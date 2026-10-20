#!/usr/bin/env python3
"""Derive 754-ID cost label source, preserving obsolete render exports unchanged."""
from __future__ import annotations
import argparse
import csv
import io
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MASTER = ROOT / "02_Data" / "Kudurru_Kings_Gameplay_Master_v1.csv"
REPORT = ROOT / "godot_client" / "data" / "cost_balance_v1_report.json"
OUT = ROOT / "06_Exports" / "Kudurru_Kings_Cost_Panel_Export_v1.csv"
COLUMNS = ("card_id", "card_name", "card_family", "cost_sinew", "cost_sigil",
           "cost_oath", "upkeep_oath", "balance_basis", "gameplay_certified")

def expected() -> bytes:
    with MASTER.open(encoding="utf-8-sig", newline="") as f:
        cards = list(csv.DictReader(f))
    audit = json.loads(REPORT.read_text(encoding="utf-8"))
    profiles = {x["card_id"]: x for x in audit["profile_by_card"]}
    if len(cards) != 754 or len(profiles) != 754:
        raise ValueError("Cannot export incomplete 754-card master/report")
    buf = io.StringIO(newline="")
    writer = csv.DictWriter(buf, fieldnames=COLUMNS, lineterminator="\n")
    writer.writeheader()
    ids = set()
    for card in cards:
        ident = card["card_id"]
        if ident in ids or ident not in profiles:
            raise ValueError("Duplicate/missing card ID")
        ids.add(ident)
        profile = profiles[ident]
        for field in ("cost_sinew", "cost_sigil", "cost_oath", "upkeep_oath"):
            if str(profile["new"][field]) != str(card[field]):
                raise ValueError(f"Master/report cost diverged on {ident}:{field}")
        writer.writerow({
            "card_id": ident, "card_name": card["card_name"], "card_family": card["card_family"],
            "cost_sinew": card["cost_sinew"], "cost_sigil": card["cost_sigil"],
            "cost_oath": card["cost_oath"], "upkeep_oath": card["upkeep_oath"],
            "balance_basis": profile["basis"], "gameplay_certified": "false",
        })
    return buf.getvalue().encode("utf-8")

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--write", action="store_true")
    args = p.parse_args()
    data = expected()
    if args.write:
        OUT.parent.mkdir(parents=True, exist_ok=True)
        OUT.write_bytes(data)
    elif not OUT.is_file() or OUT.read_bytes() != data:
        raise SystemExit("Cost panel missing or stale; run with --write")
    print(f"COST_PANEL_OK records=754 bytes={len(data)} source={MASTER.relative_to(ROOT)} mode={'WRITE' if args.write else 'VERIFY'}")

if __name__ == "__main__":
    main()
