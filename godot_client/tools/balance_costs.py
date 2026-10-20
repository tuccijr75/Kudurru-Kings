#!/usr/bin/env python3
"""Kudurru Kings deployment-cost and upkeep baseline v1.

Reads 754 canonical master records; computes each resource cost from printed stats,
family and stated text. --preview is strictly read-only; --apply changes only four
cost/upkeep columns on the isolated development branch. Existing nonzero/manual
costs are never silently overwritten. Source changes remain reversible through Git.

Costs are a testable proposed gameplay baseline, NOT certification of card effects.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import random
import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MASTER = ROOT / "02_Data" / "Kudurru_Kings_Gameplay_Master_v1.csv"
REPORT = ROOT / "godot_client" / "data" / "cost_balance_v1_report.json"
COST_FIELDS = ("cost_sinew", "cost_sigil", "cost_oath", "upkeep_oath")
FAMILIES = {"Character", "Boss", "Edict", "HostSigil", "Name", "Pet", "Relic", "Site"}
RARITIES = {"Common", "Uncommon", "Rare", "SuperRare", "Legendary", "Ultra"}
SCHEMA = "kudurru_cost_balance_v1"

def number(row: dict, field: str) -> int:
    value = str(row[field]).strip()
    if not value or not value.isdigit():
        raise ValueError(f"Invalid {field} on card_id {row['card_id']}: {value!r}")
    return int(value)

def derive(row: dict) -> dict[str, int | str]:
    family = row["card_family"]
    rarity = row["rarity"]
    name = row["card_name"]
    if family not in FAMILIES or rarity not in RARITIES:
        raise ValueError(f"Unknown family/rarity on {row['card_id']}")
    st, ve, au = (number(row, x) for x in ("stone", "veil", "authority"))
    total = st + ve + au
    rules = row["rules_text"]
    s = g = o = upkeep = 0
    basis = "FAMILY_AND_PRINTED_POWER"
    if family == "Character":
        s = 1 + (total >= 5) + (total >= 11) + (total >= 18)
        g = int(ve >= 5 and ve >= st and total >= 10)
        o = int(au >= 7 and au >= max(st, ve) and total >= 13)
        # Only Ultra characters are Adamu, according to Shipping Rules.
        if rarity == "Ultra":
            if name != "Adamu": raise ValueError(f"Unexpected Ultra Character: {name}")
            s, g, o = 4, 2, 2
            basis = "ULTRA_APEX"
        # Baseline Characters have no generic recurring Oath tax. Printed abilities
        # with 'supply' or other legacy terms are NOT silently interpreted as Oath.
        upkeep = 0
    elif family == "Boss":
        s = 3 + (total >= 17) + (total >= 26)
        g = int(ve >= 9)
        o = 1 + int(total >= 24)
        upkeep = 1  # Sustains exactly under +1 Oath objective income.
        if rarity == "Ultra":
            if name != "Anu": raise ValueError(f"Unexpected Ultra Boss: {name}")
            s, g, o, upkeep = 5, 2, 2, 1
            basis = "ULTRA_APEX_BOSS"
    elif family == "Pet":
        s = int(st >= ve and st >= 1 or rarity == "Legendary")
        g = int(ve > st)
        if s + g == 0: s = 1
        # Attached support is affordable; no default recurring upkeep.
        upkeep = 0
    elif family == "Site":
        g = 1 + int(rarity == "Legendary")
        s = int(rarity in {"Rare", "SuperRare", "Legendary"}
                and bool(re.search(r"\b(copy|cancel|steal|raid)\b", rules, re.I)))
    elif family == "Edict":
        g = 1 + int(rarity in {"SuperRare", "Legendary"})
        o = int(rarity == "Legendary" or
                (rarity == "SuperRare" and bool(re.search(r"\ball units\b|\beach opponent\b", rules, re.I))))
    elif family == "Name":
        g = 1 + int(rarity in {"Rare", "SuperRare", "Legendary"})
        o = int(rarity == "Legendary")
        # Persistent laws already add Audit Heat; only apex tier carries maintenance.
        upkeep = int(rarity == "Legendary")
    elif family == "Relic":
        g = 1 + int(rarity in {"SuperRare", "Legendary"})
        s = int(rarity in {"Rare", "SuperRare", "Legendary"}
                and bool(re.search(r"\b(Stone Test|Temper|damage|support)\b", rules, re.I)))
    elif family == "HostSigil":
        g = 1 + int(rarity in {"SuperRare", "Legendary"})
        o = int(rarity in {"SuperRare", "Legendary"})
        # Printed timed invocations do not also pay undocumented upkeep.
        upkeep = 0
        # A literal printed invocation cost overrides generic deployment price.
        # Future resolver must NOT charge this twice.
        explicit = re.search(r"\bInvoke\s+Oath\s+(\d+)\s*\+\s*Sigil\s+(\d+)\b", rules, re.I)
        if explicit:
            o, g = int(explicit.group(1)), int(explicit.group(2))
            basis = "PRINTED_INVOKE_COST_NO_DOUBLE_CHARGE"
    if not (0 <= s <= 5 and 0 <= g <= 2 and 0 <= o <= 2 and 0 <= upkeep <= 1):
        raise ValueError(f"Cost outside viable resource bounds: {row['card_id']}, {(s,g,o,upkeep)}")
    if s + g + o == 0:
        raise ValueError(f"Free deployment without explicit authorization: {row['card_id']}")
    return {"cost_sinew": s, "cost_sigil": g, "cost_oath": o,
            "upkeep_oath": upkeep, "basis": basis}

def load() -> tuple[list[str], list[dict], bytes]:
    raw = MASTER.read_bytes()
    with io.StringIO(raw.decode("utf-8-sig"), newline="") as f:
        reader = csv.DictReader(f)
        headers = reader.fieldnames or []
        required = set(COST_FIELDS) | {"card_id", "card_name", "card_family",
                   "rarity", "rules_text", "stone", "veil", "authority"}
        if len(headers) != 136 or required - set(headers):
            raise ValueError(f"Unexpected master schema: columns={len(headers)}, missing={required - set(headers)}")
        rows = list(reader)
    if len(rows) != 754 or len({r["card_id"] for r in rows}) != 754:
        raise ValueError("Master does not contain 754 unique card IDs")
    return headers, rows, raw

def simulation(rows: list[dict], costs: dict[str, dict], samples: int = 12000) -> dict:
    # Deterministic *affordability stress-test*, not a simulated match or legal deck.
    # Deck composition approximates early Standard proportions; no faction/card effects
    # are simulated, and cannot substantiate card-balance certification.
    rng = random.Random(20010614)
    by = {}
    for row in rows:
        by.setdefault((row["card_family"], row["rarity"]), []).append(row)
    groups = {}
    for row in rows:
        groups.setdefault(row["card_family"], []).append(row)
    first = mulligan = char_first = playable_counts = 0
    for _ in range(samples):
        deck = []
        for grade, count in (("Common", 10), ("Uncommon", 5), ("Rare", 3)):
            deck.extend(rng.sample(by[("Character", grade)], count))
        for fam, count in (("Site", 5), ("Pet", 3), ("Relic", 1),
                           ("Edict", 4), ("Name", 2), ("Boss", 2), ("HostSigil", 1)):
            deck.extend(rng.sample(groups[fam], count))
        assert len(deck) == 36
        rng.shuffle(deck)
        def afford(card):
            cost = costs[card["card_id"]]
            return cost["cost_sinew"] <= 2 and cost["cost_sigil"] <= 1 and cost["cost_oath"] <= 1
        hand1 = deck[:6]
        open_count = sum(afford(c) for c in hand1)
        playable_counts += open_count
        first += bool(open_count)
        char_first += any(afford(c) and c["card_family"] == "Character" for c in hand1)
        # Free full mulligan only if opening hand has no deployable card.
        if open_count:
            mulligan += 1
        else:
            rng.shuffle(deck)
            mulligan += any(afford(c) for c in deck[:6])
    return {
        "samples": samples, "seed": 20010614,
        "sampling_model": "illustrative mixed-faction economics-only 36-card pool, not legal deck validation",
        "first_hand_any_affordable": round(first / samples, 5),
        "after_optional_mulligan_any_affordable": round(mulligan / samples, 5),
        "opening_hand_affordable_character": round(char_first / samples, 5),
        "average_affordable_cards_first_hand": round(playable_counts / samples, 3),
    }

def produce() -> tuple[dict, list[str], list[dict], dict[str, dict]]:
    headers, rows, raw = load()
    costs = {r["card_id"]: derive(r) for r in rows}
    old_nonzero = sum(any(str(r[f]).strip() not in ("0", "") for f in COST_FIELDS[:3]) for r in rows)
    exact = sum(all(str(r[f]).strip() == str(costs[r["card_id"]][f]) for f in COST_FIELDS) for r in rows)
    # Either pristine migration (all 3 deployment fields zero), or an idempotent
    # re-run with exact v1 values; manual edits are never overwritten.
    if old_nonzero and exact != 754:
        raise ValueError(f"Detected {old_nonzero} nonzero-cost rows with only {exact} exact v1 profiles. Refusing to overwrite manual values.")
    cost_hist = Counter()
    family_cost = {}
    for row in rows:
        c = costs[row["card_id"]]
        cost_hist[(c["cost_sinew"], c["cost_sigil"], c["cost_oath"])] += 1
        family_cost.setdefault(row["card_family"], Counter())[sum(c[f] for f in COST_FIELDS[:3])] += 1
    report = {
        "schema": SCHEMA,
        "source_sha256_before_apply": hashlib.sha256(raw).hexdigest(),
        "records": len(rows),
        "source_zero_deployment_count": sum(
            all(str(row[f]).strip() in ("", "0") for f in COST_FIELDS[:3]) for row in rows),
        "original_high_upkeep_count": sum(int(row["upkeep_oath"] or "0") > 1 for row in rows),
        "changed_deployment_count": sum(
            any(str(row[f]).strip() != str(costs[row["card_id"]][f]) for f in COST_FIELDS[:3])
            for row in rows),
        "changed_upkeep_count": sum(
            str(row["upkeep_oath"]).strip() != str(costs[row["card_id"]]["upkeep_oath"]) for row in rows),
        "zero_new_deployments": sum(sum(costs[row["card_id"]][f] for f in COST_FIELDS[:3]) == 0 for row in rows),
        "new_upkeep_over_one": sum(costs[row["card_id"]]["upkeep_oath"] > 1 for row in rows),
        "cost_combinations": [
            {"sinew": s, "sigil": g, "oath": o, "count": n}
            for (s, g, o), n in sorted(cost_hist.items())],
        "total_cost_by_family": {f: dict(sorted(counter.items())) for f, counter in family_cost.items()},
        "affordability_stress_test": simulation(rows, costs),
        "profile_by_card": [
            {"card_id": row["card_id"], "name": row["card_name"], "family": row["card_family"],
             "rarity": row["rarity"], "old": {f: int(row[f] or "0") for f in COST_FIELDS},
             "new": {f: costs[row["card_id"]][f] for f in COST_FIELDS}, "basis": costs[row["card_id"]]["basis"]}
            for row in rows],
        "fully_gameplay_certified": False,
        "reason_not_certified": "Card effects, legacy rule terms, timing and match simulations await authoritative resolver tests.",
    }
    return report, headers, rows, costs

def apply(headers: list[str], rows: list[dict], costs: dict[str, dict]) -> None:
    output = io.StringIO(newline="")
    writer = csv.DictWriter(output, fieldnames=headers, lineterminator="\n",
                            quoting=csv.QUOTE_MINIMAL)
    writer.writeheader()
    for row in rows:
        changed = row.copy()
        for f in COST_FIELDS: changed[f] = str(costs[row["card_id"]][f])
        writer.writerow(changed)
    candidate = output.getvalue().encode("utf-8")
    with io.StringIO(candidate.decode(), newline="") as fh:
        back = list(csv.DictReader(fh))
    if len(back) != len(rows):
        raise ValueError("Serialization lost records")
    for source, changed in zip(rows, back):
        for field in headers:
            if field not in COST_FIELDS and source[field] != changed[field]:
                raise ValueError(f"Unapproved data rewrite at {source['card_id']}: {field}")
    MASTER.write_bytes(candidate)

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true", help="Write 4 columns to canonical master")
    args = parser.parse_args()
    report, headers, rows, costs = produce()
    sim = report["affordability_stress_test"]
    if sim["after_optional_mulligan_any_affordable"] < 0.97:
        raise ValueError("Opening accessibility regression: mulligan affordability below 97%")
    if sim["first_hand_any_affordable"] < 0.88:
        raise ValueError("Opening accessibility regression: first hand affordability below 88%")
    if report["zero_new_deployments"] or report["new_upkeep_over_one"]:
        raise ValueError("Cost/boss sustainability invariant violated")
    if args.apply:
        apply(headers, rows, costs)
        report["applied_master_sha256"] = hashlib.sha256(MASTER.read_bytes()).hexdigest()
    report["mode"] = "APPLY" if args.apply else "PREVIEW"
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text(json.dumps(report, sort_keys=True, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({k: report[k] for k in ("mode","records","source_zero_deployment_count",
        "original_high_upkeep_count","changed_deployment_count","changed_upkeep_count",
        "zero_new_deployments","new_upkeep_over_one","affordability_stress_test")},
        indent=2, sort_keys=True))
    print(f"Report: {REPORT}")

if __name__ == "__main__":
    main()
