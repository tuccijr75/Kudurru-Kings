"""Server-side Kudurru Kings collection ledger.

Receipts must originate from an independently certified match authority.
The server key never belongs in the distributed Godot client. Transactions
guarantee idempotency and keep the original owner's collection unchanged.
"""
from __future__ import annotations
import csv
import hashlib
import hmac
import json
import sqlite3
from pathlib import Path
from contextlib import contextmanager

class LedgerError(ValueError): pass

def canonical(data: dict) -> bytes:
    return json.dumps(data,sort_keys=True,separators=(",",":"),ensure_ascii=False).encode("utf8")

class CollectionLedger:
    def __init__(self,database: str | Path,key:bytes,card_master: str | Path):
        if not isinstance(key,bytes) or len(key)<32:
            raise LedgerError("SERVER_SIGNING_KEY_REQUIRED")
        self.database=str(database)
        self.key=key
        with open(card_master,encoding="utf-8-sig",newline="") as f:
            rows=list(csv.DictReader(f))
        self.cards={r["card_id"]:r for r in rows}
        if len(rows)!=754 or len(self.cards)!=754:
            raise LedgerError("SOURCE_MASTER_INVALID")
        self.source_sha=hashlib.sha256(Path(card_master).read_bytes()).hexdigest()
        with self.connect() as db:
            db.executescript("""
            CREATE TABLE IF NOT EXISTS accounts(
              id TEXT PRIMARY KEY, level INTEGER NOT NULL DEFAULT 0,
              apex_sigils INTEGER NOT NULL DEFAULT 0);
            CREATE TABLE IF NOT EXISTS owned(
              owner TEXT NOT NULL REFERENCES accounts(id),
              card TEXT NOT NULL, quantity INTEGER NOT NULL CHECK(quantity>=0),
              PRIMARY KEY(owner,card));
            CREATE TABLE IF NOT EXISTS fragments(
              owner TEXT NOT NULL REFERENCES accounts(id),
              card TEXT NOT NULL, quantity INTEGER NOT NULL CHECK(quantity>=0),
              PRIMARY KEY(owner,card));
            CREATE TABLE IF NOT EXISTS grants(
              event_id TEXT PRIMARY KEY, hash TEXT NOT NULL,
              match_id TEXT NOT NULL, recipient TEXT NOT NULL,
              card TEXT NOT NULL, kind TEXT NOT NULL);
            """)

    @contextmanager
    def connect(self):
        conn=sqlite3.connect(self.database,timeout=20)
        conn.execute("PRAGMA foreign_keys=ON")
        conn.execute("PRAGMA busy_timeout=20000")
        try:
            yield conn
            conn.commit()
        except:
            conn.rollback()
            raise
        finally:
            conn.close()

    def sign(self,payload:dict)->str:
        """Match-server operation only. Never expose this to public clients."""
        return hmac.new(self.key,canonical(payload),hashlib.sha256).hexdigest()

    def register(self,account_id:str):
        if not isinstance(account_id,str) or not 3<=len(account_id)<=64:
            raise LedgerError("INVALID_ACCOUNT")
        with self.connect() as db:
            db.execute("INSERT OR IGNORE INTO accounts(id) VALUES(?)",(account_id,))

    def quantity(self,account_id:str,card_id:str)->int:
        with self.connect() as db:
            row=db.execute("SELECT quantity FROM owned WHERE owner=? AND card=?",
                (account_id,card_id)).fetchone()
            return row[0] if row else 0

    def capture(self,payload:dict,signature:str)->dict:
        needed={"event_id","match_id","type","recipient","defender",
                "card_id","trial_axes","success","card_master_sha256"}
        if not isinstance(payload,dict) or set(payload)!=needed:
            raise LedgerError("INVALID_RECEIPT_FIELDS")
        if any(not isinstance(payload[k],str) for k in (
            "event_id","match_id","type","recipient","defender","card_id","card_master_sha256")):
            raise LedgerError("INVALID_RECEIPT_TYPES")
        if not isinstance(payload["trial_axes"],list) or any(
            not isinstance(axis,str) for axis in payload["trial_axes"]):
            raise LedgerError("INVALID_RECEIPT_TYPES")
        if (not isinstance(signature,str) or len(signature)!=64 or
            any(char not in "0123456789abcdef" for char in signature) or
            not hmac.compare_digest(self.sign(payload),signature)):
            raise LedgerError("BAD_AUTHORITY_SIGNATURE")
        if payload["card_master_sha256"]!=self.source_sha:
            raise LedgerError("SOURCE_VERSION_MISMATCH")
        if payload["type"]!="CAPTURE_CONFIRMED" or payload["success"] is not True:
            raise LedgerError("CAPTURE_NOT_CONFIRMED")
        if payload["recipient"]==payload["defender"]:
            raise LedgerError("SELF_CAPTURE")
        if not all(isinstance(payload[k],str) and len(payload[k])>=12 for k in ("event_id","match_id")):
            raise LedgerError("INVALID_EVENT_ID")
        card=self.cards.get(str(payload["card_id"]))
        if card is None or card["card_family"] not in ("Character","Boss"):
            raise LedgerError("INVALID_CAPTURE_CARD")
        if card["card_family"]=="Boss" and (
            not isinstance(payload["trial_axes"],list) or
            sorted(set(payload["trial_axes"]))!=["Authority","Stone","Veil"]):
            raise LedgerError("BOSS_THREE_DISTINCT_TRIALS_REQUIRED")
        if card["card_family"]=="Character" and payload["trial_axes"]!=[]:
            raise LedgerError("CHARACTER_TRIALS_NOT_ALLOWED")
        digest=hashlib.sha256(canonical(payload)).hexdigest()
        with self.connect() as db:
            try:
                db.execute("BEGIN IMMEDIATE")
                for account in (payload["recipient"],payload["defender"]):
                    if not db.execute("SELECT 1 FROM accounts WHERE id=?",(account,)).fetchone():
                        raise LedgerError("ACCOUNT_UNKNOWN")
                prior=db.execute("SELECT hash FROM grants WHERE event_id=?",
                    (payload["event_id"],)).fetchone()
                if prior:
                    if prior[0]!=digest:raise LedgerError("EVENT_REPLAY_CONFLICT")
                    return {"ok":True,"granted":False,"idempotent":True}
                db.execute("""INSERT INTO owned(owner,card,quantity) VALUES(?,?,1)
                   ON CONFLICT(owner,card) DO UPDATE SET quantity=quantity+1""",
                   (payload["recipient"],payload["card_id"]))
                db.execute("INSERT INTO grants VALUES(?,?,?,?,?,?)",(
                    payload["event_id"],digest,payload["match_id"],payload["recipient"],
                    payload["card_id"],"capture"))
                return {"ok":True,"granted":True,"idempotent":True}
            except:
                db.rollback()
                raise

    def ultra_eligibility(self,account_id:str,card_id:str,policy:dict|None)->dict:
        source=self.cards.get(card_id)
        if source is None or source["rarity"]!="Ultra":
            raise LedgerError("NOT_SOURCE_ULTRA")
        if policy is None:
            return {"eligible":False,"reason":"UNAPPROVED_ULTRA_THRESHOLDS"}
        if set(policy)!={"minimum_level","apex_sigils","card_fragments"} or any(
            type(value) is not int or value<=0 for value in policy.values()):
            raise LedgerError("POLICY_MUST_SPECIFY_THREE_POSITIVE_GATES")
        with self.connect() as db:
            account=db.execute("SELECT level,apex_sigils FROM accounts WHERE id=?",
                (account_id,)).fetchone()
            if account is None:raise LedgerError("ACCOUNT_UNKNOWN")
            row=db.execute("SELECT quantity FROM fragments WHERE owner=? AND card=?",
                (account_id,card_id)).fetchone()
            fragments=row[0] if row else 0
            return {"eligible":account[0]>=policy["minimum_level"] and
                account[1]>=policy["apex_sigils"] and
                fragments>=policy["card_fragments"],
                "reason":"THREE_PREREQUISITES_REQUIRED"}
