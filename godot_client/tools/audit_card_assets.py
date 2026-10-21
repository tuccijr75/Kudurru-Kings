#!/usr/bin/env python3
"""Fail-closed artwork evidence inventory. File integrity is not rights/visual certification."""
from __future__ import annotations
import argparse
import csv
import hashlib
import json
from collections import Counter
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[2]
SOURCE = '02_Data/Kudurru_Kings_Gameplay_Master_v1.csv'
MANIFEST = 'godot_client/data/card_asset_manifest_v1.json'
OUT = 'godot_client/data/card_asset_audit_v1.json'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def local_file(root, value):
    if not isinstance(value, str) or not value or '\\' in value:
        return None
    path = PurePosixPath(value)
    if path.is_absolute() or '..' in path.parts or ':' in value:
        return None
    resolved = (root / value).resolve()
    if not resolved.is_relative_to(root.resolve()) or not resolved.is_file():
        return None
    return resolved


def audit(root=ROOT, source=SOURCE, manifest=MANIFEST):
    root = Path(root)
    source_path = root / source
    with source_path.open(encoding='utf-8-sig', newline='') as stream:
        cards = list(csv.DictReader(stream))
    ids = [card['card_id'] for card in cards]
    if len(ids) != len(set(ids)) or any(not x for x in ids):
        raise ValueError('Source card IDs must be nonempty and unique')
    source_hash = digest(source_path)
    manifest_path = root / manifest
    data = json.loads(manifest_path.read_text(encoding='utf-8')) if manifest_path.is_file() else None
    manifest_errors = []
    entries = []
    if data is not None:
        if not isinstance(data, dict) or data.get('schema') != 'kudurru_card_asset_manifest_v1':
            manifest_errors.append('invalid_manifest_schema')
        elif data.get('source_sha256') != source_hash:
            manifest_errors.append('stale_manifest_source')
        if isinstance(data, dict) and isinstance(data.get('cards'), list):
            entries = data['cards']
        else:
            manifest_errors.append('invalid_manifest_cards')
    by_id = {}
    for entry in entries:
        if not isinstance(entry, dict) or not isinstance(entry.get('card_id'), str):
            manifest_errors.append('invalid_mapping_record')
            continue
        by_id.setdefault(entry['card_id'], []).append(entry)
    unknown = sorted(set(by_id) - set(ids))
    paths = Counter(
        image for entry in entries if isinstance(entry, dict)
        if (image := local_file(root, entry.get('image_path'))) is not None
    )
    records = []
    for card in cards:
        card_id = card['card_id']
        matches = by_id.get(card_id, [])
        issues = list(sorted(set(manifest_errors)))
        file_hash = None
        if not matches:
            issues.append('missing_card_mapping')
        elif len(matches) != 1:
            issues.append('duplicate_card_mapping')
        else:
            entry = matches[0]
            for field in ('card_name', 'card_family'):
                if entry.get(field) != card[field]:
                    issues.append('source_identity_mismatch_' + field)
            expected_rules = hashlib.sha256(card['rules_text'].encode('utf-8')).hexdigest()
            if entry.get('rules_sha256') != expected_rules:
                issues.append('stale_card_rules')
            image = local_file(root, entry.get('image_path'))
            if image is None:
                issues.append('missing_or_unsafe_image_path')
            else:
                if image.suffix.lower() not in ('.png', '.jpg', '.jpeg', '.webp', '.svg'):
                    issues.append('unsupported_image_extension')
                file_hash = digest(image)
                if entry.get('image_sha256') != file_hash:
                    issues.append('image_hash_mismatch')
            if image is not None and paths.get(image, 0) > 1:
                issues.append('shared_image_requires_identity_review')
            # References must be local evidence files pinned to their exact bytes.
            # Their legal meaning and visual correctness still require human review.
            for field in ('rights_evidence', 'identity_review', 'legibility_review'):
                review = entry.get(field)
                if not isinstance(review, dict):
                    issues.append('missing_' + field)
                    continue
                evidence = local_file(root, review.get('path'))
                if evidence is None or review.get('sha256') != digest(evidence):
                    issues.append('invalid_' + field)
                if not isinstance(review.get('reviewer'), str) or not review['reviewer'].strip():
                    issues.append('missing_' + field + '_reviewer')
        records.append({'card_id': card_id, 'card_name': card['card_name'], 'family': card['card_family'],
                        'issues': sorted(set(issues)), 'image_sha256': file_hash,
                        'evidence_complete': not issues, 'production_certified': False})
    counts = Counter(issue for card in records for issue in card['issues'])
    return {'schema': 'kudurru_card_asset_audit_v1', 'source_sha256': source_hash,
            'manifest_present': data is not None, 'manifest_errors': sorted(set(manifest_errors)),
            'unknown_card_ids': unknown, 'source_card_count': len(cards),
            'evidence_complete_count': sum(card['evidence_complete'] for card in records),
            'issue_counts': dict(sorted(counts.items())), 'production_certified_count': 0,
            'production_status': 'CLOSED',
            'boundary': 'Checks evidence presence and integrity only; does not certify rights, image identity, legibility or human acceptance.',
            'cards': records}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--manifest', default=MANIFEST)
    parser.add_argument('--output', default=OUT)
    parser.add_argument('--check', action='store_true', help='Fail when mappings/evidence are incomplete; default inventories blockers successfully.')
    args = parser.parse_args()
    report = audit(manifest=args.manifest)
    destination = ROOT / args.output
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(report, indent=2, sort_keys=True) + '\n', encoding='utf-8')
    print(f"Card artwork evidence: {report['evidence_complete_count']}/{report['source_card_count']}; production CLOSED")
    return int(args.check and (report['evidence_complete_count'] != report['source_card_count'] or bool(report['unknown_card_ids']) or bool(report['manifest_errors'])))


if __name__ == '__main__':
    raise SystemExit(main())
