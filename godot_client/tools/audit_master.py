#!/usr/bin/env python3
"""Read-only structural audit of the repository's canonical 754-card master.
Never infers card costs or silently changes EOE/KK faction assignments.
Exit 2 on missing data or wrong schema; emit JSON for reproducible gates.
"""
import csv
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MASTER = ROOT / "02_Data" / "Kudurru_Kings_Gameplay_Master_v1.csv"
FIELDS = ("card_id", "card_name", "card_family", "owner_faction", "cost_sinew", "cost_sigil", "cost_oath")
CROSSWALK_EXPECTED = {
    "Drowned Archivist": "UnderwellKeepers",
    "Ash Prophetess": "Fateforge",
    "Chain Marshal": "BorderstoneGuild",
    "Taxlord Balash": "BorderstoneGuild",
    "Silver Mask Judge": "SkyloomTemple",
    "Adamu": "BorderstoneGuild",
}
def run():
    if not MASTER.is_file():
        print(json.dumps({"status": "BLOCKED_MISSING_MASTER", "path": str(MASTER)}))
        return 2
    with MASTER.open(encoding="utf-8-sig", newline="") as fh:
        reader = csv.DictReader(fh)
        missing = sorted(set(FIELDS) - set(reader.fieldnames or ()))
        if missing:
            print(json.dumps({"status": "INVALID_SCHEMA", "missing": missing}))
            return 2
        rows = list(reader)
    matches = {}
    for name, target in CROSSWALK_EXPECTED.items():
        found = [r for r in rows if r["card_name"].casefold() == name.casefold()]
        matches[name] = {
            "crosswalk_faction": target,
            "source_records": [
                {"id": r["card_id"], "family": r["card_family"], "source_faction": r["owner_faction"], "matches_crosswalk": r["owner_faction"] == target}
                for r in found
            ],
            "status": "MISSING_REVIEW" if not found else ("MATCH" if all(r["owner_faction"] == target for r in found) else "CONFLICT_UNDER_REVIEW"),
        }
    all_zero = sum(
        all(r[k].strip() in ("", "0", "0.0") for k in ("cost_sinew", "cost_sigil", "cost_oath")) for r in rows
    )
    result = {
        "status": "MASTER_IMPORT_UNCERTIFIED",
        "count": len(rows),
        "fields": len(reader.fieldnames or []),
        "zero_triple_cost_count": all_zero,
        "families": dict(Counter(r["card_family"] for r in rows)),
        "crosswalk_reconciliation": matches,
        "gameplay_released": False,
    }
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0 if len(rows) == 754 and len(reader.fieldnames or []) == 136 else 2

if __name__ == "__main__":
    raise SystemExit(run())
