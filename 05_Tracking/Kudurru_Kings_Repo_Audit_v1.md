# Kudurru Kings Repo Audit v1

Date: 2026-04-20

## Audit conclusion

This repository is a canonical gameplay-content package, not a runnable game client or Unity project.

The coherent retained build set is:
- `01_Rules/` for live gameplay authority
- `02_Data/` for canonical gameplay data and metadata sidecars
- `03_Implementation/` for migration mapping, acceptance coverage, and runtime sequencing
- `04_Product/` for retained product doctrine that still informs the build
- `05_Tracking/` for legacy audit artifacts and faction review aids
- `06_Exports/` for regenerated build/export outputs
- `attached_assets/` for supporting art and render assets
- `00_README_Migration_Manifest_v1.md` as the migration handoff

## Verified consistency

- Canonical gameplay master rows: `754`
- Master export rows: `754`
- Production metadata rows: `754`
- Production export rows: `754`
- Blank `owner_faction` rows in canonical gameplay master: `0`
- Key identity mismatches between canonical master and master export: `0`
- Validation errors file contains header only, with no active blocking rows

## Cleanup decision

The legacy tracked set under `Archive/`, `csvs/`, and `gameplay_docs/` is superseded by the numbered canonical structure and should remain removed.

The following local-only artifacts do not belong in the retained build set:
- `.env`
- `.local/state/replit/agent/*`
- `gitattributes.txt`
- `shipping_rules_v_1.md`
- `Kudurru-Kings.zip`

`attached_assets/card_images.zip` remains part of the retained set because the canonical data and export files reference it directly as the image package.

## Remaining material gap

`02_Data/Kudurru_Kings_Unresolved_Backfills_v1.csv` still contains `754` unresolved `cost_*` backfill rows. The migrated package is internally consistent enough to serve as the single canonical source pack, but cost normalization still requires explicit design review before calling the data fully build-locked.
