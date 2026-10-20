# Kudurru Kings — Godot M1 (development branch)

This is the standalone Godot 4.7.2 **development shell** of Kudurru Kings. It does not yet constitute a playable Standard match. The canonical card records, Shipping Rules, acceptance specs, and economy sources remain at the repository root in their numbered folders. This folder does **not** fork or replace them.

## Launch
Open `godot_client/project.godot` with Godot 4.7.2 Stable. The four-seat board will appear with seven phase controls. Click **NEXT PHASE** to advance a deterministic preview state. All card slots are intentionally non-interactive while the 754-card master awaits certification.

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
