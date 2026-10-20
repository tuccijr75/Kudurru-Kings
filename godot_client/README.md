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
- No card gains a fabricated effect, deployment cost, or rarity reward. The repo master currently has 754 records with triple-zero deployment costs; no entries are promoted to a playable catalog.
- Capture attempts remain pending adjudication; declining eligible capture results in Defeated. Permanent collection copies and Marks are not emitted by this preview.
- Four-seat view is a **developer preview**. Multiplayer, AI, combat, economy, rule-complete capture, and scenario engine are future milestones.

## Status
M1 source files committed to `build/godot-m1-20261020`. Until Godot headless tests run successfully, this branch is **NOT** certified M1. The `main` branch must not be changed without review.

## M1 exit gate
- [ ] Godot 4.7.2 editor import with zero parse/load errors
- [ ] Headless GDScript regression suite passes
- [ ] Board opens on Windows and Next Phase cycles 7 phases and 4 seats
- [x] Canonical repository source remains unchanged
- [x] Public branch contains no private EOE working copies
- [x] Uncertified master not loaded into live match
