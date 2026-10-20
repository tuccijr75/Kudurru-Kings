# Kudurru Kings — M6 Guard, First Strike and Initiative Authority

**Decision owner:** approved developer discretion (2026-10-20).
**Branch:** `build/m6-combat-stat-reconciliation-20261020`
**Status:** canonical data reconciliation; complete gameplay effect semantics remain a distinct release gate.

## Canon decision and its gameplay rationale

**Printed card stats are authoritative when they contradict migrated empty/default structured combat columns.** The first 664 combat-capable records (500 Characters, 164 Bosses) uniformly have printed Guard 1–7 and First Strike 1–7; all had `guard=0` and `first_strike=False` in the migrated 136-column master. All 664 printed Initiative values already matched structured Initiative. The 90 noncombat cards properly retain Guard 0, First Strike false, Initiative 0.

**Guard** is a numeric 1–7 defensive/protector rating. It is not automatically added in full to Stone/Veil/Authority contests because that would grant enormous unconditional defensive bonuses and distort the resource and Supporter economy. Guard is reserved for source-legal protector/defensive modifiers when their triggers and caps are fully established.

**First Strike** is an ordered **numeric rating 1–7**, not merely a presence flag. The existing boolean `first_strike` is true when positive, while the complete 1–7 value is retained in `first_strike_rating` on the derived real-card runtime source. All 664 combatants therefore have a positive First Strike rating: the boolean alone cannot convey their differences.

**Initiative** is the already matching printed number (3, 5, 9, 12 or 13) and determines combat sequencing after First Strike ties. Priority for two certified combatants is:
1. Higher First Strike rating acts earlier;
2. if equal, higher Initiative acts earlier;
3. if still equal, action order is **simultaneous/unresolved**, not an invented tie-break or attack victory.

First Strike does not grant a free wound or automatic victory. The pure `combat_stat_order.gd` evaluator reports sequencing only, not damage, protection or any guaranteed attack resolution. This avoids the common design failure of treating Guard 7 as unconditional +7 and First Strike as automatic first damage.

## Exact migration

- Source of truth: `02_Data/Kudurru_Kings_Gameplay_Master_v1.csv`.
- Update **only** the `guard` and `first_strike` columns of all 664 combat-capable records. No other canonical field is changed; the approved cost balance, abilities, factions, EOE continuity, identity, rarity and 36-card constraints remain intact.
- `godot_client/tools/reconcile_combat_stats.py`: explicit preimage SHA, source-text regex, exact Initiative validation, 664-row membership checks, field-by-field identity/diff checks, all-card source hash, idempotent replay, fail-closed partial edits.
- `godot_client/data/m6_guard_first_strike_migration.json`: source and printed-value provenance, full numeric First Strike ratings, 664 old and new Guard/boolean values, rules SHA-256s, original master SHA. This is reversible from Git and snapshot.
- `godot_client/data/printed_combat_transcription_v1.json`: regenerated with **0 printed/structured discrepancies**, still contains original numeric ratings and printed tiers.
- `godot_client/data/real_cards_v1.json`: regenerated typed fields `guard`, `first_strike`, `first_strike_rating`, `initiative`, `combat_stat_provenance`. All 754 real cards remain `production_playable=false`.
- `godot_client/scripts/combat_stat_order.gd`: pure source-verified sequencing comparator; does not change M5 source-limited combat damage, Face-off, raids or capture outcomes.
- `godot_client/scripts/real_catalog_ui.gd`: shows reconciled three combat ratings next to the original card text.

## Design constraints

- No source-specific Guard protector triggers or First Strike preemptive retaliation are invented by this data repair.
- Positive First Strike does not imply the printed rating is a +N combat-axis stat or a raw +N damage bonus.
- The exact effect of Guard on target restriction, protection/mitigation, and retaliation; and the precise First Strike window within full multiplayer combat need certified implementation after state/trigger reconciliation.
- EOE Canon/Crosswalk remains faction authority; card assignment conflicts are untouched.
- 742 additional card effects, target/trigger data, Boss aura/retaliation, scenarios, field/Line/Geas actions, capture success, AI/networking, rendering and visual review remain unresolved. The release-blocker audit names remaining categories and does not label Standard release-ready.

## Validation and reproducibility

Run `godot_client/tools/run_m6_quality_gate.ps1` on ManicsPC to:
1. Verify the 664-row migration against immutable pinned source and original Git content;
2. Rebuild all three-source resource-cost, EOE preview, printed combat and real-card JSON outputs;
3. Prove exactly 664 Guard and 664 First Strike column changes against the M5 master and no other modifications;
4. Execute 34 Python source and migration integrity checks and the established Godot regression suite plus M6 combat sequencing tests;
5. Verify real-card scenes still run headlessly without reported script errors;
6. Check Git whitespace integrity.

**M6 exit:** data authority corrected; all source tests green; full-game release gate remains closed until complete gameplay semantics are implemented and exercised by end-to-end match replays.
