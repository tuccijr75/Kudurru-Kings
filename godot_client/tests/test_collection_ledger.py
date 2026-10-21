import importlib.util
import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
import sys
sys.path.insert(0,str(ROOT/"godot_client/server"))
from collection_ledger import CollectionLedger,LedgerError

class LedgerTests(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory()
  self.db=Path(self.tmp.name)/"collections.sqlite"
  self.ledger=CollectionLedger(self.db,b"server-only-fixture-secret-at-least-32-bytes",ROOT/"02_Data/Kudurru_Kings_Gameplay_Master_v1.csv")
  for account in ("capturer","defender"):
   self.ledger.register(account)

 def tearDown(self):self.tmp.cleanup()

 def receipt(self,card_id,axes=None):
  return {"event_id":"capture-proof-"+card_id+"-event-00001","match_id":"match-proof-0000000001",
   "type":"CAPTURE_CONFIRMED","recipient":"capturer","defender":"defender",
   "card_id":card_id,"trial_axes":axes or [],"success":True,
   "card_master_sha256":self.ledger.source_sha}

 def test_real_character_owner_preserved_idempotency(self):
  payload=self.receipt("421")
  sig=self.ledger.sign(payload)
  self.assertTrue(self.ledger.capture(payload,sig)["granted"])
  self.assertEqual(1,self.ledger.quantity("capturer","421"))
  self.assertFalse(self.ledger.capture(payload,sig)["granted"])
  self.assertEqual(1,self.ledger.quantity("capturer","421"))
  self.assertEqual(0,self.ledger.quantity("defender","421"))

 def test_wrong_signature_and_replay_payload(self):
  payload=self.receipt("421")
  with self.assertRaisesRegex(LedgerError,"BAD_AUTHORITY_SIGNATURE"):
   self.ledger.capture(payload,"malicious-client")
  self.ledger.capture(payload,self.ledger.sign(payload))
  forged=payload|{"recipient":"defender"}
  with self.assertRaises(LedgerError):
   self.ledger.capture(forged,self.ledger.sign(forged))
  self.assertEqual(1,self.ledger.quantity("capturer","421"))

 def test_boss_trials_three_unique(self):
  payload=self.receipt("16",["Stone","Veil","Authority"])
  self.assertTrue(self.ledger.capture(payload,self.ledger.sign(payload))["granted"])
  self.assertEqual(1,self.ledger.quantity("capturer","16"))
  another=self.receipt("16",["Stone","Stone","Veil"])|{"event_id":"capture-proof-boss-2"}
  with self.assertRaisesRegex(LedgerError,"BOSS_THREE_DISTINCT_TRIALS_REQUIRED"):
   self.ledger.capture(another,self.ledger.sign(another))
  self.assertEqual(1,self.ledger.quantity("capturer","16"))

 def test_capture_missing_authority_and_bad_card(self):
  p=self.receipt("421")|{"success":False}
  with self.assertRaisesRegex(LedgerError,"CAPTURE_NOT_CONFIRMED"):
   self.ledger.capture(p,self.ledger.sign(p))
  p=self.receipt("99999")
  with self.assertRaisesRegex(LedgerError,"INVALID_CAPTURE_CARD"):
   self.ledger.capture(p,self.ledger.sign(p))
  p=self.receipt("421")|{"card_master_sha256":"old-version"}
  with self.assertRaisesRegex(LedgerError,"SOURCE_VERSION_MISMATCH"):
   self.ledger.capture(p,self.ledger.sign(p))

 def test_concurrent_replay_safe_sqlite(self):
  payload=self.receipt("421"); sig=self.ledger.sign(payload)
  from concurrent.futures import ThreadPoolExecutor
  with ThreadPoolExecutor(max_workers=8) as ex:
   results=list(ex.map(lambda _:self.ledger.capture(payload,sig),range(24)))
  self.assertEqual(1,sum(int(x["granted"]) for x in results))
  self.assertEqual(1,self.ledger.quantity("capturer","421"))

 def test_ultra_requires_all_three_without_invented_thresholds(self):
  u=self.ledger.ultra_eligibility("capturer","255",None)
  self.assertFalse(u["eligible"])
  self.assertEqual("UNAPPROVED_ULTRA_THRESHOLDS",u["reason"])
  policy={"minimum_level":25,"apex_sigils":3,"card_fragments":10}
  self.assertFalse(self.ledger.ultra_eligibility("capturer","255",policy)["eligible"])
  with self.ledger.connect() as db:
   db.execute("UPDATE accounts SET level=25,apex_sigils=3 WHERE id='capturer'")
   db.execute("INSERT INTO fragments VALUES ('capturer','255',10)")
  self.assertTrue(self.ledger.ultra_eligibility("capturer","255",policy)["eligible"])
  self.assertFalse(self.ledger.ultra_eligibility("capturer","36",policy)["eligible"])
  with self.assertRaises(LedgerError):
   self.ledger.ultra_eligibility("capturer","255",{"minimum_level":25})

 def test_malformed_receipts_fail_closed_without_database_changes(self):
  for payload in (None,[],True,"receipt"):
   with self.subTest(payload=payload),self.assertRaisesRegex(LedgerError,"INVALID_RECEIPT_FIELDS"):
    self.ledger.capture(payload,"invalid")
  for field,value in (("recipient",[]),("defender",{}),("card_id",421),
                      ("trial_axes",[{}]),("trial_axes",[1]),("trial_axes",None)):
   payload=self.receipt("421")|{field:value}
   with self.subTest(field=field,value=value),self.assertRaisesRegex(LedgerError,"INVALID_RECEIPT_TYPES"):
    self.ledger.capture(payload,self.ledger.sign(payload))
  payload=self.receipt("421")
  for signature in ("é"*64,"g"*64,"a"*63,None,[]):
   with self.subTest(signature=signature),self.assertRaisesRegex(LedgerError,"BAD_AUTHORITY_SIGNATURE"):
    self.ledger.capture(payload,signature)
  self.assertEqual(0,self.ledger.quantity("capturer","421"))
  with self.ledger.connect() as db:
   self.assertEqual(0,db.execute("SELECT count(*) FROM grants").fetchone()[0])

 def test_schema_and_key_gate(self):
  with self.assertRaisesRegex(LedgerError,"SERVER_SIGNING_KEY_REQUIRED"):
   CollectionLedger(self.db,b"tiny",ROOT/"02_Data/Kudurru_Kings_Gameplay_Master_v1.csv")
  with self.assertRaisesRegex(LedgerError,"INVALID_RECEIPT_FIELDS"):
   self.ledger.capture({"card_id":"421"},self.ledger.sign({"card_id":"421"}))

if __name__=="__main__":unittest.main(verbosity=2)
