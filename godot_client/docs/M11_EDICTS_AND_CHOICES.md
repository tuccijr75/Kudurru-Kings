# Kudurru Kings M11 ? Integrated Source-Verified Edicts and Choice Windows

**Branch:** build/m11-effect-runtime-20261020.
**Status:** Local match candidate; full 754-card Standard remains blocked.
**Engine:** Godot 4.7.2, source-owned deterministic action reducer.

## Live Edicts in the seven-phase two-seat local match

Seven of the fifteen Edicts now execute from the original text with verified
source hashes. IDs 181 Sun-Script Overload, 188 Mercy Docket,
191 Festival Truce and 193 Convoy Priority remain intact from M8.
Three additions:

- **184 Condemnation Seal**: during Edicts, choose an actual Downed,
  undefeated unit (including an opposing unit); mark it ineligible to
  be saved or readied during the current round. The local game has
  no completed resurrection system yet, so this status does not certify
  the entire printed effect ecosystem.
- **185 Writ of Seizure**: choose a real Site or Relic instance, with owner
  and host identity verified. Exhaust until the *target controller's* next
  Upkeep. Mirror Archive cannot be activated; Bitumen Furnace and
  Bitumen Harness provide no combat bonus while exhausted. Wake at
  the controller's next Upkeep. The Source ID is not fabricated.
- **187 Night Market Clause**: during End, pay the original cost, draw
  up to two actual deck cards, then use a separate explicit action
  to discard one chosen card and raise Heat by one. The mandatory
  choice blocks End advancement until completed. No arbitrary
  auto-selection of a human player's discard. The local AI resolves
  its own choice deterministically. Action log, source conservation,
  physical match save/replay and UI are all exercised.

The deterministic local opponent now deploys source-verified Pets and Relics
onto legal friendly units when affordable. This prevents support items
from remaining human-only actions.

Each default local candidate deck contains 23 real source-verified
Characters, 2 Sites, 4 Pets/Relics, and 7 Edicts: exactly 36 legal
source IDs with original costs and copy/rarity restrictions. The
754-card deck builder remains unchanged: unsupported cards may be
designed into legal-composition decks, but cannot enter the live
candidate until their effects have been implemented.

## Verification

Reproducible full gate: tools/run_m11_quality_gate.ps1.
Includes all preceding engine, replay, collection ledger, localhost
server, battle and deck-builder tests, and:
- test_more_live_edicts.gd (30 targeted checks)
- test_night_market_clause.gd (31 sequencing/replay checks)
- test_night_market_ui.gd (14 UI/replay checks)
- test_opponent_support.gd (34 actual Pet/Relic AI action checks)

M11 remains source-limited. Card metadata and EOE Crosswalk
conflicts are not overridden; the printed legacy Wind/Eye/supply/recoil
systems have not been silently reassigned. The full-game audit
records 754 source cards, 121 normalized effect groups, zero
production-certified cards, and 6 PASS / 11 IN_PROGRESS / 6 BLOCKED
shipping domains. A successful Windows export does not change those
release-blocker counts.

The full four-seat multiplayer, Boss law, capture success canon,
all jurisdiction and raids, full collection progression and
per-card artwork are still unresolved. Main remains unchanged.
