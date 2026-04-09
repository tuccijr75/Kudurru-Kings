# Kudurru Kings — Finalized Replacement Set

This folder is the finalized replacement set intended to replace the previously split doctrine docs.

## Folder structure

### 01_Doctrine
- `Kudurru_Kings_Final_Gameplay_Doctrine_v1_0.md`
  - Replaces the split gameplay/rules/dynamics markdown set

### 02_Engineering
- `Kudurru_Kings_Final_Engineering_and_Data_Doctrine_v1_0.md`
  - Replaces the split card schema + implementation spec markdown set

### 03_Data
- `Kudurru_Kings_Master_Cards_Current.csv`
- `Kudurru_Kings_Master_Units_Current.csv`

### 04_Tracking
- `Kudurru_Kings_Mechanics_Alignment_Matrix.csv`

### 05_Admin
- `Kudurru_Kings_Old_to_New_Mapping.md`
- `Finalized_Set_Manifest.json`

## Practical authority order

1. `01_Doctrine/Kudurru_Kings_Final_Gameplay_Doctrine_v1_0.md`
2. `02_Engineering/Kudurru_Kings_Final_Engineering_and_Data_Doctrine_v1_0.md`
3. `03_Data/*.csv`
4. `04_Tracking/Kudurru_Kings_Mechanics_Alignment_Matrix.csv`

## Notes

- Data CSVs are preserved as separate masters because they are operational source files, not prose doctrine.
- The alignment matrix remains separate because it is a live implementation-gap tracker, not a rules section.
- The split markdown docs are consolidated into two larger doctrine files for easier replacement and comparison.
