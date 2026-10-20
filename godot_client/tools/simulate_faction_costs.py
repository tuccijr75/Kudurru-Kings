#!/usr/bin/env python3
"""Five-faction cost accessibility stress test using composition-legal Standard decks.
Not a combat simulation or evidence that legacy rules text is implemented.
Uses provisional owner_faction rows: canon-uncertified faction examples.
"""
from __future__ import annotations
import csv
import hashlib
import json
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MASTER = ROOT / "02_Data" / "Kudurru_Kings_Gameplay_Master_v1.csv"
OUT = ROOT / "godot_client" / "data" / "pure_faction_cost_validation_v1.json"
FACTIONS = ["BorderstoneGuild", "FloodbornPact", "SkyloomTemple", "UnderwellKeepers", "Fateforge"]
N = 4000

def afford(card: dict, budget: dict) -> bool:
    return all(int(card["cost_" + c]) <= budget[c] for c in ("sinew", "sigil", "oath"))

def play_one(hand: list, budget: dict, family: str) -> bool:
    possible = [(i, c) for i, c in enumerate(hand) if c["card_family"] == family and afford(c, budget)]
    if not possible:
        return False
    index, card = min(possible, key=lambda p: (sum(int(p[1]["cost_" + c]) for c in budget), p[1]["card_id"]))
    for resource in budget:
        budget[resource] -= int(card["cost_" + resource])
    hand.pop(index)
    return True

def run() -> dict:
    with MASTER.open(encoding="utf-8-sig", newline="") as stream:
        records = list(csv.DictReader(stream))
    groups = {}
    for row in records:
        groups.setdefault((row["owner_faction"], row["card_family"], row["rarity"]), []).append(row)
        groups.setdefault((row["owner_faction"], row["card_family"], "*"), []).append(row)
    rng = random.Random(20261020)
    results = {}
    for faction in FACTIONS:
        t1 = t1_character = t1_site = t2 = played_both = 0
        for iteration in range(N):
            deck = []
            for rarity, count in (("Common",13),("Uncommon",5),("Rare",3)):
                deck.extend(rng.sample(groups[(faction, "Character", rarity)], count))
            for family, count in (("Site",3),("Pet",2),("Relic",2),("Edict",3),
                                  ("Name",2),("Boss",2),("HostSigil",1)):
                deck.extend(rng.sample(groups[(faction, family, "*")], count))
            assert len(deck) == 36
            assert len(set(c["card_id"] for c in deck)) == 36
            assert sum(c["card_family"] == "Character" for c in deck) == 21
            rng.shuffle(deck)
            hand = deck[:6]
            reserve = deck[6:]
            budget = {"sinew":2, "sigil":1, "oath":1}
            first = any(afford(card,budget) for card in hand)
            t1 += int(first)
            if not first:
                # Exactly one free full redraw; reshuffle all 36 before refilling.
                rng.shuffle(deck)
                hand = deck[:6]
                reserve = deck[6:]
            first = any(afford(card,budget) for card in hand)
            # Simple objective-agnostic economic path: choose a Site if possible,
            # then a Character if possible. Extra plays are not presumed.
            has_site = play_one(hand, budget, "Site")
            has_character = play_one(hand, budget, "Character")
            t1_site += int(has_site)
            t1_character += int(has_character)
            # Existing rules: most ready units give Sinew, Site gives Sigil;
            # if neither condition holds, fallback 1 Sinew. No Oath objective assumed.
            if has_character: budget["sinew"] += 1
            if has_site: budget["sigil"] += 1
            if not has_character and not has_site: budget["sinew"] += 1
            # At next Draw, refill hand to six.
            hand = hand + reserve[:max(0, 6 - len(hand))]
            available = any(afford(card,budget) for card in hand)
            t2 += int(available)
            played_both += int(first and available)
        results[faction] = {
            "samples":N, "initial_hand_any_affordable":round(t1/N,5),
            "first_turn_deployed_character":round(t1_character/N,5),
            "first_turn_deployed_site":round(t1_site/N,5),
            "second_turn_any_affordable_after_income":round(t2/N,5),
            "both_turns_affordable":round(played_both/N,5),
        }
    return {
        "schema":"kudurru_pure_faction_economic_stress_v1",
        "seed":20261020,
        "model":"composition-legal faction-pure decks; no full match, no effects, no opponent",
        "factions_provisional":True,
        "cards_have_effect_certification":False,
        "results":results,
        "all_factions_pass":all(
            x["initial_hand_any_affordable"] >= .92 and
            x["second_turn_any_affordable_after_income"] >= .90
            for x in results.values()
        ),
    }

def main():
    result=run()
    if not result["all_factions_pass"]:
        raise SystemExit("Pure-faction affordability target failed; do not commit cost model")
    OUT.parent.mkdir(parents=True,exist_ok=True)
    OUT.write_text(json.dumps(result,indent=2,sort_keys=True)+"\n", encoding="utf-8")
    print(json.dumps(result,indent=2,sort_keys=True))

if __name__=="__main__":
    main()
