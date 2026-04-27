# Kudurru Kings — Migration Manifest v1

## Purpose
This package is the restructured replacement for `migrate.zip`.

It preserves all useful information from the legacy source pack, removes deprecated gameplay-authority fields, and rehomes the project into the new canonical stack:
- Shipping Rules v1
- Canonical Gameplay Schema v1
- CSV Migration Map v1
- Acceptance Test Suite v1
- Resolver / State Machine Spec v1
- Canonical Gameplay Master Template v1

## What was preserved
- All legacy card rows: **754**
- All legacy production/export rows: **754**
- Legacy audit, shipping gaps, economy, faction, and mechanics tracking docs
- Legacy art/render/package metadata
- Legacy section/unit-rank/race/tier/descriptor metadata

## What was removed from gameplay authority
The following deprecated gameplay-authority columns were removed from the canonical gameplay master:
- `wind`
- `eye`
- `weight`

The legacy combat stat `oath` was renamed to canonical `authority` in gameplay-authority files.

## Important migration decisions
- Old rarity ladder was normalized to the canonical ladder using `05_Tracking/Kudurru_Kings_Rarity_Translation_v1.csv`.
- `master.csv` and `production_master.csv` were replaced by:
  - `02_Data/Kudurru_Kings_Gameplay_Master_v1.csv`
  - `06_Exports/Kudurru_Kings_Master_Export_v1.csv`
  - `06_Exports/Kudurru_Kings_Production_Export_v1.csv`
  - plus preservation sidecars for content, visual, and production metadata.
- Because `migrate.zip` did not include an explicit per-card faction mapping, `owner_faction` remains unresolved in the canonical gameplay master and is tracked in `02_Data/Kudurru_Kings_Unresolved_Backfills_v1.csv` and `02_Data/Kudurru_Kings_Validation_Errors_v1.csv`.

## File map: old -> new
- `master.csv` -> `02_Data/Kudurru_Kings_Gameplay_Master_v1.csv` + `06_Exports/Kudurru_Kings_Master_Export_v1.csv`
- `production_master.csv` -> `06_Exports/Kudurru_Kings_Production_Export_v1.csv` + `02_Data/Kudurru_Kings_Production_Metadata_v1.csv`
- `00_Audit_Report.md` -> `05_Tracking/Kudurru_Kings_Legacy_Audit_Report_v1_0.md`
- `Shipping_Gaps.md` -> `05_Tracking/Kudurru_Kings_Legacy_Shipping_Gaps_v1_0.md`
- `Final_Engineering_and_Data_Doctrine.md` -> replaced by:
  - `01_Rules/Kudurru_Kings_Shipping_Rules_v1.md`
  - `02_Data/Kudurru_Kings_Canonical_Gameplay_Schema_v1.md`
  - `03_Implementation/Kudurru_Kings_Resolver_State_Machine_v1.md`
- `Kudurru_Kings_Economy_and_Rewards_Doctrine_v1_0.md` -> `04_Product/Kudurru_Kings_Economy_and_Rewards_Doctrine_v1_0_Migrated.md`
- `Kudurru_Kings_Economy_Implementation_Spec_v1_0.md` -> `04_Product/Kudurru_Kings_Economy_Implementation_Spec_v1_0_Migrated.md`
- `Kudurru_Kings_Final_Faction_Roster_Assignments_v1_0.md` -> `04_Product/Kudurru_Kings_Faction_Roster_Assignments_v1_0_Migrated.md`
- `Kudurru_Kings_Mechanics_Alignment_Matrix.csv` -> `05_Tracking/Kudurru_Kings_Legacy_Mechanics_Alignment_Matrix_v1_0.csv`

## Package structure
- `01_Rules/` — live gameplay authority
- `02_Data/` — canonical gameplay data + metadata sidecars
- `03_Implementation/` — migration, tests, runtime sequencing
- `04_Product/` — retained economy/faction product docs
- `05_Tracking/` — retained legacy tracking and translation aids
- `06_Exports/` — regenerated/clean export-oriented files

## Immediate next execution step
1. Backfill `owner_faction`
2. Review cost fields
3. Run validation gates
4. Run Acceptance Test Suite v1 against migrated data/runtime


## v2 continuation pass

This package was continued from the v1 restructure with a **best-effort owner_faction backfill** across the canonical gameplay master.

What changed:
- populated `owner_faction` in `02_Data/Kudurru_Kings_Gameplay_Master_v1.csv`
- regenerated `06_Exports/Kudurru_Kings_Master_Export_v1.csv` with populated factions
- added `owner_faction` into `02_Data/Kudurru_Kings_Content_Metadata_v1.csv` for easier cross-reference
- removed `owner_faction` rows from `02_Data/Kudurru_Kings_Unresolved_Backfills_v1.csv`
- cleared `02_Data/Kudurru_Kings_Validation_Errors_v1.csv` because the prior blocking validation issue was missing factions only
- added `05_Tracking/Kudurru_Kings_Faction_Assignment_Review_v1.csv` for row-level confidence and scoring
- added `05_Tracking/Kudurru_Kings_Faction_Assignment_Summary_v1.csv` for per-family quota totals

Important note:
- owner_faction assignment in this continuation pass is **heuristic/provisional**, built only from the surviving package content (card names, rules text, race metadata, and faction doctrine targets).
- it is suitable as a working build backfill, but low-confidence rows should still be reviewed manually.


## Low-confidence faction review sweep (v3)
- Promoted 35 low-confidence rows to medium where surviving race/token evidence supported the current owner_faction.
- Applied 3 quota-safe faction reassignments in the canonical gameplay master.
- Remaining low-confidence rows after sweep: 281.
- Added faction review outputs with explicit evidence, recommendations, and notes.


## v4 continuation — low-confidence promotion pass
- Promoted 21 low-confidence faction rows to medium based on owner-top surviving evidence (score >= 3).
- Remaining low-confidence rows: 260.
- No faction reassignments were applied in this pass; canonical quotas remain unchanged.
