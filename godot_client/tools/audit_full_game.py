#!/usr/bin/env python3
"""Production completion inventory, generated exclusively from Kudurru master
and current certified/runtime capability contracts. No speculative play claims.
Run after build_catalog/build_real_cards and source audits.
"""
from __future__ import annotations
import csv
import hashlib
import json
import re
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "02_Data/Kudurru_Kings_Gameplay_Master_v1.csv"
CATALOG = ROOT / "godot_client/data/real_cards_v1.json"
ADJACENCY = ROOT / "godot_client/data/adjacency_descriptors_v1.json"
OUT = ROOT / "godot_client/data/full_game_completion_audit.json"
GROUP_REPORT = ROOT / "godot_client/data/effect_template_groups.json"
M4 = set(["180","184","185","187","189","191","193","199","206","207","214","216"])
M8_LIVE_EDICTS = {"181","188","191","193"}
M7 = set(["214","216","239","241","254"])
DOMAINS = {
"canon_factions": ("BLOCKED", "Resolve every migrated faction assignment through EOE Crosswalk, including known conflicts."),
"source_card_registry": ("PASS", "All 754 genuine card IDs and original printed rules are source hashed."),
"combat_stat_authority": ("PASS", "664 printed Guard / First Strike numbers reconciled to structured fields and reversible provenance."),
"deployment_costs": ("PASS", "All 754 deployment costs positive with deterministic derivation and audit."),
"card_effects": ("BLOCKED", "M4 provides 12 selected source-pinned sandbox effects; repeated 423 Character conditions are extracted but are not full match certification."),
"reusable_effect_runtime": ("IN_PROGRESS", "Finish template-level triggers, target legality, stacking, replacement and expiry."),
"local_faction_selection": ("PASS", "M8 validates all 25 five-faction two-seat pairings against the 36-card deck contract."),
"local_save_and_replay": ("PASS", "M8 versioned source-pinned local save/restore independently replays every action and rejects modified data."),
"turn_setup_decks": ("IN_PROGRESS", "M7 candidate uses two player-specific legal 36-card decks and pre-match choices; full deck builder and all player counts pending."),
"full_combat": ("BLOCKED", "Guard protection, First Strike action windows, Bosses, full supporter effects, consequence legality and status interactions."),
"scenarios": ("IN_PROGRESS", "M7 has a clearly labeled candidate Warfield objective; production scenarios still require approval and certification."),
"field_line_geasa": ("BLOCKED", "Two active Fields exist in M7 preview, but Line traversal, Geasa and jurisdiction effects are not complete."),
"boss_trials_capture": ("BLOCKED", "Three distinct-axis Trials, true Bind sources and deterministic capture success/failure with copy rewards unresolved."),
"arbitration": ("IN_PROGRESS", "Sealed bids + Seize implemented in isolated lab; Suppress, Corrupt and Injunctions blocked."),
"heat": ("IN_PROGRESS", "Heat ladder and selected source effects present; complete Heat-spend/revival/hazard rules pending."),
"site_raids": ("BLOCKED", "Authoritative raid legality, capture and 2-Mark scoring not integrated."),
"solo_ai": ("IN_PROGRESS", "M7 deterministic local test opponent exists; advanced tactical AI and full card legality remain unverified."),
"multiplayer": ("BLOCKED", "Server authority, privacy, reconnect, simultaneous windows and 2–4 seat network mode not built."),
"collection_rewards": ("BLOCKED", "Persistent accounts, owned-copy idempotency, progression, Ultra gates and safe transactions not built."),
"visual_assets": ("BLOCKED", "Layered visual/card render exports and full UI layout/device certification not completed."),
"security_privacy": ("BLOCKED", "Server anti-cheat, account auth, hidden-state projection and audit/replay still pending."),
"distribution": ("BLOCKED", "Windows packaged release, installer, accessibility, save recovery and launch QA not certified."),
}
LEGACY = {
 "deprecated_wind": re.compile(r"\bWind\b",re.I),
 "deprecated_eye": re.compile(r"\bEye\b",re.I),
 "legacy_supply": re.compile(r"\bsupply\b",re.I),
 "legacy_recoil": re.compile(r"\brecoil\b",re.I),
 "legacy_accuracy": re.compile(r"\baccuracy\b",re.I),
 "legacy_temper": re.compile(r"\bTemper\b",re.I),
}

def effect_template(row):
    text = row["rules_text"].replace("\r\n","\n")
    lines = text.split("\n")
    if row["card_family"] in ("Character","Boss") and len(lines)>=3 and " Initiative (" in lines[0] and "Guard " in lines[1]:
        text = "\n".join(lines[2:])
    return re.sub(r"\b\d+(?:\.\d+)?\b","<N>",text)

