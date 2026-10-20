#!/usr/bin/env python3
"""Standard-library integrity suite for approved Kudurru Kings cost baseline v1."""
from __future__ import annotations
import csv
import json
import unittest
from pathlib import Path
import sys

TOOLS = Path(__file__).resolve().parents[1] / "tools"
sys.path.insert(0, str(TOOLS))
import balance_costs as mod
import export_cost_panel as exporter

class TestCostBaseline(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.header, cls.rows, cls.raw = mod.load()
        cls.report = json.loads(mod.REPORT.read_text(encoding="utf-8"))
        cls.baseline = json.loads(mod.BASELINE.read_text(encoding="utf-8"))
        cls.by_id = {r["card_id"]: r for r in cls.rows}

    def test_card_count_and_identity(self):
        self.assertEqual(754, len(self.rows))
        self.assertEqual(754, len(self.by_id))
        self.assertEqual(136, len(self.header))

    def test_baseline_snapshot_preserved(self):
        self.assertEqual(754, len(self.baseline["original"]))
        self.assertEqual(754, self.report["source_zero_deployment_count"])
        self.assertEqual(self.report["source_sha256_before_apply"], self.baseline["source_sha256"])

    def test_original_costs_are_undoable(self):
        self.assertTrue(all(int(x["cost_sinew"]) == 0 and int(x["cost_sigil"]) == 0
                            and int(x["cost_oath"]) == 0 for x in self.baseline["original"]))

    def test_positive_bounded_deployment_for_every_card(self):
        for row in self.rows:
            self.assertGreater(sum(int(row[f]) for f in mod.COST_FIELDS[:3]), 0, row["card_id"])
            self.assertLessEqual(int(row["cost_sinew"]), 5)
            self.assertLessEqual(int(row["cost_sigil"]), 2)
            self.assertLessEqual(int(row["cost_oath"]), 2)
            self.assertLessEqual(int(row["upkeep_oath"]), 1)

    def test_derived_profiles_match_written_master(self):
        for row in self.rows:
            derived = mod.derive(row)
            for field in mod.COST_FIELDS:
                self.assertEqual(int(row[field]), derived[field], (row["card_id"], field))

    def test_no_first_turn_boss(self):
        self.assertTrue(all(int(row["cost_sinew"]) >= 3 for row in self.rows if row["card_family"] == "Boss"))

    def test_boss_upkeep_feasible_for_objective_control(self):
        self.assertTrue(all(int(row["upkeep_oath"]) == 1 for row in self.rows if row["card_family"] == "Boss"))

    def test_nonboss_upkeep_limited(self):
        self.assertTrue(all(int(row["upkeep_oath"]) == 0 for row in self.rows
                            if row["card_family"] in ("Character", "Edict", "HostSigil", "Pet", "Relic", "Site")))

    def test_only_anu_and_adamu_apex(self):
        ultra = [r for r in self.rows if r["rarity"] == "Ultra"]
        self.assertEqual(2, len(ultra))
        self.assertEqual(["Adamu", "Anu the Exarch of Heaven"],
                         sorted(r["card_name"] for r in ultra))
        self.assertTrue(all(int(x["cost_oath"]) == 2 for x in ultra))

    def test_literal_invocation_override(self):
        lamassu = next(r for r in self.rows if r["card_name"] == "Lamassu, Gate-Guardian")
        self.assertEqual((2, 2), (int(lamassu["cost_oath"]), int(lamassu["cost_sigil"])))
        self.assertEqual(0, int(lamassu["upkeep_oath"]))

    def test_affordability_bounds(self):
        sim = self.report["affordability_stress_test"]
        self.assertEqual(12000, sim["samples"])
        self.assertGreaterEqual(sim["first_hand_any_affordable"], .88)
        self.assertGreaterEqual(sim["after_optional_mulligan_any_affordable"], .97)

    def test_repeatable_monte_carlo(self):
        costs = {r["card_id"]: mod.derive(r) for r in self.rows}
        self.assertEqual(mod.simulation(self.rows, costs, 1000),
                         mod.simulation(self.rows, costs, 1000))

    def test_no_premature_card_certification(self):
        self.assertFalse(self.report["fully_gameplay_certified"])
        catalog = json.loads((mod.ROOT / "godot_client/data/catalog_preview.json").read_text(encoding="utf-8"))
        self.assertEqual(0, catalog["playable_count"])
        self.assertTrue(all(c["playable"] is False for c in catalog["cards"]))

    def test_sidecar_matches_master(self):
        data = exporter.expected()
        records = list(csv.DictReader(data.decode("utf-8").splitlines()))
        self.assertEqual(754, len(records))
        self.assertEqual({r["card_id"] for r in self.rows}, {x["card_id"] for x in records})
        self.assertTrue(all(x["gameplay_certified"] == "false" for x in records))

    def test_only_approved_master_columns_differ_from_m2_base(self):
        import io
        import subprocess
        base = "ad3ec264e44606ccd1147e9222593bb37b02f82b:02_Data/Kudurru_Kings_Gameplay_Master_v1.csv"
        result = subprocess.run(
            ["git", "show", base], cwd=mod.ROOT, capture_output=True, check=True,
        )
        original = list(csv.DictReader(io.StringIO(result.stdout.decode("utf-8-sig"), newline="")))
        self.assertEqual(754, len(original))
        for old, new in zip(original, self.rows):
            self.assertEqual(old["card_id"], new["card_id"])
            for field in self.header:
                if field not in set(mod.COST_FIELDS) | {"guard", "first_strike"}:
                    # Git normalizes CRLF to LF on Windows checkout; preserve authored text.
                    self.assertEqual(old[field].replace("\r\n", "\n"),
                                     new[field].replace("\r\n", "\n"),
                                     (old["card_id"], field))

if __name__ == "__main__":
    unittest.main(verbosity=2)
