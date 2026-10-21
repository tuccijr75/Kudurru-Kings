"""Adversarial asset evidence fixtures; no claims about the real artwork's rights."""
import csv
import contextlib
import os
import subprocess
import hashlib
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

SPEC = importlib.util.spec_from_file_location('audit_card_assets', Path(__file__).resolve().parents[1] / 'tools/audit_card_assets.py')
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class AssetAuditTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / 'cards.csv'
        self.card = dict(card_id='1', card_name='Fixture', card_family='Character', rules_text='Printed fixture')
        with self.source.open('w', newline='', encoding='utf-8') as stream:
            writer = csv.DictWriter(stream, fieldnames=self.card)
            writer.writeheader()
            writer.writerow(self.card)
        (self.root / 'fixture.png').write_bytes(b'fixture bytes, not a visually certified image')
        (self.root / 'review.txt').write_text('Fixture evidence only')
        review = dict(path='review.txt', sha256=MODULE.digest(self.root / 'review.txt'), reviewer='Fixture reviewer')
        self.entry = dict(self.card, image_path='fixture.png', image_sha256=MODULE.digest(self.root / 'fixture.png'),
                          rules_sha256=hashlib.sha256(self.card['rules_text'].encode()).hexdigest(),
                          rights_evidence=review.copy(), identity_review=review.copy(), legibility_review=review.copy())
        self.manifest = dict(schema='kudurru_card_asset_manifest_v1', source_sha256=MODULE.digest(self.source), cards=[self.entry])

    @contextlib.contextmanager
    def directory_alias(self, name, target):
        """Exercise real path resolution without Windows symlink privileges."""
        alias = self.root / name
        if os.name == 'nt':
            subprocess.run(['cmd.exe', '/d', '/c', 'mklink', '/J', str(alias), str(target)],
                           check=True, capture_output=True, text=True)
        else:
            alias.symlink_to(target, target_is_directory=True)
        try:
            yield alias
        finally:
            if os.name == 'nt':
                alias.rmdir()  # Remove the junction itself, never its target.
            else:
                alias.unlink()

    def run_audit(self, write=True):
        if write:
            (self.root / 'manifest.json').write_text(json.dumps(self.manifest))
        return MODULE.audit(self.root, 'cards.csv', 'manifest.json')

    def issues(self):
        return self.run_audit()['cards'][0]['issues']

    def test_missing_manifest_is_blocked(self):
        result = self.run_audit(False)
        self.assertEqual(result['issue_counts'], {'missing_card_mapping': 1})

    def test_complete_evidence_never_implies_certification(self):
        result = self.run_audit()
        self.assertEqual(result['evidence_complete_count'], 1)
        self.assertFalse(result['cards'][0]['production_certified'])
        self.assertEqual(result['production_certified_count'], 0)
        self.assertEqual(result['production_status'], 'CLOSED')

    def test_duplicate_mapping(self):
        self.manifest['cards'].append(self.entry.copy())
        self.assertIn('duplicate_card_mapping', self.issues())

    def test_unknown_id(self):
        self.manifest['cards'].append(dict(self.entry, card_id='999'))
        self.assertEqual(self.run_audit()['unknown_card_ids'], ['999'])

    def test_wrong_identity(self):
        self.entry['card_name'] = 'Wrong'
        self.assertIn('source_identity_mismatch_card_name', self.issues())

    def test_stale_source_and_card(self):
        self.manifest['source_sha256'] = '0' * 64
        self.entry['rules_sha256'] = '0' * 64
        self.assertIn('stale_manifest_source', self.issues())
        self.assertIn('stale_card_rules', self.issues())

    def test_hash_mismatch(self):
        self.entry['image_sha256'] = '0' * 64
        self.assertIn('image_hash_mismatch', self.issues())

    def test_unsafe_paths(self):
        for value in ('../fixture.png', '/tmp/fixture.png', 'C:/fixture.png', 'folder\\fixture.png'):
            with self.subTest(value=value):
                self.entry['image_path'] = value
                self.assertIn('missing_or_unsafe_image_path', self.issues())

    def test_malformed_image_path(self):
        self.entry['image_path'] = {'path': 'fixture.png'}
        self.assertIn('missing_or_unsafe_image_path', self.issues())

    def test_symlink_escape(self):
        with tempfile.TemporaryDirectory() as outside:
            target = Path(outside) / 'image.png'
            target.write_bytes(b'outside')
            with self.directory_alias('escape', Path(outside)):
                self.entry['image_path'] = 'escape/image.png'
                self.assertIn('missing_or_unsafe_image_path', self.issues())

    def test_missing_or_tampered_review(self):
        del self.entry['rights_evidence']
        self.entry['identity_review']['sha256'] = '0' * 64
        self.entry['legibility_review']['reviewer'] = ''
        self.assertIn('missing_rights_evidence', self.issues())
        self.assertIn('invalid_identity_review', self.issues())
        self.assertIn('missing_legibility_review_reviewer', self.issues())

    def test_malformed_manifest(self):
        self.manifest = []
        self.assertIn('invalid_manifest_schema', self.issues())

    def test_lexical_image_alias_requires_review(self):
        self.manifest['cards'].append(dict(self.entry, card_id='2', image_path='./fixture.png'))
        self.assertIn('shared_image_requires_identity_review', self.issues())

    def test_internal_symlink_image_alias_requires_review(self):
        with self.directory_alias('alias', self.root):
            self.manifest['cards'].append(dict(self.entry, card_id='2', image_path='alias/fixture.png'))
            self.assertIn('shared_image_requires_identity_review', self.issues())

    def test_shared_image_requires_review(self):
        self.manifest['cards'].append(dict(self.entry, card_id='2'))
        self.assertIn('shared_image_requires_identity_review', self.issues())


if __name__ == '__main__':
    unittest.main()
