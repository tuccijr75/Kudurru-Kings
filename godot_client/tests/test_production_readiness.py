#!/usr/bin/env python3
"""Adversarial checks for source drift and false production promotion."""
import copy
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'godot_client/tools'))
import audit_production_readiness as scan


class ProductionReadiness(unittest.TestCase):
    def setUp(self):
        self.documents = {name: scan.read(ROOT, name) for name in (
            'full_game_completion_audit.json', 'final_completion_ledger.json')}
        optional = ROOT / 'godot_client/data/card_asset_audit_v1.json'
        if optional.exists():
            self.documents[optional.name] = scan.read(ROOT, optional.name)

    def run_inventory(self):
        with patch.object(scan, 'read', side_effect=lambda root, name: copy.deepcopy(self.documents[name])):
            return scan.inventory(ROOT)

    def test_missing_art_evidence_is_not_established(self):
        self.assertEqual('NOT_ESTABLISHED', scan.asset_evidence(None, 'pin', set())['status'])

    def test_stale_art_evidence_rejected(self):
        with self.assertRaisesRegex(ValueError, 'art evidence provenance'):
            scan.asset_evidence({'cards': [], 'schema': 'kudurru_card_asset_audit_v1'}, 'pin', set())

    def art_document(self):
        return {'schema': 'kudurru_card_asset_audit_v1', 'source_sha256': 'pin',
                'source_card_count': 754, 'evidence_complete_count': 0,
                'cards': [{'card_id': str(i), 'evidence_complete': False} for i in range(754)]}

    def test_complete_mapping_partition_still_not_certification(self):
        document = self.art_document()
        result = scan.asset_evidence(document, 'pin', {str(i) for i in range(754)})
        self.assertEqual('DECLARED_EVIDENCE_ONLY', result['status'])
        self.assertIn('NOT_ESTABLISHED', result['certification'])

    def test_art_aggregate_lie_rejected(self):
        document = self.art_document()
        document['evidence_complete_count'] = 754
        with self.assertRaisesRegex(ValueError, 'disagrees'):
            scan.asset_evidence(document, 'pin', {str(i) for i in range(754)})

    def test_duplicate_art_mapping_rejected(self):
        document = self.art_document()
        document['cards'][-1] = copy.deepcopy(document['cards'][0])
        with self.assertRaisesRegex(ValueError, 'art evidence provenance'):
            scan.asset_evidence(document, 'pin', {str(i) for i in range(754)})

    def test_actual_candidate_stays_closed(self):
        result = self.run_inventory()
        self.assertEqual(754, result['source_cards'])
        self.assertEqual(0, result['card_stage_declarations']['production_certified'])
        self.assertEqual(7, len(result['gates']))
        self.assertFalse(result['release_authorized'])
        self.assertTrue(all(g['status'] == 'CLOSED' for g in result['gates'].values()))

    def test_candidate_pass_never_certifies(self):
        for system in self.documents['final_completion_ledger.json']['systems']:
            system['status'] = 'PASS'
            self.documents['full_game_completion_audit.json']['production_game_gates'][system['id']]['status'] = 'PASS'
        self.assertEqual('CLOSED', self.run_inventory()['production_status'])

    def test_duplicate_and_missing_card_rejected(self):
        cards = self.documents['final_completion_ledger.json']['cards']
        cards[-1] = copy.deepcopy(cards[0])
        with self.assertRaisesRegex(ValueError, 'identities'):
            self.run_inventory()

    def test_stale_master_rejected(self):
        self.documents['full_game_completion_audit.json']['master_sha256'] = '0' * 64
        with self.assertRaisesRegex(ValueError, 'provenance'):
            self.run_inventory()

    def test_stale_card_rule_rejected(self):
        self.documents['final_completion_ledger.json']['cards'][0]['rules_sha256'] = '0' * 64
        with self.assertRaisesRegex(ValueError, 'Stale or misidentified'):
            self.run_inventory()

    def test_truthy_string_is_not_certification(self):
        self.documents['final_completion_ledger.json']['cards'][0]['release_certified'] = 'false'
        with self.assertRaisesRegex(ValueError, 'explicit boolean'):
            self.run_inventory()

    def test_aggregate_certification_lie_rejected(self):
        self.documents['final_completion_ledger.json']['production_certified_card_count'] = 754
        with self.assertRaisesRegex(ValueError, 'total disagrees'):
            self.run_inventory()

    def test_partial_card_cannot_be_certified(self):
        self.documents['final_completion_ledger.json']['cards'][0]['production_certified'] = True
        with self.assertRaisesRegex(ValueError, 'required stages'):
            self.run_inventory()

    def test_missing_security_domain_rejected(self):
        systems = self.documents['final_completion_ledger.json']['systems']
        systems[:] = [s for s in systems if s['id'] != 'security_privacy']
        with self.assertRaisesRegex(ValueError, 'production domain'):
            self.run_inventory()

    def test_stale_status_rejected(self):
        self.documents['final_completion_ledger.json']['systems'][0]['status'] = 'PASS'
        with self.assertRaisesRegex(ValueError, 'Stale system'):
            self.run_inventory()

    def test_editing_status_cannot_open_production(self):
        self.documents['final_completion_ledger.json']['production_status'] = 'OPEN'
        with self.assertRaisesRegex(ValueError, 'separately approved'):
            self.run_inventory()


if __name__ == '__main__':
    unittest.main(verbosity=2)
