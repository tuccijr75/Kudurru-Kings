> Migrated note: Legacy shipping-gap tracker migrated from migrate.zip. Preserved as planning history and implementation backlog reference.

# Kudurru Kings — Shipping Gaps v1.0

## Purpose

This document defines the remaining production gaps between the finalized doctrine set and a shipping-ready product. It converts the remaining undefined areas into a formal shipping checklist and priority ladder.

## Canon shipping update

The product stance is now updated as follows:
- **Official shipping support:** 2 to 4 simultaneous players.
- **Expanded support:** more than 4 players is permitted only if gameplay quality, rules clarity, pacing, UI legibility, state readability, and system performance remain acceptable after validation.
- Multiplayer is no longer treated as an optional extension in product planning. It is a full shipping target through 4 players.

## Remaining gaps

### 1. Final content authoring at card-by-card level
The engineering doctrine defines the schema, text templating, timing hooks, and legality rules, but that does not mean every card has final authored mechanical text, complete hook data, validation-complete fields, and balance-ready values.

This gap includes:
- final rules text for every card
- final timing-hook assignment for every card
- validation-complete card records
- family-specific data completion
- balance-ready numeric values
- final keyword cleanup
- final legality pass against the card schema

### 2. Final faction-to-card assignment
Faction identities and subsystem roles are defined, but the actual shipping mapping of cards, bosses, names, relics, sites, pets, and host sigils into finalized faction rosters is still incomplete.

This gap includes:
- full faction roster assignment
- neutral-card policy
- faction starter/core package definition
- faction scarcity balance
- faction-specific closer distribution
- faction mirror-match sanity pass

### 3. Full scenario catalog and official format package
Scenario modifiers exist, but the full shipping format program is not yet locked.

This gap includes:
- full official scenario list
- final short / standard / long match package
- draft policy, if shipping
- sealed policy, if shipping
- tournament policy, if shipping
- sideboard policy, if any
- rematch / best-of rules
- scenario legality and selection rules
- ranked/casual format differences if digital

### 4. Final multiplayer product stance
Multiplayer is now a shipping feature up to 4 simultaneous players, but the supporting rule and product details still need completion.

This gap includes:
- final turn-order rules for 3 and 4 players
- full arbitration behavior in multiplayer
- multiplayer targeting sanity pass
- field control resolution in 3–4 players
- simultaneous-win rules in full product format
- kingmaking / elimination / concession policy
- UI scaling for 3–4 players
- performance validation for 4-player digital play
- controlled testing for more than 4 players if gameplay permits

### 5. Canon-to-build reconciliation is still unfinished
The doctrine preserves a split between the canonical target game and the current Base44 build snapshot. The app is not yet fully conformed to canon.

Known examples include:
- draw refilling toward 6 instead of the canonical normal draw
- simplified combat resolution
- partial subsystem implementation depth

This gap includes:
- build-vs-canon diff closure
- resolver alignment
- phase behavior alignment
- multiplayer alignment
- state visibility compliance
- scenario support alignment
- boss/arbitration behavior alignment

### 6. Final UI/state implementation mapping in the actual app
The rules now require visible state such as:
- Field dominance
- Trial counters
- Audit escalation
- Name ownership
- capture / bind / raid eligibility

That visibility requirement is canonical, but actual app exposure is still incomplete.

This gap includes:
- exact UI field mapping for all required state flags
- 2-player and 4-player layout support
- state-priority ordering
- tooltip / codex surface decisions
- hidden vs public state validation
- animation and resolution clarity for high-complexity turns

### 7. Final balance targets and live tuning
The dynamics layer defines the intended feel of the game, but not final locked numerical balance.

This gap includes:
- final cost curves
- per-family rate bands
- target matchup spread
- target game length bands
- live balance thresholds
- card-by-card tuning outcomes
- faction win-band targets
- archetype overrepresentation thresholds

## Priority ranking

### Highest priority
1. Build alignment to canon
2. Card-by-card content completion
3. Final faction roster mapping
4. Official format / scenario package
5. UI/state exposure compliance

### Secondary
6. Multiplayer as full product mode through 4 players, with more than 4 only if validated
7. Numerical balance and live tuning targets

## Shipping workstreams

### Workstream A — Canon alignment
Definition of done:
- all live systems obey canonical phase, combat, arbitration, boss, and state rules
- build snapshot no longer contains rule-level drift from doctrine
- multiplayer through 4 players is rules-valid and implemented

### Workstream B — Content completion
Definition of done:
- every shipping card has final text, hooks, validation-complete data, and production-ready values
- every faction roster is fully assigned
- all family distributions are legal and intentional

### Workstream C — Product package
Definition of done:
- official formats are locked
- scenarios are enumerated and legality checked
- multiplayer shipping rules are finalized
- rematch / best-of / sideboard policy is locked where applicable

### Workstream D — UI and state clarity
Definition of done:
- all required state flags are visible and understandable
- 2–4 player interfaces remain legible
- resolution visibility is sufficient for deterministic competitive play

### Workstream E — Balance and live tuning
Definition of done:
- target pacing is met
- archetype ecosystem is healthy
- faction and multiplayer balance are within acceptable target bands
- tuning process and patch thresholds are defined

## Canon note

This document is the official shipping-status companion to the finalized doctrine set until every workstream is closed.
---

## Reconciliation update

This shipping-gaps document now also records the following audited reconciliation facts:

### Multiplayer status reconciliation
The authoritative shipping stance is now:
- full support for 2, 3, and 4 simultaneous players
- more than 4 only if validated

Any earlier wording describing 3–4 players as merely optional or extension-mode support is superseded.

### Current build snapshot facts incorporated into shipping planning
The current Base44 implementation currently shows:
- 7-phase turn spine
- 4-seat visible multiplayer presentation
- hand refill draw model to 6
- simplified deterministic combat
- direct implemented capture-to-marks flow
- end-step +1 / +1 / +1 resource gain

These are now treated as explicit reconciliation inputs for shipping workstream planning.
