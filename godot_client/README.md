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
