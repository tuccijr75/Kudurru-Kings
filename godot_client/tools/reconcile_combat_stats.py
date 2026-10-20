#!/usr/bin/env python3
"""Kudurru Kings M6: authoritative printed Guard/First Strike reconciliation.

Replaces ONLY the migrated guard (integer) and first_strike (boolean) fields
on the 664 combat cards. The complete printed First Strike *rating* is retained
in source-hashed typed provenance, not squeezed into a boolean.

--verify: compare canonical CSV against printed source facts, no modifications.
--apply: refuse arbitrary/manual edits and apply only when the full migration
preimage is correct. Original values snapshot and source checksum are retained.
"""
from __future__ import annotations
import argparse
import csv
import hashlib
import io
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MASTER = ROOT / "02_Data/Kudurru_Kings_Gameplay_Master_v1.csv"
SNAPSHOT = ROOT / "godot_client/data/m6_guard_first_strike_migration.json"
SOURCE_BASE_SHA = "c4193b54e543462cf658f8d3bf879877c150fbef4f55c3b0fd2dcb7f40cceeed"
FAMILIES = {"Character", "Boss"}
FIELDS = ("guard", "first_strike")
PATTERN = re.compile(
    r"^(?P<label>[^\n]+?) Initiative \((?P<initiative>\d+)\)\n"
    r"🛡️ Guard (?P<guard>\d+) • ⚔️ First Strike (?P<firststrike>\d+)(?:\n|$)"
)

def read():
    raw = MASTER.read_bytes()
    with io.StringIO(raw.decode("utf-8-sig"), newline="") as f:
        reader = csv.DictReader(f)
        headers = reader.fieldnames or []
        rows = list(reader)
    if len(rows) != 754 or len(headers) != 136 or len({r["card_id"] for r in rows}) != 754:
        raise ValueError("Master identity/schema drift")
    return headers, rows, raw

def expected(rows):
    originals, ratings, discrepancies = [], [], []
    for r in rows:
        ident = r["card_id"]
        if r["card_family"] not in FAMILIES:
            if r["guard"] != "0" or r["first_strike"] != "False" or r["initiative"] != "0":
                raise ValueError(f"Non-combat stat changed unexpectedly: {ident}")
            continue
        text = r["rules_text"].replace("\r\n", "\n")
        match = PATTERN.match(text)
        if not match:
            raise ValueError(f"Printed combat text missing: {ident}")
        guard = int(match["guard"])
        rating = int(match["firststrike"])
        initiative = int(match["initiative"])
        if guard < 1 or guard > 7 or rating < 1 or rating > 7:
            raise ValueError(f"Unexpected printed value range for {ident}")
        if int(r["initiative"]) != initiative:
            raise ValueError(f"Initiative mismatch for {ident}")
        if match["label"] not in ("Basic", "Standard", "Heroic", "Apocalyptic", "Celestial"):
            raise ValueError(f"Unknown Initiative tier for {ident}")
        originals.append({
            "card_id": ident,
            "printed_guard": guard,
            "printed_first_strike_rating": rating,
            "printed_initiative": initiative,
            "printed_label": match["label"],
            "rules_sha256": hashlib.sha256(text.encode("utf-8")).hexdigest(),
            "old_guard": "0", "old_first_strike": "False",
            "new_guard": str(guard), "new_first_strike": "True",
        })
        ratings.append(rating)
        if r["guard"] != str(guard) or r["first_strike"] != "True":
            discrepancies.append(ident)
    if len(originals) != 664:
        raise ValueError("Expected exactly 664 combat cards")
    if len(discrepancies) not in (0, 664):
        raise ValueError(f"Partial/manual migration detected ({len(discrepancies)})")
    return originals, discrepancies

def serialize(headers, rows, provenance):
    mapped = {r["card_id"]: r for r in provenance}
    out = io.StringIO(newline="")
    writer = csv.DictWriter(out, fieldnames=headers, lineterminator="\n")
    writer.writeheader()
    for original in rows:
        r = original.copy()
        if r["card_id"] in mapped:
            spec = mapped[r["card_id"]]
            r["guard"] = spec["new_guard"]
            r["first_strike"] = spec["new_first_strike"]
        writer.writerow(r)
    output = out.getvalue().encode("utf-8")
    with io.StringIO(output.decode("utf-8"), newline="") as f:
        parsed = list(csv.DictReader(f))
    if len(parsed) != len(rows):
        raise ValueError("Serialization dropped records")
    for old, new in zip(rows, parsed):
        for field in headers:
            if field not in FIELDS and old[field].replace("\r\n", "\n") != new[field].replace("\r\n", "\n"):
                raise ValueError(f"Unexpected modification {old['card_id']}:{field}")
    return output

def run(apply=False):
    headers, rows, raw = read()
    sha = hashlib.sha256(raw).hexdigest()
    specs, differences = expected(rows)
    if SNAPSHOT.exists():
        snap = json.loads(SNAPSHOT.read_text(encoding="utf-8"))
        if snap["source_sha256_before"] != SOURCE_BASE_SHA or snap["records"] != specs:
            raise ValueError("Migration provenance mutated")
    else:
        snap = {
            "schema": "kudurru_guard_first_strike_migration_v1",
            "source_sha256_before": SOURCE_BASE_SHA,
            "record_count": 664,
            "guard_model": "integer printed defensive rating; exact application requires card/field legality",
            "first_strike_model": "boolean presence + complete numeric First Strike rating; no universal damage bonus",
            "initiative_model": "printed value already equal to canonical structured initiative",
            "records": specs,
        }
    if len(differences) == 664:
        if sha != SOURCE_BASE_SHA:
            raise ValueError("Pristine source SHA not recognized: refuse overwrite")
        if not apply:
            raise ValueError("Master not migrated; run --apply after approval")
        SNAPSHOT.parent.mkdir(parents=True, exist_ok=True)
        SNAPSHOT.write_text(json.dumps(snap, sort_keys=True, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        MASTER.write_bytes(serialize(headers, rows, specs))
        headers, rows, raw = read()
        sha = hashlib.sha256(raw).hexdigest()
        specs, differences = expected(rows)
    elif not SNAPSHOT.exists():
        raise ValueError("Migration already applied without verified snapshot")
    if differences:
        raise ValueError("Master remains inconsistent")
    # Verify the authoritative source text and the associated typed values after serialization.
    byid = {r["card_id"]: r for r in rows}
    for spec in snap["records"]:
        row = byid[spec["card_id"]]
        if row["guard"] != spec["new_guard"] or row["first_strike"] != spec["new_first_strike"]:
            raise ValueError(f"Migrated data mismatch {spec['card_id']}")
        text = row["rules_text"].replace("\r\n", "\n")
        if hashlib.sha256(text.encode("utf-8")).hexdigest() != spec["rules_sha256"]:
            raise ValueError(f"Printed rules text changed {spec['card_id']}")
    print("M6_STAT_AUTHORITY_OK records=664 guard_numeric=664 first_strike_true=664 first_strike_ratings_preserved=664 source_sha256=" + sha)

if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--apply", action="store_true")
    args = p.parse_args()
    run(args.apply)
