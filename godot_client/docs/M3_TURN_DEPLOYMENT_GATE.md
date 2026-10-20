# M3 — Deterministic Economy-Lab and Turn Foundation

## Status (2026-10-20)
Source implemented in isolated branch `build/m3-turn-deployment-20261020`.
This is NOT a production Kudurru Kings match, multiplayer service or real-card rules engine.

## Scope implemented
1. Production-faithful Standard **structure**: 36-card deck, initial hand 6, one optional full free mulligan **before** turn 1 for every seat, refill hand to 6 on entering Draw.
2. Two to four simulated seats; deterministic Fisher-Yates shuffle from explicitly provided seed; event revision ordering; stale-action rejection.
3. Fully separated synthetically generated `DEV_ECON_*` fixture cards, validated against a trusted fixture factory. Synthetic identities are never inserted into the canonical 754-card master.
4. Per-seat Deck/Hand/Field/Discard state, deterministic source-owned reducer and action event trail.
5. Legal action checks: seat ownership, current revision, card-in-hand proof, phase (only Main for lab deployment), allowed card family, exact three-resource payment, no negative balances, immutable rejected/successful input state.
6. Only **Character** and **Site** fixtures may be deployed (without their normal game effects). This is solely an economy/board-presence test; every other family is blocked until effects and lifecycle resolver certification.
7. Deterministic End income via the previous phase controller. Synthetic deployed Characters count as ready; synthetic Sites enable Sigil. No imagined objective state or Oath rewards.
8. Four-seat interactive Godot lab scene with all-player pre-match Keep/Mulligan decisions and clickable affordable cards. Entry via **OPEN ECONOMY LAB** button on the main Godot board.
9. Public-summary adapter reports counts and deployed card IDs but never sends hidden hands, decks, or random seed. It is NOT a network protocol and multiplayer remains absent.

## Authority and boundaries
- EOE Bible v3.1 and the original EOE Crosswalk remain controlling on shared lore and faction identities. No EOE document is published to the public GitHub repository.
- Kudurru Kings Shipping Rules v1 determines the seven phases, turn ordering and deployment timing; optional capture stays in Resolution.
- The approved cost-balance development data is preserved and regression checked, but the **754 inherited card records remain playable=false** until effect, faction and rules text certification.
- No card-effect simulation, combat, opponent AI, capture result, production inventory, rewards, currency payouts or scoring.
- The existing main board remains a development shell; the new laboratory scene is a separate explicitly labelled test runtime.
- Deck fixtures are generated with approved family composition counts and no pure-faction bonus. **This does not certify real decks.**
- Boss Upkeep and card-specific actions remain unimplemented in the test reducer; Boss/Edict/Pet/Relic/Name/Host Sigil play is disallowed.

## Source files
- `scripts/lab_fixtures.gd`: isolated synthetic Standard deck fixture factory
- `scripts/dev_match.gd`: deterministic pregame, mulligan, draw, deployment, turn and event reducer
- `scripts/economy_lab_ui.gd` and `scenes/economy_lab.tscn`: selectable local demonstration
- `scripts/cost_rules.gd`, `scripts/game_rules.gd`, `scripts/deck_validator.gd`: previously validated rules helpers
- `tests/test_dev_match.gd`: 101+ contract checks
- `tests/test_economy_lab_ui.gd`: 15 headless user-action checks
- `tools/run_m3_quality_gate.ps1`: tests all three-resource, source-integrity and Godot gates

## M3 exit criteria
- [x] No touching `main`; implementation on isolated `build/m3-turn-deployment-20261020` branch
- [x] 36-card conservation through mulligan, deployment and Draw
- [x] Every seat independently decides to Keep or Mulligan before Upkeep
- [x] Rejected actions cannot spend resources or mutate state
- [x] Development fixture IDs never overlap real card IDs
- [x] Event log does not publish hidden cards or seed
- [x] Godot headless lab initialization and UI dispatch smoke
- [ ] Manual visual inspection and input-device usability review on ManicsPC
- [ ] Full Standard gameplay legality, 10 Mark victories and complete opponent AI (separate later milestones)

## Next
M4 is the source-owned **combat and lifecycle resolver**: attacker/defender/axis legality, supporter and combat resource-spend limits, same-axis Face-off, wound/downed/bound/defeated transitions, Boss Trial progress. These must be implemented from Shipping Rules + canonical schema + existing resolver test suite, not inferred from fixture behavior.
