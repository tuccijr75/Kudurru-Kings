#!/usr/bin/env python3
"""M6 printed combat stat migration provenance and non-regression gate."""
import csv
import hashlib
import io
import json
import subprocess
import sys
import unittest
from collections import Counter
from pathlib import Path

TOOLS = Path(__file__).resolve().parents[1] / "tools"
sys.path.insert(0, str(TOOLS))
import reconcile_combat_stats as migrate
import build_real_cards
import compile_character_mechanics

PREIMAGE = "1600245eb846cb98a80cd77f09f89a34820a7b56:02_Data/Kudurru_Kings_Gameplay_Master_v1.csv"

class TestCombatSourceAuthority(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.headers, cls.rows, cls.raw = migrate.read()
        cls.snapshot = json.loads(migrate.SNAPSHOT.read_text(encoding="utf-8"))
        cls.cards, cls.coverage = build_real_cards.build()
        cls.byid = {r["card_id"]: r for r in cls.rows}
        cls.runtime = {r["card_id"]: r for r in cls.cards["cards"]}

    def test_original_source_hash(self):
        result = subprocess.run(["git", "show", PREIMAGE], cwd=migrate.ROOT,
                                check=True, capture_output=True)
        # Git stores normalized LF, while the canonical Windows checkout used CRLF.
        # Pin the immutable Git blob separately; row-level comparison below
        # proves only Guard/First Strike changed semantically.
        self.assertEqual("95ffde978412d4bd87656d9300f36b88a26e6d229cc497d85b4cff77d67e6544",
                         hashlib.sha256(result.stdout).hexdigest())
        self.assertEqual(754, len(self.rows))

    def test_only_two_canonically_authorized_columns_changed(self):
        result = subprocess.run(["git", "show", PREIMAGE], cwd=migrate.ROOT,
                                check=True, capture_output=True)
        original = list(csv.DictReader(io.StringIO(result.stdout.decode("utf-8-sig"), newline="")))
        self.assertEqual(754, len(original))
        changed = Counter()
        for old, new in zip(original, self.rows):
            self.assertEqual(old["card_id"], new["card_id"])
            for field in self.headers:
                if old[field].replace("\r\n", "\n") != new[field].replace("\r\n", "\n"):
                    changed[field] += 1
        self.assertEqual({"guard": 664, "first_strike": 664}, dict(changed))

    def test_snapshot_is_complete_and_original_values_reversible(self):
        specs = self.snapshot["records"]
        self.assertEqual(664, len(specs))
        self.assertEqual(664, len({r["card_id"] for r in specs}))
        self.assertEqual(migrate.SOURCE_BASE_SHA, self.snapshot["source_sha256_before"])
        for spec in specs:
            self.assertEqual("0", spec["old_guard"])
            self.assertEqual("False", spec["old_first_strike"])
            self.assertEqual(self.byid[spec["card_id"]]["guard"], spec["new_guard"])
            self.assertEqual(self.byid[spec["card_id"]]["first_strike"], spec["new_first_strike"])
            self.assertGreater(spec["printed_guard"], 0)
            self.assertGreater(spec["printed_first_strike_rating"], 0)

    def test_printed_guard_full_rating_and_initiative_reconcile(self):
        evidence, deltas = migrate.expected(self.rows)
        self.assertEqual([], deltas)
        self.assertEqual(664, len(evidence))
        report, descriptors = compile_character_mechanics.compile()
        self.assertEqual(0, report["guard_or_first_strike_schema_disagreements"])
        self.assertEqual(423, descriptors["descriptor_count"])
        for spec in evidence:
            actual = self.runtime[spec["card_id"]]
            self.assertEqual(spec["printed_guard"], actual["guard"])
            self.assertEqual(spec["printed_first_strike_rating"], actual["first_strike_rating"])
            self.assertEqual(spec["printed_initiative"], actual["initiative"])
            self.assertTrue(actual["first_strike"])
            self.assertFalse(actual["production_playable"])
            self.assertEqual("SOURCE_HASHED_PRINTED_V1", actual["combat_stat_provenance"])

    def test_noncombat_90_unchanged(self):
        others = [r for r in self.rows if r["card_family"] not in migrate.FAMILIES]
        self.assertEqual(90, len(others))
        for row in others:
            self.assertEqual(("0", "False", "0"), (
                row["guard"], row["first_strike"], row["initiative"]))
            card = self.runtime[row["card_id"]]
            self.assertEqual(0, card["first_strike_rating"])
            self.assertFalse(card["first_strike"])

    def test_all_combat_ratings_available_for_balance(self):
        values = Counter(r["printed_first_strike_rating"] for r in self.snapshot["records"])
        self.assertEqual(set(range(1,8)), set(values))
        self.assertEqual(664, sum(values.values()))
        guard = Counter(r["printed_guard"] for r in self.snapshot["records"])
        self.assertEqual(set(range(1,8)), set(guard))

    def test_reapplication_is_bitwise_idempotent(self):
        before = migrate.MASTER.read_bytes()
        migrate.run(apply=True)
        self.assertEqual(before, migrate.MASTER.read_bytes())

    def test_partial_source_edit_not_silently_accepted(self):
        copied = [r.copy() for r in self.rows]
        first = next(r for r in copied if r["card_family"] == "Character")
        first["guard"] = "0"
        with self.assertRaises(ValueError):
            migrate.expected(copied)

if __name__ == "__main__":
    unittest.main(verbosity=2)
