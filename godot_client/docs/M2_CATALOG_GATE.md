# M2 — Uncertified Catalog Import Gate (2026-10-20)

## Runtime status
- Godot 4.7.2 editor import: PASS (exit code 0)
- Godot headless scene runtime: PASS (exit code 0)
- GDScript regression: PASS (38/38; exit code 0)
- Python compilation: PASS
- Card database: 754 inherited records indexed, 0 certified as playable
- Card database authority: repository root `02_Data/Kudurru_Kings_Gameplay_Master_v1.csv`; preview index is a regenerable derivative

## Data contracts
- Card IDs are the unique immutable runtime keys. Source slug collisions are preserved as findings, not silently renamed.
- Two source slug collisions: `word-eater` (card IDs 386 and 540), `ink-tongue` (418 and 642).
- Four known EOE verified faction conflicts corrected **for display only**: Drowned Archivist, Ash Prophetess, Chain Marshal, Taxlord Balash.
- Only explicit EOE-verified assignments are overlaid; all other inherited faction assignments remain marked provisional.
- Mercy Docket exists as an Edict in the master, but is a named figure in EOE; must undergo identity-family adjudication before auto-reconciliation.
- All 754 card records currently declare zero for all three deployment cost fields; no costs are certified.
- Full availability of the original EOE Crosswalk for comprehensive automated validation is pending private-source integration; private EOE documents are not copied to the public repo.

## Security and safety
- Generated catalog has `playable=false` for all cards and `playable_count=0`.
- Catalog reader rejects duplicate immutable IDs, record-count mismatch, and unexpected playable records.
- Game UI reports its restricted catalog status.
- No purchase, reward, save, inventory mutation, or multiplayer action is enabled.

## Regeneration and tests
Run from repository root:
```powershell
python godot_client/tools/build_catalog.py
python godot_client/tools/audit_master.py
& 'E:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'E:\KudurruKings\repo\godot_client' --editor --quit
& 'E:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'E:\KudurruKings\repo\godot_client' --script res://tests/test_runner.gd
& 'E:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'E:\KudurruKings\repo\godot_client' --quit-after 8
```

## Remaining M2 gates
- Full EOE Crosswalk reconciliation against every card
- Cost values approved and balanced; no unreviewed 0-cost defaults released
- Card-specific faction lock resolver, including legal hybrid-faction exception semantics
- Gameplay-schema enforcement and card-effect compiler
- Legal starter decks with the necessary abilities and costs; still not a playable match
- Interactive visual review on workstation (headless success is not visual certification)
