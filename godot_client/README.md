# M18 ? Real Two-Window Combat Proof

The authoritative localhost match now has 37 actual socket/UI acceptance checks for attacker/defender resource ownership, double-spend prevention, per-seat private hands and synchronized battles. Both match UIs show the disputed axis and who must respond. Run tools/run_m18_quality_gate.ps1. This is not complete Standard or internet-safe multiplayer. See docs/M18_NETWORK_COMBAT_E2E.md.

# M17 ? Defender-Owned Combat Response

Real battles now require an attacker declaration followed by the defending player selecting their own 0-2 matching resource spend and optional supporter. The attacker can no longer spend the defender resources through a crafted packet. Solo and two-window UI implement the choice. Run tools/run_m17_quality_gate.ps1; see docs/M17_DEFENDER_PRIORITY.md. Full Standard is still blocked.

# M16 ? River Evacuation

The integrated local match executes source-hashed Edict 186: player-selected displacement of one or two units from the same current active Field, with correct Sigil costs and occupied-slot handling. Both solo and localhost two-player interfaces include targeting. Lines/Geasa remain explicitly unresolved, and the 754-card game is not production-certified. See docs/M16_RIVER_EVACUATION.md. Run tools/run_m16_quality_gate.ps1.

# M15 ? Actual Two-Window Localhost Multiplayer UI

The main board now opens a real client for the authoritative Godot localhost server. Two independent game windows can host and join with private hands and server-validated turns. This is same-computer preview, not WAN, TLS, reconnect or 4-seat multiplayer. Run tools/run_m15_quality_gate.ps1. See docs/M15_LOCAL_MULTIPLAYER.md.

# M14 ? Defeated Auto-Restore

Defeated battlefield units now return to their original match owner after two complete intervening rounds, choosing Hand if space otherwise a deterministically shuffled Deck. Source-card conservation, status display and attached-item preview behavior are tested. See docs/M14_DEFEAT_RESTORE.md and run tools/run_m14_quality_gate.ps1. No production capture or permanent rewards are represented as complete.

# M13 ? Explicit End Discards and Income Preview

End now enforces voluntary player-selected discards down to six instead of silently popping hand cards; the game shows each of the three source income conditions and projected Sinew/Sigil/Oath gains before ending. Run tools/run_m13_quality_gate.ps1. This is still a local game candidate, not complete Standard.

# M12 Source-Verified Opponent Priority

Nine Edicts run in local matches. Public Reckoning and Censor Audit now open victim-owned action-choice windows rather than choosing for the target. The local opponent responds out of turn and localhost projections protect private options. See docs/M12_PRIORITY_RULES.md. Run tools/run_m12_quality_gate.ps1. Full 754-card production Standard remains blocked.

# Kudurru Kings M11 ? Seven Source-Verified Live Edicts

Condemnation Seal, Writ of Seizure, and Night Market Clause now run in the local match with target legality, passive suspension and real player-driven draw/discard choices. Night Market supports full action-log replay. Seven of the 15 Edicts are integrated, with remaining source effects blocked. Run tools/run_m11_quality_gate.ps1. Full 754-card Standard is NOT production-certified.

# Kudurru Kings M10 ? Real 754-Card Deck Builder

The main board includes BUILD A DECK (754 REAL CARDS). Construct, validate, save and reload full-source card lists, then select a source-verified candidate deck in PLAY REAL-CARD MATCH (PREVIEW). Unsupported effects are explicitly design-only and never substituted. See docs/M10_DECK_BUILDER_RELEASE_BOUNDARIES.md and run tools/run_m10_quality_gate.ps1. Full 754-card Standard is still not production-ready.

# Kudurru Kings M9 ? Production Systems (NOT FINAL RELEASE)

M9 adds a real Windows x64 export preset, source-pinned jurisdiction and candidate capture validation, a transactional server collection ledger, and a real two-client localhost-only server-authoritative preview. These DO NOT complete the full 754-card game, four-seat WAN multiplayer or art certification. See docs/M9_PRODUCTION_SYSTEMS_STATUS.md and run tools/run_m9_quality_gate.ps1.

# Kudurru Kings M8 - Local Playable Game Preview

**M8:** Five factions, 25 pairing combinations, local Save/Continue with independent replay, four new live source-hashed Edicts and seeded full-match tests. This is a restricted local match candidate, NOT all 754-card Standard or a commercial export. See docs/M8_LOCAL_GAME_REPORT.md; run tools/run_m8_quality_gate.ps1.

# Kudurru Kings — M7 Integrated Local Match and Production Completion Audit

