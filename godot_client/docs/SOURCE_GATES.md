# Source and Certification Gates — 2026-10-20

## M1 scope boundary
Development-only interface / pure rules helpers. The shell does not assert the full rules engine exists. No simulated result is permitted to mutate a persistent player inventory.

## Verified source facts
The repository's `02_Data/Kudurru_Kings_Gameplay_Master_v1.csv` contains 754 data rows and 136 columns. On the cost-balance development branch, all 754 deployment cost triplets are positive under the deterministic v1 baseline, and 397 inherited upkeep values were normalized. Gameplay and effects remain uncertified; see `COST_BALANCE_DOCTRINE_V1.md`.

## EOE original Crosswalk alignment (audit, not mutation)
- Drowned Archivist: UnderwellKeepers (source: FloodbornPact)
- Ash Prophetess: Fateforge (source: FloodbornPact)
- Chain Marshal: BorderstoneGuild (source: FloodbornPact)
- Taxlord Balash: BorderstoneGuild (source: Fateforge)
- Silver Mask Judge: SkyloomTemple (source: matches)
- Adamu: BorderstoneGuild (source: matches)
- Mercy Docket: Crosswalk's Borderstone Guild **named figure** collides with a Kudurru **Edict** row assigned UnderwellKeepers. Do not auto-reassign without identity review.
- Rille Broker: absent from gameplay master under exact name; source Crosswalk dictates KK assignment for matching identity if introduced.

## Shipping rule contracts already enforced in M1 shell
- Exactly seven phases: Upkeep, Draw, Edicts, Main, Battle, Resolution, End.
- Starting resources: 2 Sinew, 1 Sigil, 1 Oath.
- End-phase conditional resource gain and fallback; no invented scenario state.
- Capture only during Resolution for Downed + Bound targets; Boss requires all three Trial axes.
- Decline yields Defeated; attempting has no fabricated success rate.
- Standard 36 cards, 12+ Characters, 2+ Sites, 4+ Pet/Relic, <=3 Boss, <=3 Name, <=1 Host Sigil.
- Mixed and pure factions legal subject to card-specific locks; pure benefit inactive.

## Not implemented yet (not waived)
Full combat + Face-off tie resolution; lifecycle wound/downed/bound/defeated transitions; fields/lines/geasa; objective/Scenario; Edicts/Names law; Oath bid arbitration; raids; resource spending limits; Boss stance/aura/retaliation; deck-draw/mulligan/hand refill; collection persistence; account progression; multiplayer; security and anti-cheat.

## Next build step
First certify M1 with installed Godot executable, then implement M2 approved data certification and legal deck ingestion. Do not autofill 754 missing deployment costs.
