"""Source-owned completion ledger. Candidate evidence never promotes certification."""
import csv
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'godot_client/data/final_completion_ledger.json'

def build():
    master = ROOT / '02_Data/Kudurru_Kings_Gameplay_Master_v1.csv'
    rows = list(csv.DictReader(master.open(encoding='utf-8-sig', newline='')))
    audit = json.loads((ROOT / 'godot_client/data/full_game_completion_audit.json').read_text())
    by_id = {r['card_id']: r for r in rows}
    assert len(by_id) == len(rows) == len(audit['card_manifest']) == 754
    cards = []
    for card in audit['card_manifest']:
        row = by_id[card['card_id']]
        assert row['card_name'] == card['card_name'] and row['card_family'] == card['family']
        cards.append({**card,
            'rules_sha256': hashlib.sha256(row['rules_text'].replace('\r\n', '\n').encode()).hexdigest(),
            'source_path': '02_Data/Kudurru_Kings_Gameplay_Master_v1.csv',
            'source_verified': True,
            'full_effect_implemented': False,
            'full_effect_unit_tested': False,
            'full_effect_integration_tested': False,
            'visually_verified': False,
            'release_certified': False,
            'done_when': 'All printed effects typed, provenance verified, legal positive/negative/replay tests pass, art and UI certified',
        })
    systems = []
    for name, state in audit['production_game_gates'].items():
        systems.append({'id': name, **state,
            'release_certified': False,
            'source': 'godot_client/tools/audit_full_game.py:DOMAINS',
            'candidate_status_only': True})
    return {'schema': 'kudurru_final_completion_ledger_v1',
        'baseline_commit': 'caf153dcf400b0f461de6b3c9a188e84e4b89022',
        'source_card_count': 754, 'production_certified_card_count': 0,
        'effect_template_count': audit['unique_effect_templates'],
        'live_candidate_edict_count': len(audit['source_verified_live_edicts']),
        'system_count': len(systems), 'production_status': 'CLOSED',
        'coverage_contract': 'Full-effect booleans concern complete production behavior; partial candidate evidence is effect_status.',
        'cards': cards, 'systems': systems,
        'completion_criteria': {
            'boss_trials_capture': '164 source Bosses; 3 distinct axes; optional Resolution Bind/Capture; no Downed awards; owner-safe transaction',
            'jurisdiction_sites_raids': 'All 15 Sites and all source Lines/Geasa integrated with authoritative traversal and 2-Mark legal raids',
            'names_arbitration': 'All 15 Names; hidden owner bids; Face-off ties; Seize/Suppress/Corrupt; Heat and visibility',
            'player_counts': 'Solo and 2/3/4-seat real matches, four-seat presentation, account auth, WAN security and reconnect',
            'collections': 'Verified success only; authoritative idempotent grants; concurrency/rollback/replay tests; Ultra prerequisites',
            'art': '754 verified card-to-art mappings, rights/provenance, family renders and human visual certification',
            'distribution': 'Full Standard gates green; Windows native export, independent extracted launch, signing/install/playtest certification',
        }}

if __name__ == '__main__':
    data = build()
    OUT.write_text(json.dumps(data, ensure_ascii=False, sort_keys=True, indent=2)+'\n', encoding='utf-8')
    print('FINAL_COMPLETION_LEDGER cards=754 templates=121 systems=23 certified=0 status=CLOSED')
