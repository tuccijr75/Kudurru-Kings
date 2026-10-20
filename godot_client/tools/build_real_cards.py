#!/usr/bin/env python3
"""Complete source-pinned 754-real-card catalog; no production play certification."""
import csv, hashlib, json
from collections import Counter
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
MASTER = ROOT / "02_Data/Kudurru_Kings_Gameplay_Master_v1.csv"
PREVIEW = ROOT / "godot_client/data/catalog_preview.json"
OUT = ROOT / "godot_client/data/real_cards_v1.json"
REPORT = ROOT / "godot_client/data/real_effect_coverage_v1.json"
PINNED = {
"180":"ce7971bb9a5f38d35b45562cbf5f7c3ef41d4e043339b05ca6c9f9f471ae8cc0",
"184":"d621bcd0a495f80999dcc4dc3e791f040f970e4186a2b8c57495e00bbcfccc94",
"185":"27397efb602eda36d49fcb9d83b768ee3491672c00aa9921bf0fc5e56e16e7f3",
"187":"9c6964e87975c030d3f2d161334c66973974d73c00b9edef9227b30efbe1dc40",
"189":"4ed10094e651562647412fe0fac64cb0d42daf606ded46360e90e6d4a1a6abba",
"191":"01a059adfba723ec3e22b6e8be4ffa27946b778e6e4797fb0c6f39670f4b377f",
"193":"c0a3917b78511bf01bf64fe0f39e9c9a065dac4e65adb2e4cd39569100935278",
"199":"8dd1c2909c058f31a064566c58f72dc5132e4025181f49aab5427102a1e5fa20",
"206":"21fa77ca88dbb7eba315d49653b2050fc4ccef003e8d0b3cb511e74ac560c63b",
"207":"d4853820138dd098cdbef7fb4073f8fab85e9d603fd0fbff9024053da7cb09e8",
"214":"d36bef97289a48543ead3b18f7744f44bd03afcec75a97fd0b84dd27bb9b8c7b",
"216":"8a8db6ddd60bb781e6af42f2e028fde3303b919abb1be9dc59bc491a2b32fb44",
}
FIELDS = ("card_id","card_slug","card_name","card_family","owner_faction","rarity","subtype_primary","is_standard_legal","scenario_only","requires_faction_lock","allowed_splash","deck_copy_limit","cost_sinew","cost_sigil","cost_oath","upkeep_oath","stone","veil","authority","guard","first_strike","initiative","vitality","wound_threshold","support_value_rule","heat_on_support","play_timing","enters_play_zone","site_type","heat_on_install","rules_text")
INTS = {"cost_sinew","cost_sigil","cost_oath","upkeep_oath","stone","veil","authority","guard","initiative","vitality"}
BOOLS = {"is_standard_legal","scenario_only","requires_faction_lock","allowed_splash","first_strike"}
def build():
 raw = MASTER.read_bytes()
 with MASTER.open(encoding="utf-8-sig", newline="") as f:
  reader = csv.DictReader(f)
  if set(FIELDS)-set(reader.fieldnames or ()): raise ValueError("Missing canonical fields")
  rows = list(reader)
 preview = json.loads(PREVIEW.read_text(encoding="utf-8"))
 if preview["source_sha256"] != hashlib.sha256(raw).hexdigest(): raise ValueError("Stale faction preview")
 index = {v["card_id"]:v for v in preview["cards"]}
 if len(rows)!=754 or len(index)!=754: raise ValueError("Incomplete catalog")
 provenance=json.loads((ROOT/"godot_client/data/m6_guard_first_strike_migration.json").read_text(encoding="utf-8"))
 stats={s["card_id"]:s for s in provenance["records"]}
 if len(stats)!=664: raise ValueError("Combat rating migration is missing or incomplete")
 cards, seen = [], set()
 for r in rows:
  ident=r["card_id"]
  if ident in seen or ident not in index: raise ValueError("Duplicate/untracked immutable ID")
  seen.add(ident)
  c={k:r[k] for k in FIELDS}
  for k in INTS: c[k]=int(c[k])
  for k in BOOLS:
   if c[k] not in ("True","False"): raise ValueError("Invalid boolean")
   c[k]=c[k]=="True"
  if ident in stats:
   evidence=stats[ident]
   if c["guard"]!=evidence["printed_guard"] or c["first_strike"]!=(evidence["printed_first_strike_rating"]>0) or c["initiative"]!=evidence["printed_initiative"]:
    raise ValueError("Structured combat value diverged from printed card: "+ident)
   c["first_strike_rating"]=evidence["printed_first_strike_rating"]
   c["combat_stat_provenance"]="SOURCE_HASHED_PRINTED_V1"
  else:
   if c["guard"]!=0 or c["first_strike"] or c["initiative"]!=0: raise ValueError("Noncombat values changed: "+ident)
   c["first_strike_rating"]=0
   c["combat_stat_provenance"]="NOT_COMBAT_CAPABLE"
  c["display_faction"]=index[ident]["display_faction"]
  c["faction_provenance"]=index[ident]["faction_provenance"]
  digest=hashlib.sha256(c["rules_text"].replace("\r\n","\n").encode()).hexdigest()
  c["rules_sha256"]=digest
  if ident in stats and stats[ident]["rules_sha256"] != digest: raise ValueError("Combat rating text drift: "+ident)
  if ident in PINNED and PINNED[ident]!=digest: raise ValueError("Effect source drift: "+ident)
  c["effect_status"]="SANDBOX_TEST_REQUIRED" if ident in PINNED else "UNIMPLEMENTED"
  c["sandbox_effect_implemented"]=ident in PINNED
  c["production_playable"]=False
  cards.append(c)
 if len(seen)!=754 or sum(c["sandbox_effect_implemented"] for c in cards)!=len(PINNED):
  raise ValueError("Effect registry mismatch")
 return {
  "schema":"kudurru_real_cards_v1","source_sha256":hashlib.sha256(raw).hexdigest(),
  "record_count":754,"production_playable_count":0,
  "sandbox_effect_count":len(PINNED),"cards":cards,
 }, {
  "schema":"kudurru_effect_coverage_v1","total":754,
  "sandbox_effect_count":len(PINNED),"unimplemented_count":754-len(PINNED),
  "production_certified":0,"by_family":dict(Counter(c["card_family"] for c in cards)),
  "pinned_hashes":PINNED,
 }
if __name__=="__main__":
 data,coverage=build()
 OUT.write_text(json.dumps(data,indent=2,sort_keys=True,ensure_ascii=False)+"\n",encoding="utf-8")
 REPORT.write_text(json.dumps(coverage,indent=2,sort_keys=True)+"\n",encoding="utf-8")
 print("REAL_CARD_BUILD_OK cards=%d sandbox=%d production=%d"%(data["record_count"],data["sandbox_effect_count"],data["production_playable_count"]))