def build():
    with SOURCE.open(encoding="utf-8-sig",newline="") as f:
        rows=list(csv.DictReader(f))
    c=json.loads(CATALOG.read_text(encoding="utf-8"))
    adj=json.loads(ADJACENCY.read_text(encoding="utf-8"))
    if len(rows)!=754 or c["record_count"]!=754 or c["production_playable_count"]!=0:
        raise ValueError("Original card ledger or certification changed; re-audit")
    if c["source_sha256"] != hashlib.sha256(SOURCE.read_bytes()).hexdigest():
        raise ValueError("Generated real catalog is stale")
    allids={r["card_id"] for r in rows}
    if len(allids)!=754:
        raise ValueError("Nonunique card identities")
    matched={x["card_id"] for x in adj["source_card_effects"]}
    if len(matched)!=423: raise ValueError("Expected 423 exact source-backed adjacent ally patterns")
    groups=defaultdict(list)
    tags=Counter()
    records=[]
    for row in rows:
        id_=row["card_id"]
        family=row["card_family"]
        exact=effect_template(row)
        key=family+"|"+exact
        groups[key].append(id_)
        issues=[]
        for name,pat in LEGACY.items():
            if pat.search(row["rules_text"]):
                tags[name]+=1
                issues.append(name)
        if id_ in M8_LIVE_EDICTS:
            status="M8_LIVE_EDICT_CANDIDATE"
        elif id_ in matched:
            status="M7_CHARACTER_BASIC_SANDBOX"
        elif id_ in M4:
            status="M4_SOURCE_EFFECT_SANDBOX"
        elif id_ in M7:
            status="M7_PRESENT_EFFECT_NOT_FULLY_CERTIFIED"
        else:
            status="UNIMPLEMENTED_OR_UNVERIFIED"
        records.append({
            "card_id":id_,"card_name":row["card_name"],
            "family":family,"template_key_sha256":hashlib.sha256(key.encode()).hexdigest(),
            "effect_status":status,"production_certified":False,
            "migration_terms":issues,
        })
    stats=Counter(r["effect_status"] for r in records)
    byfam=Counter(r["family"] for r in records)
    grouped=[{
        "family":key.split("|",1)[0],"normalized_pattern":key.split("|",1)[1],
        "source_card_count":len(ids),"card_ids":ids,
        "template_sha256":hashlib.sha256(key.encode()).hexdigest()
    } for key,ids in groups.items()]
    grouped.sort(key=lambda x:(-x["source_card_count"],x["family"],x["template_sha256"]))
    if sum(stats.values())!=754 or sum(byfam.values())!=754:
        raise ValueError("Incomplete source coverage")
    domains={name:{"status":status,"remaining":remaining} for name,(status,remaining) in DOMAINS.items()}
    result={
        "schema":"kudurru_full_game_completion_audit_v1",
        "master_sha256":hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
        "source_card_count":754,
        "source_coverage_count":len(records),
        "unique_effect_templates":len(grouped),
        "by_family":dict(byfam),
        "effect_statuses":dict(stats),
        "source_migration_term_counts":dict(tags),
        "full_standard_releasable":False,
        "multiplayer_releasable":False,
        "candidate_local_match_available":True,
        "candidate_faction_pairings":25,
        "candidate_verified_save_replay":True,
        "source_verified_live_edicts":sorted(M8_LIVE_EDICTS),
        "candidate_scenario":"Warfield Ascendancy (uncertified variant)",
        "production_game_gates":domains,
        "blocked_gate_count":sum(x["status"]=="BLOCKED" for x in domains.values()),
        "in_progress_gate_count":sum(x["status"]=="IN_PROGRESS" for x in domains.values()),
        "passed_gate_count":sum(x["status"]=="PASS" for x in domains.values()),
        "card_manifest":records,
    }
    return result,grouped

if __name__=="__main__":
    result,groups=build()
    OUT.write_text(json.dumps(result,ensure_ascii=False,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    GROUP_REPORT.write_text(json.dumps({"schema":"kudurru_effect_grouping_v1","template_count":len(groups),"templates":groups},
        ensure_ascii=False,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("COMPLETE_GAME_AUDIT cards=%d effect_templates=%d passed=%d in_progress=%d blocked=%d"
        % (result["source_card_count"],result["unique_effect_templates"],
        result["passed_gate_count"],result["in_progress_gate_count"],result["blocked_gate_count"]))
