#!/usr/bin/env python3
"""Source-preservation and unsupported-effect gates for real card M4."""
import csv
import hashlib
import json
import unittest
from pathlib import Path
import sys

TOOLS=Path(__file__).resolve().parents[1]/"tools"
sys.path.insert(0,str(TOOLS))
import build_real_cards as cards
import compile_character_mechanics as mechanics

class TestRealCardSource(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.data,cls.coverage=cards.build()
  cls.printed,cls.adjacent=mechanics.compile()
  cls.by={r["card_id"]:r for r in cls.data["cards"]}

 def test_754_original_identities(self):
  self.assertEqual(754,len(self.by))
  self.assertEqual(754,self.data["record_count"])
  self.assertEqual(8,len(self.coverage["by_family"]))

 def test_all_actual_effect_text_retained(self):
  with cards.MASTER.open(encoding="utf-8-sig",newline="") as f: source=list(csv.DictReader(f))
  for r in source:
   self.assertEqual(r["rules_text"],self.by[r["card_id"]]["rules_text"])
   self.assertEqual(r["owner_faction"],self.by[r["card_id"]]["owner_faction"])
   self.assertEqual(r["card_name"],self.by[r["card_id"]]["card_name"])
   self.assertEqual(int(r["cost_oath"]),self.by[r["card_id"]]["cost_oath"])

 def test_eoe_faction_display_overlay_preserved(self):
  x=self.by["686"]
  self.assertEqual("UnderwellKeepers",x["display_faction"])
  self.assertEqual("FloodbornPact",x["owner_faction"])
  self.assertEqual("EOE_VERIFIED_CONFLICT",x["faction_provenance"])

 def test_no_production_card_certification(self):
  self.assertEqual(0,self.data["production_playable_count"])
  self.assertTrue(all(c["production_playable"] is False for c in self.data["cards"]))

 def test_pinned_effect_coverage(self):
  self.assertEqual(12,len(cards.PINNED))
  self.assertEqual(12,self.data["sandbox_effect_count"])
  self.assertEqual(742,self.coverage["unimplemented_count"])
  self.assertEqual(set(cards.PINNED),
   {x["card_id"] for x in self.data["cards"] if x["sandbox_effect_implemented"]})

 def test_exact_pinned_hashes(self):
  for id_, sha in cards.PINNED.items():
   record=self.by[id_]
   self.assertEqual(sha,record["rules_sha256"])
   self.assertEqual("SANDBOX_TEST_REQUIRED",record["effect_status"])

 def test_legacy_render_only_no_fake_playability(self):
  self.assertEqual("UNIMPLEMENTED",self.by["181"]["effect_status"])
  self.assertFalse(self.by["181"]["sandbox_effect_implemented"])
  self.assertFalse(self.by["255"]["production_playable"])

 def test_combat_source_parsed_without_override(self):
  self.assertEqual(664,self.printed["combat_family_records"])
  self.assertEqual(664,self.printed["parsed_printed_values"])
  self.assertFalse(self.printed["override_structured_stats"])
  self.assertEqual(664,self.printed["guard_or_first_strike_schema_disagreements"])

 def test_423_exact_adjacency_only(self):
  self.assertEqual(423,self.adjacent["descriptor_count"])
  self.assertFalse(self.adjacent["full_match_ready"])
  self.assertEqual(423,len({r["card_id"] for r in self.adjacent["source_card_effects"]}))
  for r in self.adjacent["source_card_effects"]:
   self.assertEqual("Character",self.by[r["card_id"]]["card_family"])
   self.assertEqual(self.by[r["card_id"]]["rules_sha256"],r["source_sha256"])
   self.assertEqual(0,mechanics.adjacency_modifier(r,0))
   self.assertEqual(1,mechanics.adjacency_modifier(r,1))
   self.assertEqual(1,mechanics.adjacency_modifier(r,8))

 def test_generated_registry_identical(self):
  saved=json.loads(cards.OUT.read_text(encoding="utf-8"))
  self.assertEqual(saved,self.data)
  saved_desc=json.loads(mechanics.ACTIONS.read_text(encoding="utf-8"))
  self.assertEqual(saved_desc,self.adjacent)

 def test_export_card_counts(self):
  self.assertEqual(500,self.coverage["by_family"]["Character"])
  self.assertEqual(164,self.coverage["by_family"]["Boss"])
  for fam in ("Name","Edict","Site","Relic","Pet","HostSigil"):
   self.assertEqual(15,self.coverage["by_family"][fam])

if __name__=="__main__":
 unittest.main(verbosity=2)
