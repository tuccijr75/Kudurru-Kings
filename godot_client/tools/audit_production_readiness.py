#!/usr/bin/env python3
"""Read-only release blocker inventory. Candidate PASS is never certification.

This tool checks source/ledger consistency and reports certification declarations.
It cannot approve canon, authenticate human acceptance, or authorize a release.
--require-open fails while production remains closed (suitable for release jobs).
"""
from __future__ import annotations
import argparse
import csv
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MASTER = '02_Data/Kudurru_Kings_Gameplay_Master_v1.csv'
CARD_CHECKS = ('source_verified', 'full_effect_implemented', 'full_effect_unit_tested',
               'full_effect_integration_tested', 'visually_verified', 'release_certified',
               'production_certified')
GATES = {
    'G1_cards': ('canon_factions', 'card_effects', 'reusable_effect_runtime', 'combat_stat_authority', 'deployment_costs', 'source_card_registry'),
    'G2_boss_capture_scoring': ('full_combat', 'boss_trials_capture', 'scenarios'),
    'G3_jurisdiction': ('field_line_geasa', 'site_raids', 'arbitration', 'heat'),
    'G4_player_counts_security': ('turn_setup_decks', 'solo_ai', 'multiplayer', 'security_privacy', 'local_save_and_replay', 'local_faction_selection', 'source_deck_builder'),
    'G5_collections': ('collection_rewards',),
    'G6_art_ui': ('visual_assets',),
    'G7_distribution_playtests': ('distribution',),
}


def read(root, name):
    return json.loads((root / 'godot_client/data' / name).read_text(encoding='utf-8'))


def asset_evidence(document, source_hash, source_ids):
    if document is None:
        return {'status': 'NOT_ESTABLISHED', 'evidence_complete_count': 0}
    cards = document['cards']
    if (document.get('schema') != 'kudurru_card_asset_audit_v1'
            or document.get('source_sha256') != source_hash
            or document.get('source_card_count') != 754
            or len(cards) != 754
            or {card['card_id'] for card in cards} != source_ids):
        raise ValueError('Stale or incomplete art evidence provenance')
    count = document['evidence_complete_count']
    if type(count) is not int or not 0 <= count <= 754:
        raise ValueError('Invalid art evidence count')
    if any(type(card.get('evidence_complete')) is not bool for card in cards):
        raise ValueError('Art evidence requires explicit booleans')
    if count != sum(card['evidence_complete'] for card in cards):
        raise ValueError('Art evidence count disagrees with individual records')
    return {'status': 'DECLARED_EVIDENCE_ONLY', 'evidence_complete_count': count,
            'certification': 'NOT_ESTABLISHED_BY_ASSET_MAPPING_AUDIT'}


def inventory(root=ROOT):
    raw = (root / MASTER).read_bytes()
    with (root / MASTER).open(encoding='utf-8-sig', newline='') as stream:
        rows = list(csv.DictReader(stream))
    source = {row['card_id']: row for row in rows}
    audit = read(root, 'full_game_completion_audit.json')
    ledger = read(root, 'final_completion_ledger.json')
    if len(rows) != 754 or len(source) != 754:
        raise ValueError('Expected 754 unique authoritative source cards')
    if audit['master_sha256'] != hashlib.sha256(raw).hexdigest():
        raise ValueError('Stale master provenance in completion audit')
    if audit['source_card_count'] != 754 or ledger['source_card_count'] != 754:
        raise ValueError('Inconsistent source card totals')
    cards = ledger['cards']
    ids = [card['card_id'] for card in cards]
    if len(ids) != 754 or set(ids) != set(source):
        raise ValueError('Completion ledger omits, duplicates or invents card identities')
    manifest = audit['card_manifest']
    if len(manifest) != 754 or {card['card_id'] for card in manifest} != set(source):
        raise ValueError('Audit manifest does not partition authoritative cards')
    declarations = {key: 0 for key in CARD_CHECKS}
    for card in cards:
        row = source[card['card_id']]
        expected_hash = hashlib.sha256(row['rules_text'].replace('\r\n', '\n').encode()).hexdigest()
        if (card['card_name'], card['family'], card['rules_sha256'], card['source_path']) != (
                row['card_name'], row['card_family'], expected_hash, MASTER):
            raise ValueError('Stale or misidentified card: ' + card['card_id'])
        for key in CARD_CHECKS:
            if type(card.get(key)) is not bool:
                raise ValueError('Certification must be an explicit boolean: ' + key)
            declarations[key] += card[key]
        if card['production_certified'] and not all(card[key] for key in CARD_CHECKS):
            raise ValueError('Card certification lacks required stages: ' + card['card_id'])
    if ledger['production_certified_card_count'] != declarations['production_certified']:
        raise ValueError('Certified card total disagrees with individual records')
    systems = {system['id']: system for system in ledger['systems']}
    required = {domain for domains in GATES.values() for domain in domains}
    if len(systems) != len(ledger['systems']) or set(systems) != required or ledger['system_count'] != len(systems):
        raise ValueError('Missing, duplicated or unknown production domain')
    for name, system in systems.items():
        if type(system.get('release_certified')) is not bool:
            raise ValueError('Missing explicit system certification: ' + name)
        if system.get('candidate_status_only') is not True:
            raise ValueError('Unsupported system certification contract: ' + name)
        if system['status'] != audit['production_game_gates'][name]['status']:
            raise ValueError('Stale system status: ' + name)
    # The current ledger holds candidate declarations, not signed independent
    # certification evidence. No combination of PASS strings or edited booleans
    # can turn this inventory into release authorization.
    if ledger['production_status'] != 'CLOSED' or audit['full_standard_releasable'] is not False:
        raise ValueError('Production promotion requires a separately approved evidence contract')
    asset_path = root / 'godot_client/data/card_asset_audit_v1.json'
    art = asset_evidence(read(root, asset_path.name) if asset_path.exists() else None,
                         hashlib.sha256(raw).hexdigest(), set(source))
    gates = {gate: {
        'status': 'CLOSED',
        'required_domains': list(domains),
        'candidate_pass_domains': [name for name in domains if systems[name]['status'] == 'PASS'],
        'uncertified_domains': [name for name in domains if not systems[name]['release_certified']],
        'independent_certification_evidence': 'NOT_ESTABLISHED_BY_CURRENT_LEDGER',
    } for gate, domains in GATES.items()}
    return {
        'schema': 'kudurru_production_readiness_inventory_v1',
        'master_sha256': hashlib.sha256(raw).hexdigest(),
        'source_cards': 754, 'card_stage_declarations': declarations,
        'production_status': 'CLOSED', 'release_authorized': False,
        'gates': gates, 'art_evidence': art,
        'coverage_contract': 'Counts are ledger declarations. Candidate PASS, headless tests and historical Windows smoke evidence do not certify full Standard or authorize production.',
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--require-open', action='store_true')
    args = parser.parse_args()
    try:
        result = inventory()
    except (ValueError, KeyError, TypeError, OSError) as error:
        parser.exit(2, 'PRODUCTION_INVENTORY_INVALID: ' + str(error) + '\n')
    print(json.dumps(result, sort_keys=True, indent=2))
    return 1 if args.require_open else 0


if __name__ == '__main__':
    raise SystemExit(main())