**New executable entry:** On the main Godot board select **PLAY REAL-CARD MATCH (PREVIEW)**. This uses two real 36-card source-validated decks, a deterministic local opponent, the seven-phase turn loop, two Fields, actual resource payments and combat, a provisional Warfield objective and a 10-Mark ending. It has completed 20 deterministic headless match simulations and includes working UI tests. No production rewards or accounts are accessed. **This is not the fully certified 754-card Standard game.**

**Full-game contract:** `docs/FULL_GAME_PRODUCTION_CONTRACT.md`. Machine-readable exhaustive 754-card effect and 20-domain shipping audit: `data/full_game_completion_audit.json`; 121 normalized effect groups: `data/effect_template_groups.json`. Reproducible checks: `tools/run_m7_quality_gate.ps1`.

**M6 canon update:** Printed Guard (1–7), numerical First Strike rating (1–7), and existing Initiative now have consistent source-backed structured representations for all 664 combat-capable cards. Their order is First Strike rating, then Initiative; equal order is simultaneous. This does not add fictional unconditional damage/protection or certify unfinished card effects. See `docs/M6_COMBAT_STAT_AUTHORITY.md`; run `tools/run_m6_quality_gate.ps1`.

**New M5:** Select **TEST REAL COMBAT** on the main board to exercise the real-card Stone/Veil/Authority combat sandbox, Face-off, Downed/Defeated states and optional Resolution capture decline. A separate sealed-bid Oath arbitration engine is covered by headless tests. Conditional resource income now applies when the End phase actually resolves. See `docs/M5_COMBAT_ARBITRATION_STATUS.md`; execute `tools/run_m5_quality_gate.ps1` before further changes. Full Standard remains blocked.

**New M4:** The board includes **VIEW 754 REAL CARDS**, a browsable source-true library and restricted effect bench. Twelve exact effects are executable in a sandbox; 423 adjacent-ally condition descriptors are compiled but the full combat resolver is not. All 754 cards remain production-locked. See `docs/M4_REAL_CARD_EFFECT_GATE.md` and run `tools/run_m4_quality_gate.ps1`.

This is the standalone Godot 4.7.2 **development shell** of Kudurru Kings. It does not yet constitute a playable Standard match. The canonical card records, Shipping Rules, acceptance specs, and economy sources remain at the repository root in their numbered folders. This folder does **not** fork or replace them.

## Launch
Open `godot_client/project.godot` with Godot 4.7.2 Stable. The original four-seat board will appear with seven phases. Click **OPEN ECONOMY LAB** to enter the separate restricted M3 demonstration. Each seat chooses Keep or a free Mulligan before turns begin; then advance to Main and click affordable synthetic Character or Site cards to test deployment and three-resource payments. The 754 real cards remain intentionally non-interactive until certified. Read `docs/M3_TURN_DEPLOYMENT_GATE.md` for exact boundaries.

## Run validation (Windows)
```powershell
& 'E:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'E:\KudurruKings\repo\godot_client' --editor --quit
& 'E:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'E:\KudurruKings\repo\godot_client' --script res://tests/test_runner.gd
python 'E:\KudurruKings\repo\godot_client\tools\audit_master.py'
```

## Source of truth
- **EOE**: original Crosswalk for character-to-faction alignment, working Bible v3.1 for fixed world canon. None is copied into this **public** repository from private source documents.
- **Kudurru Kings**: Shipping Rules v1 for mechanics unless EOE authority contradicts it. Seven phases end with **Resolution** then **End**; capture is optional within Resolution.
- Pure and mixed decks are both legal, subject to card locks; **pure-faction benefits are not yet defined or active**.
- An approved deterministic deployment-cost baseline now assigns a positive cost to all 754 cards and normalizes Oath upkeep. This is balanced source data, NOT effect certification or release permission. See `docs/COST_BALANCE_DOCTRINE_V1.md`.
- Capture attempts remain pending adjudication; declining eligible capture results in Defeated. Permanent collection copies and Marks are not emitted by this preview.
- Four-seat view is a **developer preview**. Multiplayer, AI, combat, economy, rule-complete capture, and scenario engine are future milestones.

## Status
M1/M2 headless runtime verified on ManicsPC with Godot 4.7.2: 46/46 regression checks passed, editor import and scene start exit code 0. Interactive visual review remains pending. M2 read-only catalog indexing has begun; gameplay is not released. The `main` branch must not be changed without review.

## M1 exit gate
- [x] Godot 4.7.2 headless editor import, exit code 0
- [x] Headless GDScript regression suite: 38/38
- [x] Headless scene startup, exit code 0
- [ ] Interactive Windows visual and phase-button review
- [x] Canonical repository source remains unchanged
- [x] Public branch contains no private EOE working copies
- [x] Uncertified master not loaded into live match
