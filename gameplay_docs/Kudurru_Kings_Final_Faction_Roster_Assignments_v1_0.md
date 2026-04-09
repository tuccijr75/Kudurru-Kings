# Kudurru Kings — Final Faction Roster Assignments v1.0

## Purpose

This document finalizes the shipping roster assignment policy for the five core factions already defined in gameplay doctrine:
- Borderstone Guild
- Floodborn Pact
- Skyloom Temple
- Underwell Keepers
- Fateforge

It resolves the previously open shipping gap around faction-to-card assignment by locking:
- faction ownership by family
- faction package counts
- neutral policy
- launch roster structure
- per-faction distribution targets

## Canon faction set

### 1. Borderstone Guild
Primary identity:
- Field Dominion
- Sites
- local combat control
- territorial value

### 2. Floodborn Pact
Primary identity:
- Veil mobility
- displacement
- evasive positioning
- soft denial

### 3. Skyloom Temple
Primary identity:
- Oath adjudication
- Arbitration
- law timing
- sanction control

### 4. Underwell Keepers
Primary identity:
- capture
- bind
- attrition finishing
- weakened-state punishment

### 5. Fateforge
Primary identity:
- Audit Heat
- cost-risk conversion
- dangerous tempo spikes
- legal overreach

## Neutral policy

Launch policy:
- **No neutral cards in the shipping roster.**
- Every launch card belongs to exactly one of the five factions.
- Neutral cards are reserved for future scenarios, tutorials, or expansion products only.

Reason:
- cleaner onboarding
- stronger faction identity
- cleaner deckbuilding logic
- simpler UI filtering
- stronger launch balance telemetry

## Family assignment rule

Every card in the launch roster must be assigned to exactly one faction by `owner_faction`.

Canonical owner_faction values:
- Borderstone Guild
- Floodborn Pact
- Skyloom Temple
- Underwell Keepers
- Fateforge

## Locked family distribution targets

The current card set size is:
- Characters: 500
- Bosses: 164
- Edicts: 15
- Host Sigils: 15
- Names: 15
- Pets: 15
- Relics: 15
- Sites: 15

### Minor-family distribution
The 15-card minor families are distributed evenly:
- 3 Edicts per faction
- 3 Host Sigils per faction
- 3 Names per faction
- 3 Pets per faction
- 3 Relics per faction
- 3 Sites per faction

### Character distribution
Characters are distributed evenly:
- 100 Characters per faction

### Boss distribution
Bosses are distributed as evenly as possible:
- Borderstone Guild: 33
- Floodborn Pact: 33
- Skyloom Temple: 33
- Underwell Keepers: 33
- Fateforge: 32

This distribution is accepted as canon for launch unless a later deliberate rebalance changes total boss count.

## Per-faction launch package

### Borderstone Guild
- 100 Characters
- 33 Bosses
- 3 Edicts
- 3 Host Sigils
- 3 Names
- 3 Pets
- 3 Relics
- 3 Sites

Focus:
- Field control
- durable front-line units
- site leverage
- stable support tools

### Floodborn Pact
- 100 Characters
- 33 Bosses
- 3 Edicts
- 3 Host Sigils
- 3 Names
- 3 Pets
- 3 Relics
- 3 Sites

Focus:
- Veil pressure
- movement
- silence/disruption
- relation-breaking plays

### Skyloom Temple
- 100 Characters
- 33 Bosses
- 3 Edicts
- 3 Host Sigils
- 3 Names
- 3 Pets
- 3 Relics
- 3 Sites

Focus:
- Oath lines
- arbitration
- law control
- sanction pressure

### Underwell Keepers
- 100 Characters
- 33 Bosses
- 3 Edicts
- 3 Host Sigils
- 3 Names
- 3 Pets
- 3 Relics
- 3 Sites

Focus:
- capture
- bind
- wound exploitation
- collapse punishment

### Fateforge
- 100 Characters
- 32 Bosses
- 3 Edicts
- 3 Host Sigils
- 3 Names
- 3 Pets
- 3 Relics
- 3 Sites

Focus:
- Heat manipulation
- risk conversion
- explosive tempo
- legal volatility

## Assignment doctrine by family

### Characters
Characters should be assigned according to each faction's gameplay identity:
- Borderstone Guild: field holders, defenders, site stabilizers
- Floodborn Pact: evasive units, disruptors, mobility specialists
- Skyloom Temple: oath users, legal enforcers, timing controllers
- Underwell Keepers: binders, finishers, weakened-state punishers
- Fateforge: heat users, high-risk payoff units, volatility engines

### Bosses
Bosses should be the most concentrated expression of each faction's primary subsystem:
- Borderstone Guild: territorial anchors
- Floodborn Pact: space-warping or deceptive bosses
- Skyloom Temple: sanction / arbitration bosses
- Underwell Keepers: capture / grave-pressure bosses
- Fateforge: heat-spike / overreach bosses

### Names
Each faction receives 3 Names:
- one stabilizer law
- one pressure law
- one closer or high-risk distortion law

### Edicts
Each faction receives 3 Edicts:
- one reactive answer
- one tempo opener
- one signature faction intervention

### Sites
Each faction receives 3 Sites:
- one economy/control Site
- one tactical conflict Site
- one scoring/raid Site

### Relics
Each faction receives 3 Relics:
- one unit amplifier
- one subsystem converter
- one high-value identity relic

### Pets
Each faction receives 3 Pets:
- one early support piece
- one synergy extender
- one specialty/tactical companion

### Host Sigils
Each faction receives 3 Host Sigils:
- one stabilizer
- one swing piece
- one closer or mythic identity anchor

## Deckbuilding implication

Launch deckbuilding uses faction-locked pools.
A legal faction deck may only include cards from:
- its chosen faction
- plus any future explicitly allowed neutral/tutorial/scenario cards

Since launch policy is no neutrals, faction deckbuilding is fully faction-pure by default.

## Data requirement

The live and production masters should include:
- `owner_faction`

Accepted values:
- `Borderstone Guild`
- `Floodborn Pact`
- `Skyloom Temple`
- `Underwell Keepers`
- `Fateforge`

No blank owner_faction values are allowed in the launch roster.

## Final doctrine

Faction roster assignment is now considered resolved at the structure level.

Remaining implementation work is not to decide faction philosophy anymore. It is to assign each individual launch card into the locked faction package counts above and write that assignment into the live master data.
