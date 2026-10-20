#!/usr/bin/env python3
"""M5 release-readiness audit: explicit machine-readable unresolved canon gates.

This is not a test claiming shipping readiness. It rejects falsely positive claims
and keeps all 754 real-card effects unapproved for public matches.
"""
import csv
import json
import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CSV = ROOT / "02_Data/Kudurru_Kings_Gameplay_Master_v1.csv"
CARDS = ROOT / "godot_client/data/real_cards_v1.json"
ADJ = ROOT / "godot_client/data/adjacency_descriptors_v1.json"
PRINTED = ROOT / "godot_client/data/printed_combat_transcription_v1.json"
OUTPUT = ROOT / "godot_client/data/m5_release_blockers.json"

REQUIRED = {
 "effect_implementation": "742 cards still lack sandbox-verified full printed abilities",
 "numeric_stat_authority": "664 printed Guard/First Strike conflicts with structured master",
 "targeting": "Critical targeting legality still absent from master target_rule_ref",
 "triggers": "No populated trigger_windows values in canonical card master",
 "scenario_objective": "Every Standard match needs a scenario/objective; none certified in M5 engine",
 "boss_special": "Boss aura/retaliation and stance consequences are not implemented",
 "capture_outcome": "Capture attempt success and failure adjudication still unspecified",
 "binding": "No certified universal Bind action; test-only evidence injection remains restricted",
 "combat_global": "Only precisely source-matched Character bonuses resolve; incomplete support effects, protections and legal consequence systems",
 "arbitration_options": "Suppress and Corrupt post-bid state transitions remain undefined",
 "faceoff_exhaustion": "Double-empty Face-off tie needs governing termination rule",
 "board_geometry": "Two-Field control, Lines, Geasa and legal traversal need complete implementation",
 "raid": "Site raids and 2-Mark scoring need scenario-legal actions",
 "progression": "Permanent collection copy reward, currencies, anti-duplication and persistence are not implemented",
 "multiplayer": "Server authority, hidden information and reconnect protections not implemented",
 "solo_ai": "Full-match legal-action AI not implemented",
 "assets": "Source-verified card render export and interactive workstation QA still pending",
 "faction_authority": "EOE Crosswalk reconciliation incomplete for all 754 master records",
 "pure_faction_bonus": "Pure-faction benefits approved in principle but effects/activation criteria undefined",
}

def build():
    with CSV.open(encoding="utf-8-sig", newline="") as stream:
        data = list(csv.DictReader(stream))
    cards = json.loads(CARDS.read_text(encoding="utf-8"))
    adj = json.loads(ADJ.read_text(encoding="utf-8"))
    printed = json.loads(PRINTED.read_text(encoding="utf-8"))
    if len(data) != 754 or cards["record_count"] != 754:
        raise ValueError("Master not complete")
    if hashlib.sha256(CSV.read_bytes()).hexdigest() != cards["source_sha256"]:
        raise ValueError("Card import stale")
    if cards["sandbox_effect_count"] != 12 or cards["production_playable_count"] != 0:
        raise ValueError("Incorrect effect release status")
    if adj["descriptor_count"] != 423 or adj["full_match_ready"] is not False:
        raise ValueError("Adjacency capability incorrectly marked complete")
    if printed["guard_or_first_strike_schema_disagreements"] != 664:
        raise ValueError("Combat authority changed without reconciliation")
    missing_target_rules = sum(not x["target_rule_ref"].strip() for x in data)
    missing_trigger_windows = sum(not x["trigger_windows"].strip() for x in data)
    boss_aura_false = sum(x["card_family"] == "Boss" and x["boss_has_aura"] == "False" for x in data)
    boss_retaliation_false = sum(x["card_family"] == "Boss" and x["boss_has_retaliation"] == "False" for x in data)
    if missing_target_rules != 754 or missing_trigger_windows != 754:
        raise ValueError("New target or trigger data found: re-audit")
    if boss_aura_false != 164 or boss_retaliation_false != 164:
        raise ValueError("Boss special schema changed: re-audit")
    return {
        "schema": "kudurru_m5_release_readiness_v1",
        "stage": "M5_PARTIAL_SOURCE_OWNED",
        "full_standard_ready": False,
        "commercial_release_ready": False,
        "engine": "Godot 4.7.2",
        "full_card_import": 754,
        "source_pinned_sandbox_effects": 12,
        "unsupported_effects": 742,
        "compiled_adjacency_descriptors": 423,
        "printed_combat_conflict_records": 664,
        "missing_target_rule_refs": missing_target_rules,
        "missing_trigger_windows": missing_trigger_windows,
        "bosses_without_activated_aura_flag": boss_aura_false,
        "bosses_without_activated_retaliation_flag": boss_retaliation_false,
        "known_corrected_source_phase_issue": "End income now applied at End, not upon leaving Resolution",
        "implemented_m5_sandbox_subsystems": [
            "real-character_source-limited_combat", "half-rounded-up_support",
            "matching_resource_spends_0_to_2", "same-axis_faceoff",
            "wound_thresholds_and_downed", "declined_capture_defeated",
            "two_full_round_defeated_restoration",
            "sealed_oath_arbitration_with_seize_only",
        ],
        "unresolved_gates": REQUIRED,
        "external_canon_documents_published": False,
        "rewards_enabled": False,
        "release_approval_required": True,
    }
if __name__ == "__main__":
    result = build()
    OUTPUT.write_text(json.dumps(result, sort_keys=True, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("M5_READINESS_AUDIT active_blockers=%d production_card_effects=0 full_standard_ready=false" % len(REQUIRED))
