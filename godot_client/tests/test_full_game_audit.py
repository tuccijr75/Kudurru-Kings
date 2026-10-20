#!/usr/bin/env python3
"""M7 fail-closed commercial readiness and source-effect coverage audit."""
import json
import sys
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/"godot_client/tools"))
import audit_full_game as scan

class TestM7Completion(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.audit,cls.templates=scan.build()
 def test_exact_card_ledger(self):
  self.assertEqual(754,self.audit["source_card_count"])
  self.assertEqual(754,len(self.audit["card_manifest"]))
  self.assertEqual(754,len({x["card_id"] for x in self.audit["card_manifest"]}))
 def test_all_family_counts(self):
  self.assertEqual({"Character":500,"Boss":164,"HostSigil":15,"Edict":15,
                    "Name":15,"Site":15,"Relic":15,"Pet":15},
                   self.audit["by_family"])
 def test_effect_compiler_partition(self):
  self.assertEqual(121,len(self.templates))
  self.assertEqual(121,self.audit["unique_effect_templates"])
  self.assertEqual(754,sum(len(x["card_ids"]) for x in self.templates))
  self.assertEqual(423,self.audit["effect_statuses"]["M7_CHARACTER_BASIC_SANDBOX"])
  self.assertEqual(10,self.audit["effect_statuses"]["M4_SOURCE_EFFECT_SANDBOX"])
  self.assertEqual(4,self.audit["effect_statuses"]["M8_LIVE_EDICT_CANDIDATE"])
  self.assertEqual(3,self.audit["effect_statuses"]["M7_PRESENT_EFFECT_NOT_FULLY_CERTIFIED"])
  self.assertEqual(314,self.audit["effect_statuses"]["UNIMPLEMENTED_OR_UNVERIFIED"])
 def test_legacy_terms_not_silently_converted(self):
  self.assertEqual(239,self.audit["source_migration_term_counts"]["legacy_supply"])
  self.assertEqual(239,self.audit["source_migration_term_counts"]["legacy_recoil"])
  self.assertGreater(self.audit["source_migration_term_counts"]["deprecated_wind"],0)
  self.assertGreater(self.audit["source_migration_term_counts"]["deprecated_eye"],0)
 def test_release_is_blocked(self):
  self.assertFalse(self.audit["full_standard_releasable"])
  self.assertFalse(self.audit["multiplayer_releasable"])
  self.assertTrue(self.audit["candidate_local_match_available"])
  self.assertEqual(5,self.audit["passed_gate_count"])
  self.assertEqual(11,self.audit["in_progress_gate_count"])
  self.assertEqual(6,self.audit["blocked_gate_count"])
 def test_all_22_domain_criteria_present(self):
  domains=self.audit["production_game_gates"]
  self.assertEqual(22,len(domains))
  for name,data in domains.items():
   self.assertIn(data["status"],("PASS","IN_PROGRESS","BLOCKED"),name)
   self.assertGreater(len(data["remaining"]),20,name)
 def test_no_production_card_false_positive(self):
  self.assertTrue(all(not row["production_certified"] for row in self.audit["card_manifest"]))
 def test_generated_report_reproducible(self):
  saved=json.loads(scan.OUT.read_text(encoding="utf-8"))
  self.assertEqual(self.audit,saved)
  groups=json.loads(scan.GROUP_REPORT.read_text(encoding="utf-8"))
  self.assertEqual(len(groups["templates"]),len(self.templates))

if __name__=="__main__":
 unittest.main(verbosity=2)
