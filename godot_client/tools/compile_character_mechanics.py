#!/usr/bin/env python3
"""Transcribe printed initiative/guard/first strike and strictly matched adjacency text.
Printed values are observed source facts, NOT approved replacements for structured
gameplay authority or a complete combat resolver.
"""
import csv,hashlib,json,re
from collections import Counter
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
SRC=ROOT/"02_Data/Kudurru_Kings_Gameplay_Master_v1.csv"
OUT=ROOT/"godot_client/data/printed_combat_transcription_v1.json"
ACTIONS=ROOT/"godot_client/data/adjacency_descriptors_v1.json"
PREFIX=re.compile(r"^(?P<label>[^\n]+?) Initiative \((?P<initiative>\d+)\)\n🛡️ Guard (?P<guard>\d+) • ⚔️ First Strike (?P<first_strike>\d+)(?:\n|$)")
EXACT=re.compile(r"^(?:Basic|Standard|Heroic) Initiative \(\d+\)\n🛡️ Guard \d+ • ⚔️ First Strike \d+\nChecks get \+1 when adjacent to an ally\.$")
def compile():
 with SRC.open(encoding="utf-8-sig",newline="") as f: rows=list(csv.DictReader(f))
 if len(rows)!=754: raise ValueError("Master count changed")
 transcription=[]
 adjacency=[]
 mismatches=[]
 unparsed=[]
 for row in rows:
  if row["card_family"] not in ("Character","Boss"): continue
  text=row["rules_text"].replace("\r\n","\n")
  match=PREFIX.match(text)
  if not match:
   unparsed.append({"card_id":row["card_id"],"name":row["card_name"]})
   continue
  value={
   "card_id":row["card_id"],"name":row["card_name"],"family":row["card_family"],
   "rules_sha256":hashlib.sha256(text.encode("utf-8")).hexdigest(),
   "printed_initiative_label":match["label"],"printed_initiative":int(match["initiative"]),
   "printed_guard":int(match["guard"]),"printed_first_strike":int(match["first_strike"]),
   "structured_guard":row["guard"],"structured_first_strike":row["first_strike"],
   "authority_status":"PRINTED_EVIDENCE_NOT_PROMOTED_TO_GAMEPLAY",
  }
  transcription.append(value)
  if row["guard"]!=str(int(match["guard"])) or (
      row["first_strike"].lower() not in ("true","false")) or (
      row["first_strike"].lower()=="false" and int(match["first_strike"])>0):
   mismatches.append(row["card_id"])
  if EXACT.fullmatch(text):
   adjacency.append({
    "card_id":row["card_id"],
    "source_sha256":value["rules_sha256"],
    "trigger":"ON_COMBAT_TEST",
    "condition":{"adjacent_friendly_unit_count_min":1},
    "modifier":{"tested_axis_total":1},
    "limits":"requires separately certified adjacency and combat resolver",
    "sandbox_descriptor_only":True
   })
 if len(transcription)+len(unparsed)!=664: raise ValueError("Combat identity count mismatch")
 if len(adjacency)!=423: raise ValueError(f"Unexpected precise adjacent-only count: {len(adjacency)}")
 if len({x["card_id"] for x in adjacency})!=423: raise ValueError("Duplicate adjacency descriptor")
 report={
  "schema":"kudurru_printed_combat_transcription_v1",
  "source_sha256":hashlib.sha256(SRC.read_bytes()).hexdigest(),
  "combat_family_records":664,
  "parsed_printed_values":len(transcription),
  "unparsed":unparsed,
  "guard_or_first_strike_schema_disagreements":len(mismatches),
  "mismatch_card_ids":mismatches,
  "mechanics":transcription,
  "override_structured_stats":False,
 }
 descriptor_report={
  "schema":"kudurru_exact_adjacency_v1",
  "source_sha256":report["source_sha256"],"descriptor_count":423,
  "full_match_ready":False,"source_card_effects":adjacency
 }
 return report,descriptor_report
def adjacency_modifier(record:dict,ally_count:int)->int:
 if record["trigger"]!="ON_COMBAT_TEST" or record["modifier"]!={"tested_axis_total":1}:
  raise ValueError("Unknown adjacency rule")
 if not isinstance(ally_count,int) or ally_count<0: raise ValueError("Invalid adjacency evidence")
 return 1 if ally_count>=1 else 0

if __name__=="__main__":
 report,descriptors=compile()
 OUT.write_text(json.dumps(report,indent=2,ensure_ascii=False,sort_keys=True)+"\n",encoding="utf-8")
 ACTIONS.write_text(json.dumps(descriptors,indent=2,ensure_ascii=False,sort_keys=True)+"\n",encoding="utf-8")
 print("PRINTED_COMBAT_AUDIT records=%d parsed=%d inconsistencies=%d exactly_matched_adjacent=%d"%(
  report["combat_family_records"],report["parsed_printed_values"],
  report["guard_or_first_strike_schema_disagreements"],descriptors["descriptor_count"]))
