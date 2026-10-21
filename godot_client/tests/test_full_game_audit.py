#!/usr/bin/env python3
"""M7 fail-closed commercial readiness and source-effect coverage audit."""
import json
import sys
import unittest
import tempfile
from unittest.mock import patch
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
  self.assertEqual(7,self.audit["effect_statuses"]["M4_SOURCE_EFFECT_SANDBOX"])
  self.assertEqual(10,self.audit["effect_statuses"]["M16_LIVE_EDICT_CANDIDATE"])
  self.assertEqual(3,self.audit["effect_statuses"]["M7_PRESENT_EFFECT_NOT_FULLY_CERTIFIED"])
  self.assertEqual(311,self.audit["effect_statuses"]["UNIMPLEMENTED_OR_UNVERIFIED"])
 def test_legacy_terms_not_silently_converted(self):
  self.assertEqual(239,self.audit["source_migration_term_counts"]["legacy_supply"])
  self.assertEqual(239,self.audit["source_migration_term_counts"]["legacy_recoil"])
  self.assertGreater(self.audit["source_migration_term_counts"]["deprecated_wind"],0)
  self.assertGreater(self.audit["source_migration_term_counts"]["deprecated_eye"],0)
 def test_release_is_blocked(self):
  self.assertFalse(self.audit["full_standard_releasable"])
  self.assertFalse(self.audit["multiplayer_releasable"])
  self.assertTrue(self.audit["candidate_local_match_available"])
  self.assertEqual(6,self.audit["passed_gate_count"])
  self.assertEqual(11,self.audit["in_progress_gate_count"])
  self.assertEqual(6,self.audit["blocked_gate_count"])
 def test_all_23_domain_criteria_present(self):
  domains=self.audit["production_game_gates"]
  self.assertEqual(23,len(domains))
  for name,data in domains.items():
   self.assertIn(data["status"],("PASS","IN_PROGRESS","BLOCKED"),name)
   self.assertGreater(len(data["remaining"]),20,name)
 def test_no_production_card_false_positive(self):
  self.assertTrue(all(not row["production_certified"] for row in self.audit["card_manifest"]))
 def test_generated_report_reproducible(self):
  saved=json.loads(scan.OUT.read_text(encoding="utf-8"))
  self.assertEqual(self.audit,saved)
  groups=json.loads(scan.GROUP_REPORT.read_text(encoding="utf-8"))
  self.assertEqual(groups["templates"],self.templates)

 def test_template_inventory_keeps_card_evidence_and_certification_separate(self):
  records={r["card_id"]:r for r in self.audit["card_manifest"]}
  for group in self.templates:
   self.assertEqual(group["source_card_count"],sum(group["candidate_status_counts"].values()))
   self.assertEqual(set(group["card_ids"]),set(group["source_rules_hashes"]))
   self.assertEqual(0,group["production_certified_count"])
   self.assertIn("not executable equivalence",group["coverage_contract"])
   for ident,digest in group["source_rules_hashes"].items():
    self.assertEqual(records[ident]["rules_sha256"],digest)

 def _reject_catalog_change(self,mutate):
  data=json.loads(scan.CATALOG.read_text(encoding="utf-8"))
  mutate(data)
  with tempfile.TemporaryDirectory() as directory:
   path=Path(directory)/"catalog.json"
   path.write_text(json.dumps(data),encoding="utf-8")
   with patch.object(scan,"CATALOG",path),self.assertRaises(ValueError):scan.build()

 def test_reject_unknown_catalog_schema(self):
  self._reject_catalog_change(lambda d:d.update(schema="untrusted"))

 def test_reject_catalog_rules_tampering_with_unchanged_top_level_hash(self):
  self._reject_catalog_change(lambda d:d["cards"][0].update(rules_text="fabricated effect"))

 def test_reject_catalog_identity_duplication(self):
  self._reject_catalog_change(lambda d:d["cards"].__setitem__(1,d["cards"][0]))

 def test_reject_catalog_incomplete_rows(self):
  self._reject_catalog_change(lambda d:d["cards"].pop())

 def test_reject_catalog_hash_forgery(self):
  self._reject_catalog_change(lambda d:d["cards"][0].update(rules_sha256="0"*64))

 def test_reject_catalog_production_unlock(self):
  self._reject_catalog_change(lambda d:d["cards"][0].update(production_playable=True))

 def test_reject_catalog_stat_mutation(self):
  self._reject_catalog_change(lambda d:d["cards"][20].update(stone=999))

 def test_reject_bool_substituted_for_numeric_value(self):
  self._reject_catalog_change(lambda d:d["cards"][0].update(stone=False))

 def test_reject_derived_combat_rating_tampering(self):
  self._reject_catalog_change(lambda d:d["cards"][20].update(first_strike_rating=999))

 def test_reject_derived_combat_provenance_tampering(self):
  self._reject_catalog_change(lambda d:d["cards"][20].update(combat_stat_provenance="FABRICATED"))

 def test_reject_derived_faction_display_tampering(self):
  self._reject_catalog_change(lambda d:d["cards"][0].update(display_faction="FABRICATED"))

 def test_reject_derived_faction_provenance_tampering(self):
  self._reject_catalog_change(lambda d:d["cards"][0].update(faction_provenance="FABRICATED"))

 def test_reject_descriptor_parameter_tampering(self):
  data=json.loads(scan.ADJACENCY.read_text(encoding="utf-8"))
  data["source_card_effects"][0]["modifier"]["tested_axis_total"]=999
  with tempfile.TemporaryDirectory() as directory:
   path=Path(directory)/"adjacency.json"
   path.write_text(json.dumps(data),encoding="utf-8")
   with patch.object(scan,"ADJACENCY",path),self.assertRaises(ValueError):scan.build()

 def test_reject_descriptor_boolean_substituted_for_integer(self):
  data=json.loads(scan.ADJACENCY.read_text(encoding="utf-8"))
  data["source_card_effects"][0]["modifier"]["tested_axis_total"]=True
  with tempfile.TemporaryDirectory() as directory:
   path=Path(directory)/"adjacency.json"
   path.write_text(json.dumps(data),encoding="utf-8")
   with patch.object(scan,"ADJACENCY",path),self.assertRaises(ValueError):scan.build()

 def test_reject_descriptor_float_substituted_for_integer(self):
  data=json.loads(scan.ADJACENCY.read_text(encoding="utf-8"))
  data["source_card_effects"][0]["modifier"]["tested_axis_total"]=1.0
  with tempfile.TemporaryDirectory() as directory:
   path=Path(directory)/"adjacency.json"
   path.write_text(json.dumps(data),encoding="utf-8")
   with patch.object(scan,"ADJACENCY",path),self.assertRaises(ValueError):scan.build()

 def test_reject_descriptor_hash_tampering(self):
  data=json.loads(scan.ADJACENCY.read_text(encoding="utf-8"))
  data["source_card_effects"][0]["source_sha256"]="0"*64
  with tempfile.TemporaryDirectory() as directory:
   path=Path(directory)/"adjacency.json"
   path.write_text(json.dumps(data),encoding="utf-8")
   with patch.object(scan,"ADJACENCY",path),self.assertRaises(ValueError):scan.build()

if __name__=="__main__":
 unittest.main(verbosity=2)
