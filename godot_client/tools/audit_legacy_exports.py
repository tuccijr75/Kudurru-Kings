#!/usr/bin/env python3
"""Fail-closed audit: legacy presentation exports are NOT updated by cost balancing."""
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MAIN = ROOT / "02_Data" / "Kudurru_Kings_Gameplay_Master_v1.csv"
LEGACY = (
    ROOT / "06_Exports" / "Kudurru_Kings_Master_Export_v1.csv",
    ROOT / "06_Exports" / "Kudurru_Kings_Production_Export_v1.csv",
)
OUTPUT = ROOT / "godot_client" / "data" / "legacy_export_audit_v1.json"

def read(path):
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))

def main():
    master = {r["card_id"]: r for r in read(MAIN)}
    if len(master) != 754:
        raise ValueError("Incomplete master")
    details = []
    for file in LEGACY:
        records = read(file)
        known = [r for r in records if r["card_id"] in master]
        mismatch = [r["card_id"] for r in known
                    if r["upkeep_oath"] != master[r["card_id"]]["upkeep_oath"]]
        other_mismatch = [r["card_id"] for r in known
                          if r["card_name"] != master[r["card_id"]]["card_name"]]
        if len(records) != 754 or len(known) != 754:
            raise ValueError("Legacy export contains missing/duplicate IDs")
        details.append({
            "file": str(file.relative_to(ROOT)), "row_count": len(records),
            "upkeep_disagreement_count": len(mismatch),
            "name_disagreement_count": len(other_mismatch),
            "shipping_blocked": bool(mismatch or other_mismatch),
            "interpretation": "Legacy render-only data; no authority over game master",
        })
    result = {
        "schema": "kudurru_legacy_export_gate_v1",
        "exports": details,
        "allow_shipping_legacy_exports": all(not x["shipping_blocked"] for x in details),
        "approved_cost_panel": "06_Exports/Kudurru_Kings_Cost_Panel_Export_v1.csv",
    }
    OUTPUT.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
if __name__ == "__main__":
    main()
