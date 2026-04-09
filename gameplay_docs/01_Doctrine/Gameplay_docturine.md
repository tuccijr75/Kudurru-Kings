# Kudurru Kings — Final Gameplay Doctrine v1.1

## Purpose

This is the consolidated gameplay doctrine for Kudurru Kings. It merges the active gameplay, rules, appendices, dynamics, archetype, faction, and endgame doctrine into one authority file.

## Replacement intent

This version updates canon to include formal shipping-level product data and the new Shipping Gaps framework.

## Authority order inside this file

1. Working gameplay reference and build snapshot
2. Canonical rules
3. Procedural appendix
4. Boss and Arbitration appendix
5. Gameplay dynamics framework
6. Archetype matrix
7. Faction dynamics
8. Endgame and comeback rules
9. Shipping canon addendum

---

# Section A — Working Gameplay Reference and Current Build Snapshot

**Merged from:** `Kudurru_Kings_Master_Gameplay_Mechanics.md`

# Kudurru Kings — Master Gameplay Mechanics (Current Consolidated)

## Purpose
This file consolidates the uploaded gameplay and character materials into a single current-reference document.

## Card-set authority
The card master set contains **754 cards** with **754 unique names**.

Family breakdown:
- **character**: 500
- **boss**: 164
- **edict**: 15
- **host_sigil**: 15
- **name**: 15
- **pet**: 15
- **relic**: 15
- **site**: 15

The uploaded `Kudurru_Kings_All_Cards_Master.csv` matches `Card_export.csv` exactly, so the replacement card master is a normalized export of the same 754-card set.

## Consolidated gameplay model

### A. Current digital master turn structure
For the **digital master** reference, use the 7-phase structure because it is the structure present in:
- the Base44 `Game` entity
- the current gameplay page
- the current tutorial/phase panel
- the playthrough document

Digital master phase order:
1. Upkeep
2. Draw
3. Edicts
4. Main
5. Battle
6. Capture
7. End

### B. Design-canon target rules
For the **full rules target**, keep the unified rulebook semantics, even where the current build is simplified.

Core target rules to preserve:
- Deterministic combat
- Stone / Veil / Oath as the core test axes
- Jurisdiction Fields and Line/Geas interactions
- Names, Audit Heat, and Arbitration
- Bind and Boss Trial requirements
- Marks-based victory
- 36-card legal decks
- 6-card opening hand
- Starting resources: Sinew 2 / Sigil 1 / Oath 1

## Current digital implementation baseline
Use this section as the "what the current build does now" reference.

### Setup and flow
- The current build is organized around **4 visible seats**.
- Opening / steady-state hand logic currently behaves like a **hand cap of 6**, and the Draw phase currently fills hand space back toward 6.
- Starting resources are **Sinew 2 / Sigil 1 / Oath 1**.
- The current build tracks:
  - `measure_marks`
  - `audit_heat`
  - `hand`
  - `field`
  - phase progression
  - player resources

### Phase behavior snapshot from the build
- **Upkeep**: currently pays total Oath upkeep for cards in field.
- **Draw**: currently draws enough cards to refill hand toward 6 rather than drawing exactly 1.
- **Edicts**: currently handles Name / Edict-style plays and raises Audit Heat when applicable.
- **Main**: currently handles Character / Boss / Pet / Relic / Site / Host Sigil deployment.
- **Battle**: currently resolves combat in a simplified deterministic way by comparing a selected axis value.
- **Capture**: currently converts downed units into Marks gain.
- **End**: currently collects +1 Sinew / +1 Sigil / +1 Oath in the current build flow.

### Current build audit ladder
The current UI/build material exposes this threshold ladder:
- 3+: Watched
- 5+: Censor Wraith
- 7+: Tribunal
- 9+: Lawbroke Candidate

Retain this ladder in the consolidated reference because it is visibly represented in the current build.

## Full canonical mechanics to preserve (even if not fully implemented yet)

### 1. Deck construction
- Exactly 36 cards
- Opening hand of 6
- Up to 2 copies of a named card
- Super Rare limit of 1 copy of a given Super Rare
- Host Sigil maximum of 1 total in a deck
- Minimum 12 Characters
- Minimum 2 Sites
- Minimum 4 support cards from Pets + Relics combined
- Maximum 3 Bosses
- Maximum 3 Names

### 2. Card families
Canonical families:
- Character
- Boss
- Pet
- Relic
- Name
- Edict
- Site
- Host Sigil

### 3. Fields, Lines, and Geasa
Preserve the full field model from the unified rulebook and playthrough:
- up to 2 active Fields by default
- standard tags: Sanctuary, Threshold, Wilds, Warfield
- Line crossing triggers Geasa
- standard Geasa include Oath-bind, Tribute, and Stagger

### 4. Deterministic combat target model
Preserve this as the master target ruleset:
1. declare attacker and defender
2. choose test axis (Stone / Veil / Oath)
3. choose intended consequence (Wound / Displace / Silence / Bind)
4. each side may add 1 ready supporter
5. each side may spend up to 2 matching resources
6. supporter adds half its chosen-axis value, rounded up, and gains Heat
7. apply world/faction/card modifiers
8. compare totals
9. resolve consequence
10. exhaust participants/supporters

### 5. Consequences
- **Wound**: 2 Wounds = Downed
- **Displace**: movement out of a Field or across a Line, triggering Geasa where relevant
- **Silence**: text blanked until controller's next Upkeep unless otherwise stated
- **Bind**: legal only under the documented Downed + Oath/Sanctuary conditions

### 6. Boss rules
Preserve the full Boss model:
- Bosses require Oath Upkeep
- Bosses cannot be Bound until they have **3 Trial counters**
- Trial counters are earned across different successful challenge axes/tests

### 7. Audit Heat and Arbitration
Preserve:
- Name installation/swapping increases Audit Heat
- Audit checks at high heat
- Arbitration as an Oath-bid contest over enemy Names
- End-phase card discard as a design-side heat relief option

### 8. Victory
Keep the full Marks model as canonical target:
- Character defeat/capture: +1 Mark
- Boss defeat/capture: +2 Marks
- Successful Name seizure via Arbitration: +1 Mark
- Site raid win: +1 Mark
- Standard target: 10 Marks
- Optional thresholds: 6 short / 12 long

## Reconciliation decisions
These are the decisions used in the replacement file set.

1. **All card membership, naming, and family truth comes from `Card_export.csv`.**
2. **`mechanics_expanded.csv` is the complete supplemental mechanics reference** for character/boss rows because it covers all 664 current Character/Boss cards. The base `mechanics.csv` misses **Anu the Exarch of Heaven**.
3. **`EoE_Prompts.csv` is preserved as character-art reference only** and merged into the character/unit master file. All 330 prompt rows match real master-card names.
4. **The current build is not treated as the sole rules authority** where it clearly simplifies mechanics relative to the unified rulebook.
5. **The unified rulebook remains the target-rules authority** for mechanics not fully implemented in the build.

## Notes on what was intentionally not changed
- No files inside `Base44webapp_current.zip` were edited.
- The replacement pack is documentation/data only.

---

# Section B — Canonical Master Rules

**Merged from:** `Kudurru_Kings_Canonical_Master_Rules_v1_0.md`

# Kudurru Kings — Canonical Master Rules v1.0

## Authority and scope

This document is the **master gameplay ruleset** for Kudurru Kings. It uses the consolidated gameplay reference as its source foundation and preserves the following as canonical:
- the 7-phase turn structure
- deterministic combat
- Stone / Veil / Oath as the core test axes
- Jurisdiction Fields, Lines, and Geasa
- Names, Audit Heat, and Arbitration
- Bind and Boss Trial requirements
- Marks-based victory
- 36-card legal decks
- 6-card opening hand
- starting resources of Sinew 2 / Sigil 1 / Oath 1. fileciteturn4file0turn4file1turn4file2

Where the uploaded materials preserve an intent but do not fully specify an edge case, this master supplies a **canonical ruling** so the game can be implemented consistently. Those rulings are presented as normalization decisions, not as verbatim source text. The current digital build is treated as implementation evidence, but the unified-rulebook target remains the governing rules authority whenever the build is simpler than the intended design. fileciteturn4file0turn4file1

---

## 1. Game identity

Kudurru Kings is a **deterministic tactical law-war card game**. Players deploy Characters, Bosses, Sites, Names, Edicts, Pets, Relics, and Host Sigils to establish board control, manipulate jurisdiction, force combat outcomes along Stone / Veil / Oath axes, and convert successful defeats, captures, raids, and legal seizures into **Marks**. fileciteturn4file0turn4file1

The game is not luck-driven. Conflict resolution depends on:
- chosen test axis
- declared intended consequence
- supporter commitment
- resource expenditure
- field, line, and geas pressure
- card and faction modifiers
- timing and sequencing across the seven phases. fileciteturn4file1turn4file2

---

## 2. Victory condition

The standard victory target is **10 Marks**. Optional shorter and longer thresholds are **6 Marks** and **12 Marks**. Marks are awarded as follows:
- defeat or capture a **Character**: +1 Mark
- defeat or capture a **Boss**: +2 Marks
- successfully seize a **Name** through Arbitration: +1 Mark
- win a **Site raid**: +1 Mark. fileciteturn4file1

### Canon ruling: immediate win check

---

## 3. Components and card families

The canonical card families are:
- Character
- Boss
- Pet
- Relic
- Name
- Edict
- Site
- Host Sigil. fileciteturn4file2turn4file7

The master set contains **754 cards**:
- 500 Characters
- 164 Bosses
- 15 Edicts
- 15 Host Sigils
- 15 Names
- 15 Pets
- 15 Relics
- 15 Sites. fileciteturn4file0

### Functional roles
**Characters** are the primary field units and the main source of ordinary pressure, support, and capture targets.  
**Pets** are support-oriented permanents or adjunct units.  
**Relics** are persistent support tools or modifiers.  
**Names** are laws or local reality edits that create board-level pressure but also generate Audit Heat.  
**Edicts** are event-style legal plays and interventions.  
**Sites** define places worth contesting or raiding.  
**Host Sigils** are powerful deck-level or board-level anchors with tight deckbuilding limits. fileciteturn4file0turn4file1

---

## 4. Deck construction

A legal deck must contain exactly **36 cards** and obey all of the following:
- opening hand is 6 cards
- maximum 2 copies of a named card
- maximum 1 copy of a given Super Rare card
- maximum 1 Host Sigil total
- minimum 12 Characters
- minimum 2 Sites
- minimum 4 support cards from Pets + Relics combined
- maximum 3 Bosses
- maximum 3 Names. fileciteturn4file2

### Canon ruling: deck legality precedence
If a card could violate multiple constraints, all constraints still apply. For example, a Super Rare Boss counts against both the Super Rare cap and the Boss cap.

---

## 5. Setup

1. Each player presents a legal 36-card deck.
2. Each player shuffles and draws **6 cards**.
3. Each player begins with:
   - Sinew 2
   - Sigil 1
   - Oath 1.
4. Each player begins at:
   - 0 Marks
   - 0 Audit Heat.
5. The match uses the standard Marks target unless a shorter or longer format is declared before setup. fileciteturn4file0turn4file2

### Canon rulings for setup gaps
- If mulligans are used, each player may take **one full mulligan to 6**, then shuffle one card from hand to the bottom of deck. This preserves the 6-card opener while reducing non-games.
- Players choose initial seats and reveal any pre-game Host Sigil effects before the first Upkeep.

---

## 6. The seven phases

The canonical phase order is:
1. Upkeep
2. Draw
3. Edicts
4. Main
5. Battle
6. Capture
7. End. fileciteturn4file0turn4file2turn4file16

### Phase permissions summary
**Upkeep**
- pay required Oath upkeep
- resolve "at Upkeep" effects
- expire temporary Silence effects that end at controller's next Upkeep. fileciteturn4file2turn4file1

**Draw**
- perform the phase draw rule for the chosen format. The current digital build refills toward 6, but the canonical master uses a normal draw of **1 card** per turn after setup unless a mode or card effect states otherwise. The digital refill behavior remains recognized as a build-side simplification, not the canonical long-term rule. fileciteturn4file2

**Edicts**
- play Names and Edicts
- perform law changes, installations, swaps, and audit-risking interventions
- gain Audit Heat when applicable. fileciteturn4file2turn4file1

**Main**
- deploy Characters, Bosses, Pets, Relics, Sites, and Host Sigils
- reposition or activate non-combat board effects if a card permits it
- prepare the board for Battle. fileciteturn4file2

**Battle**
- declare conflicts
- resolve deterministic combat using the full combat model in this master. fileciteturn4file1turn4file2

**Capture**
- convert eligible downed, bound, or otherwise captured states into Marks
- resolve raid, seizure, and formal capture outcomes. fileciteturn4file2turn4file1

**End**
- resolve "at End" effects
- perform end-step cleanup
- in the current build, +1 Sinew / +1 Sigil / +1 Oath is granted here; this master preserves that as the canonical baseline economy unless a future economy revision is intentionally adopted. fileciteturn4file2

### Canon ruling: priority structure
Kudurru Kings uses an **active-player priority** model within each phase:
1. active player resolves mandatory phase actions
2. active player may take optional actions
3. non-active players may respond if a card or law allows out-of-turn intervention
4. once all players pass, the phase advances.

This rule is a normalization decision for implementation clarity.

---

## 7. Resources and costs

### Resource types
- **Sinew**: bodily force, field exertion, and material deployment
- **Sigil**: legal inscription, ritual authority, and rule-changing plays
- **Oath**: binding force, sanction, endurance, and elite maintenance. fileciteturn4file0turn4file1

### Canon spending rules
- costs must be paid in full
- a player cannot spend below zero
- resource spending is public
- resource matching matters during combat when the chosen axis or effect requires matching resource expenditure. fileciteturn4file1

### Income baseline
At End, gain:
- +1 Sinew
- +1 Sigil
- +1 Oath. fileciteturn4file2

### Canon ruling: no hand-size discard by default
There is no universal hand-size discard rule in this master. Any required discard is created by card text, audit relief, or scenario rule.

---

## 8. Field model, Lines, and Geasa

The canonical board supports up to **2 active Fields** by default. Recognized field tags include:
- Sanctuary
- Threshold
- Wilds
- Warfield. fileciteturn4file1turn4file2

### Lines
Lines divide or connect Fields and define movement triggers. A unit that moves across a Line is treated as having **crossed jurisdiction**.

### Geasa
Crossing a Line can trigger a Geas. Standard Geasa preserved by the source are:
- **Oath-bind**
- **Tribute**
- **Stagger**. fileciteturn4file1turn4file2

### Canon master definitions
**Oath-bind**: the crossing unit becomes legally constrained. Until its controller's next Upkeep, it cannot initiate Bind and cannot be chosen as a supporter unless a card says otherwise.  
**Tribute**: the crossing unit's controller must pay 1 resource associated with the crossed line or field. If no specific resource is named, the controller chooses and pays 1 resource if able; otherwise the unit becomes Staggered.  
**Stagger**: the unit is rattled and suffers -1 on its next chosen test axis this turn, or cannot support if no combat remains this turn.

These detailed effects are canonical rulings added to make the preserved Geasa list implementation-ready.

### Field occupancy
- a Field may contain units from multiple players unless a card says otherwise
- some effects will reference "inside a Field," "outside a Field," or "across a Line"
- forced movement can trigger Geasa just like voluntary movement unless the effect explicitly says "without triggering Lines."

---

## 9. Unit states

A unit may be in one or more of these states:
- ready
- exhausted
- wounded
- downed
- silenced
- bound
- staggered
- trialed (Boss-specific). fileciteturn4file1

### Canon state definitions
**Ready**: may act, support, or use ready-only abilities.  
**Exhausted**: has already acted or been committed; cannot attack or support unless re-readied.  
**Wounded**: marked damage pressure. At **2 Wounds**, a unit becomes **Downed**. fileciteturn4file1  
**Downed**: remains on the field but is vulnerable to capture, bind conditions, and displacement.  
**Silenced**: text box is blank until the controller's next Upkeep unless a card overrides. fileciteturn4file1  
**Bound**: legally restrained under valid Bind conditions.  
**Staggered**: temporarily unstable after a Line or effect interaction.  
**Trialed**: a Boss with one or more Trial counters.

### Canon ruling: state persistence
- Wounds persist until removed by an effect or until the unit leaves play.
- Silence expires at the silenced unit controller's next Upkeep.
- Bound persists until removed by an effect, by leaving play, or by a rule condition that explicitly breaks the bind.

---

## 10. Full combat system

Combat is the most important mechanical expansion in this master. The source preserves the skeleton; this section flushes it out into a complete deterministic procedure. fileciteturn4file1turn4file2

## 10.1 Combat eligibility

A unit may initiate combat if:
- it is ready
- it is on the field
- it is not prohibited from attacking by Silence, Bind, Stagger, or card text
- there is a legal target within the permitted board relation.  

A unit may defend if:
- it is on the field
- it is not removed from legal targeting by a card or field rule.

### Canon ruling: battle count
By default, each ready unit may participate in **one declared combat as a primary participant per Battle phase**.

---

## 10.2 Combat declaration

For each combat:
1. attacker declares the attacking unit
2. attacker declares the defending unit
3. attacker chooses the **test axis**:
   - Stone
   - Veil
   - Oath
4. attacker declares the intended consequence:
   - Wound
   - Displace
   - Silence
   - Bind. fileciteturn4file1

### Canon ruling: legality of declared consequence
A declared consequence must be legal **at declaration time**. If Bind is not legal, the attacker may not declare Bind and must choose another consequence.

---

## 10.3 Axis meaning

**Veil** represents obscuration, misdirection, subtlety, and precision denial.  
**Oath** represents authority, sanction, binding force, and law-backed contest. fileciteturn4file0turn4file1

### Canon use guidance
- Wound most naturally pairs with Stone
- Silence most naturally pairs with Veil
- Bind most naturally pairs with Oath
- Displace may pair with Stone or Veil depending on whether force or misdirection is being used

This is guidance, not a hard restriction, unless a specific card says otherwise.

---

## 10.4 Support step

After declaration, each side may add **1 ready supporter**. The supporter must:
- be ready
- be able to affect the conflict
- not already be committed elsewhere
- not be forbidden by Silence, Bind, or a Geas. fileciteturn4file1

The supporter adds **half of its chosen-axis value, rounded up**, and gains Heat. fileciteturn4file1

### Canon rulings for support
- a side may choose zero supporters
- the supporter's contributed axis is the same axis chosen for the combat
- a supporter becomes exhausted after the combat resolves
- a supporter that is silenced still contributes raw axis value unless its value itself is granted by text rather than printed stats
- a supporter gains **+1 Audit Heat to its controller** unless a card says otherwise

That last point is a normalization decision based on the source phrase "gains Heat" and the broader Audit Heat system. fileciteturn4file1

---


Each side may spend up to **2 matching resources** during the combat. fileciteturn4file1

### Canon ruling: matching-resource mapping
For implementation clarity:
- Stone matches **Sinew**
- Veil matches **Sigil**
- Oath matches **Oath**

Each point spent adds **+1** to that side's combat total on the chosen axis.

### Spend order
1. attacker chooses support and spends
2. defender chooses support and spends

---

## 10.6 Modifiers and total calculation

After supporter contributions and resource spend:
1. start with the primary participant's value on the chosen axis
2. add supporter contribution, if any
3. add matching-resource spend
4. apply field modifiers
5. apply line / geas modifiers
6. apply card modifiers
7. apply faction or persistent law modifiers
8. lock totals and compare. fileciteturn4file1

### Canon modifier rule
If multiple modifiers apply, additive modifiers apply before multiplicative or replacement text. If two replacement effects conflict, the active player's effects resolve first, then the defending side's.

This is a canonical implementation ruling.

---

## 10.7 Resolution by consequence

### A. Wound
If the attacker wins, the defender gains 1 Wound. If that becomes the defender's second Wound, the defender becomes Downed. fileciteturn4file1

### B. Displace
If the attacker wins, the defender must move:
- out of the contested Field, or
- across an adjacent legal Line,
as specified by the attacking effect or board position. If the displacement crosses a Line, Geasa trigger normally. fileciteturn4file1

### C. Silence
If the attacker wins, the defender's text is blank until its controller's next Upkeep unless a card says otherwise. fileciteturn4file1

### D. Bind
Bind is legal only under the documented **Downed + Oath/Sanctuary** conditions. fileciteturn4file1

#### Canon Bind legality ruling
A unit may be Bound only if:
- it is currently Downed, and
- the conflict was resolved on Oath **or** the target is in a Sanctuary Field **or** the effect explicitly states it can Bind outside Sanctuary.

If a legal Bind succeeds, the unit becomes Bound instead of taking a new Wound.

---

## 10.8 Ties

The source preserves compare-and-resolve combat but does not fully specify tie handling. fileciteturn4file1

### Canon tie rule
On a tie:
- the declared consequence fails
- both primary participants become exhausted
- supporters, if any, also become exhausted
- no Wound, Displace, Silence, or Bind occurs unless a card explicitly changes tie handling

This keeps combat deterministic and prevents ties from producing unclear partial outcomes.

---

## 10.9 Exhaustion after combat

After combat resolves:
- both primary participants become exhausted
- all supporters become exhausted
- combat-specific temporary totals disappear. fileciteturn4file1

### Canon ruling: invalid target after declaration
If the target becomes illegal before totals lock, the combat fizzles and all already-committed participants still exhaust unless a card explicitly refunds commitment.

---

## 10.10 Counterplay and responses

Kudurru Kings allows responses only when a card, law, or field effect explicitly grants an interrupt, reaction, or replacement. Otherwise combat follows the deterministic sequence above.

This is an implementation-normalizing ruling intended to keep resolution stable.

---

## 11. Wounds, Downing, Capture, and removal

A unit with **2 Wounds** becomes **Downed**. fileciteturn4file1

### Capture phase master rule
During Capture, eligible downed or bound enemy units may be converted into Marks according to the victory schedule. The current build already converts downed units into Marks during Capture, and this master preserves Capture as the formal scoring conversion step rather than folding it directly into Battle. fileciteturn4file2turn4file1

### Canon capture flow
1. identify eligible enemy downed or bound units
2. active player declares capture target
3. resolve any "on capture" replacement text
4. award Marks
5. remove or mark the captured unit according to card/scenario text

### Canon removal ruling
Unless a card says otherwise, a successfully captured non-Boss unit leaves play after awarding Marks.

---

## 12. Bosses and Trials

Bosses:
- require Oath upkeep
- cannot be Bound until they have **3 Trial counters**
- earn Trial counters across different successful challenge axes or tests. fileciteturn4file1

### Canon master rule for Trial counters
A Boss gains **1 Trial counter** whenever it is successfully challenged on an axis it has not yet been trialed on this game:
- Stone Trial
- Veil Trial
- Oath Trial

Once a Boss has all three, it is **Trial-complete** and may be Bound if otherwise legal.

### Boss capture
A captured or defeated Boss awards **+2 Marks**. fileciteturn4file1

### Canon ruling: Boss defeat vs Boss capture
If a Boss is merely Downed but not captured, it does not automatically award Marks. Marks are awarded when the relevant defeat/capture condition is completed.

---

## 13. Names, Edicts, Audit Heat, and Arbitration

### Names and Edicts
The Edicts phase is the primary legal-manipulation phase. Names and Edicts change the law-state of play and can raise Audit Heat. fileciteturn4file2turn4file1

### Audit Heat ladder
The current consolidated reference preserves the build-visible threshold ladder:
- 3+: Watched
- 5+: Censor Wraith
- 7+: Tribunal
- 9+: Lawbroke Candidate. fileciteturn4file2

### Canon Audit Heat rule
- installing a Name: +1 Heat
- swapping or rewriting a Name: +1 Heat
- each supporter committed in combat: +1 Heat to its controller unless otherwise stated
- card text may increase or reduce Heat

These are master normalization decisions built around the preserved "Names increase Heat" and "support gains Heat" rules. fileciteturn4file1

### Threshold effects
**Watched (3+)**: no automatic penalty; the player is now a legal target for effects that require Watched status.  
**Censor Wraith (5+)**: first time each turn this threshold is crossed, the player must either discard a non-unit support card or gain +1 additional Heat.  
**Tribunal (7+)**: the player cannot install a second new Name this turn unless a card explicitly allows it.  
**Lawbroke Candidate (9+)**: the player must immediately survive an Audit check or lose 1 Mark.

These threshold effects are canonical rulings added to make the ladder mechanically complete.

### Audit checks
When an effect calls for an Audit check:
1. count the player's current Heat
2. apply any Heat reduction or immunity effects
3. resolve the stated penalty or replacement text
4. if no specific penalty is stated, the default penalty is lose 1 Sigil; if unable, lose 1 Mark

This is a canonical implementation ruling.

### Arbitration
Arbitration is preserved as an **Oath-bid contest over enemy Names**. fileciteturn4file1

#### Canon Arbitration procedure
1. choose a target enemy Name
2. both players secretly set an Oath bid from available Oath
3. reveal bids simultaneously
4. higher bid wins the Arbitration
5. both players spend their bid
6. if the aggressor wins, seize or suppress the target Name and gain **+1 Mark**
7. if the defender wins, the Name remains and the aggressor gains +1 Heat

If bids tie, defender wins.

That tie rule is a canonical normalization decision.

---

## 14. Sites and raids

Sites are a required deck component and a distinct family. A successful Site raid awards **+1 Mark**. fileciteturn4file1turn4file2

### Canon raid rule
A Site raid occurs when an attacking unit wins combat while targeting a Site or its designated guardian relation and meets any stated raid condition. If successful:
- award +1 Mark
- resolve the Site's "on raided" text, if any
- a Site remains unless a card says it is destroyed or conquered

---

## 15. Host Sigils

Host Sigils are capped at **1 total per deck**. fileciteturn4file2

### Canon master role
Host Sigils are persistent high-impact anchors. Because the consolidated reference preserves them as a family but does not fully specify common timing, the master rule is:
- a Host Sigil is deployed during Main unless a card says otherwise
- only one Host Sigil controlled by a player may be active at a time
- if a second would enter under the same player's control, the player must choose one to keep and the other is discarded

This is a normalization ruling.

---

## 16. Turn summary

A normal turn looks like this:
1. **Upkeep**: pay Oath upkeep and clear expiring upkeep-based effects
2. **Draw**: draw 1 card
3. **Edicts**: change Names, issue Edicts, manage legal pressure, gain Heat where appropriate
4. **Main**: deploy and prepare the board
5. **Battle**: fight deterministic combats
6. **Capture**: convert eligible downed/bound enemies into Marks
7. **End**: resolve cleanup and gain +1 Sinew / +1 Sigil / +1 Oath. fileciteturn4file1turn4file2

---

## 17. Implementation guardrails

If this master is used for the digital game, the following should be treated as non-negotiable:
- one canonical 7-phase enum
- one canonical combat resolver
- one normalized card/state contract
- separate persistent, derived, and transient state
- no duplicate rule engines in page code, bot code, and persistence code. fileciteturn4file13turn4file16turn4file10turn4file11turn4file12

These guardrails are consistent with the project’s own Base44 stabilization requirements. fileciteturn4file4turn4file10turn4file11turn4file12turn4file13turn4file16turn4file17turn4file18

---

## 18. Master reconciliation statement

This document intentionally prefers the **full canonical rules target** over the simpler current build whenever the build is clearly a reduced implementation. The current build remains useful as evidence for:
- the 7-phase structure
- visible Audit Heat ladder
- deployment categories
- end-step resource gain
- capture as a separate scoring phase. fileciteturn4file0turn4file2

The detailed combat system in this master is therefore a **completed canonical rules synthesis** built from the preserved combat skeleton and related preserved mechanics, with explicit rulings added where necessary so the game can be built and tested consistently. fileciteturn4file1turn4file2

---

# Section C — Procedural Rules Appendix

**Merged from:** `Kudurru_Kings_Rules_Appendix_v1_0.md`

# Kudurru Kings — Rules Appendix v1.0

## Purpose

This appendix supplies the procedural rules missing from the canonical master rules:
- zones
- targeting
- timing outside combat
- simultaneous effects
- state-based checks
- replacement / prevention handling
- rules glossary

This document is subordinate to the canonical master rules when a direct contradiction exists. Its function is to make the rules complete enough for content writing, QA, and implementation.

---

## 1. Zone model

Kudurru Kings uses the following canonical zones.

### 1.1 Deck
A player's hidden stack of legal cards used to draw during setup and Draw steps.

Rules:
- face down
- order hidden unless an effect reveals or searches it
- cards enter the deck only by setup, shuffle-back effects, or effects that explicitly place cards into deck

### 1.2 Hand
A player's hidden hand of cards.

Rules:
- hidden to opponents unless revealed by an effect
- there is no default hand-size discard rule

### 1.3 Field
The main public board area where Characters, Bosses, Pets, Sites, and other permanents exist.

Rules:
- organized by Fields and Lines
- occupancy may be shared unless a card says otherwise
- ready/exhausted and other board states are public

### 1.4 Law Row
Public zone for Names and long-form legal effects.

Rules:
- Names normally enter the Law Row unless a card explicitly says they enter another zone
- suppressed, corrupted, or seized Names remain in the Law Row unless an effect moves them elsewhere
- each Name has a controller and an owner

### 1.5 Relic Row
Public support zone for Relics and non-unit persistent support cards if not placed directly into a Field.

Rules:
- if a Relic references a Field, it is still considered to occupy the Relic Row unless it explicitly says it is attached or placed
- cards in the Relic Row are on the field for effect purposes only if their text says so

### 1.6 Host Sigil Slot
A dedicated public slot for Host Sigils.

Rules:
- each player may control only one active Host Sigil
- a Host Sigil occupies the Host Sigil Slot, not the Law Row or a Field, unless its card says otherwise

### 1.7 Discard
Public discard pile.

Rules:
- face up
- preserves order unless shuffled by an effect
- default destination for non-permanent one-shot cards after resolution, and for permanents that leave play without another specified destination

### 1.8 Exile
Public removed-from-play zone.

Rules:
- cards in Exile are not on the field, not in discard, and not captured
- effects must explicitly reference Exile to interact with exiled cards

### 1.9 Captured
Public zone for cards that have been captured and remain relevant after capture.

Rules:
- by default, captured non-Boss units leave play after scoring; however, a card or scenario may instead place them into the Captured zone
- cards in Captured are not on the field
- ownership does not change unless an effect explicitly changes ownership

### 1.10 Arbitration Staging
Short-lived public/hidden staging area used only during Arbitration resolution.

Rules:
- used for secret bids, witness commitments, and reveal ordering
- ceases to exist after the Arbitration finishes

### 1.11 Scenario Zone
Public zone for scenario modifiers, format cards, global laws, and match-wide effects.

Rules:
- cards/effects in the Scenario Zone are active for the whole match or for their stated duration
- scenario cards are not deck cards unless a format explicitly says so

---

## 2. Zone movement rules

Unless an effect says otherwise:
- played Edicts resolve, then go to Discard
- defeated or removed permanents go to Discard
- captured non-Boss units leave play after scoring and go to Discard
- exiled cards go to Exile
- seized Names remain in the Law Row but change controller
- suppressed Names remain in the Law Row with suppressed status
- corrupted Names remain in the Law Row with corrupted status

### Canon priority
If multiple destinations would apply, use this precedence:
1. explicit card text
2. replacement effect
3. canonical default destination

---

## 3. Targeting rules

### 3.1 Legal target
A legal target is an object, player, Field, Line, Name, or zone element that:
- matches the effect's target clause
- is targetable at the moment targets are locked
- is not prohibited by immunity, protection, suppression, or invalid relation

### 3.2 Target declaration timing
Targets are chosen:
- when the action or effect is declared, unless the effect explicitly says “choose on resolution”
- for combat, defender is chosen at combat declaration
- for Arbitration, the target Name is chosen at Arbitration declaration

### 3.3 Public vs hidden targets
- objects on the field, in Law Row, Relic Row, Host Sigil Slot, Discard, Exile, and Captured are public targets
- cards in hand and deck are hidden targets and may be chosen only if an effect explicitly allows hidden selection/search

### 3.4 Self-targeting
An effect may target its controller or source only if:
- it explicitly says “you,” “this,” “friendly,” “allied,” or equivalent, or
- the target clause is broad enough to include the source/controller

### 3.5 Allied targeting
In multiplayer, “ally” means a permanent or player you control, unless a format explicitly supports teams.

### 3.6 Multi-target ordering
If an effect has multiple targets:
1. all targets are chosen in printed order
2. legality is checked for all
3. if some but not all targets become illegal, resolve as much as possible to remaining legal targets unless the effect says “if all targets”
4. if all targets are illegal, the effect fizzles

### 3.7 Invalidated targets
If a target becomes illegal before resolution:
- that target is ignored
- the rest of the effect resolves if possible
- if the entire effect depended on that target, the effect fizzles

### 3.8 Retargeting
No default retarget rule exists. An effect may retarget only if it explicitly says so.

---

## 4. Timing framework

### 4.1 Timing classes
Kudurru Kings uses four speed classes.

**Phase Action**
- normal plays during the allowed phase
- most deployments and law plays

**Reaction**
- cannot be played freely unless text says so

**Interrupt**
- happens before a triggering event finishes resolving
- may alter legality, costs, or event structure

**Replacement**
- changes what would happen
- uses language like “instead,” “as,” or “would”

### 4.2 Default timing by family
- Character / Boss / Pet / Relic / Site / Host Sigil: Phase Action, usually Main
- Name / Edict: Phase Action, usually Edicts
- Reaction-tagged cards: Reaction
- Interrupt-tagged cards: Interrupt
- static laws / auras: always on while active

- after a Name is declared
- after an Edict is declared
- after a Field/Line effect triggers
- after an Arbitration is declared
- after an Audit check is declared
- after a capture target is declared


### 4.4 Simultaneous trigger ordering
If multiple triggers occur at the same time:
1. active player's mandatory triggers
2. non-active players' mandatory triggers in turn order
3. active player's optional triggers
4. non-active players' optional triggers in turn order

If two effects are still tied and no rule breaks the tie, the active player chooses the order.

### 4.5 Leaves-play timing
When a card leaves play:
1. continuous effects from that card stop
2. state-based checks occur
3. leave-play triggers are queued
4. destination is finalized
5. queued triggers resolve in normal order

---

## 5. State-based checks

State-based checks occur:
- after each effect resolves
- after each combat resolves
- after each consequence chain resolves
- after each Arbitration resolves
- before phase advancement
- whenever a rules layer explicitly says “check state”

### 5.1 State check list
On each check:
- units with 2+ Wounds become Downed
- units with illegal attachments lose those attachments
- units in illegal zones move to their last legal default destination
- units simultaneously Bound and not legally bindable lose Bound
- duplicate unique-persistent states are corrected
- illegal multiple Host Sigils are corrected
- invalid field-control markers are recalculated if needed

### 5.2 Simultaneous state changes
If multiple state changes occur at once:
- apply all mandatory state changes simultaneously
- then queue any resulting triggers

### 5.3 Re-entry
If a card leaves play and re-enters:
- it is treated as a new object
- it loses prior Wounds, Bound, Silence, and other non-persistent attachments unless a rule explicitly preserves them

---

## 6. Replacement and prevention rules

### 6.1 Replacement effects
A replacement effect changes what would happen.

Examples:
- “If this would be Wounded, Silence it instead.”
- “If this Name would be seized, suppress it instead.”

Rules:
- replacement applies before the original event finishes
- if multiple replacements compete, active player chooses among their effects first, then other players in turn order

### 6.2 Prevention effects
A prevention effect stops a consequence from occurring.

Examples:
- prevent 1 Wound
- prevent the next Heat gain
- prevent a Displace across this Line

Rules:
- prevention applies after legality but before final application
- prevented events count as attempted unless a card says they were not initiated

### 6.3 Cannot / must / may
- **cannot** overrides can
- **must** overrides may
- if two “must” effects conflict, follow the one with narrower scope; if still tied, active player chooses the order of attempted compliance

---

## 7. Multiplayer scope

### 7.1 Supported counts
Canonical support:
- 1-player solo support
- 2-player support
- 3-player support
- 4-player support

More than 4 simultaneous players is permitted only if gameplay remains viable after validation of pace, clarity, UI legibility, state readability, and performance.

### 7.2 Turn order
In multiplayer:
- play proceeds clockwise from a starting player
- turn order remains fixed unless a scenario changes it
- 2-player remains the primary balance baseline
- 3-player and 4-player are first-class supported modes

### 7.3 Field control in multiplayer
A player controls a Field if they alone have the highest number of ready primary units there at End. Otherwise it is contested.

### 7.4 Targeting in multiplayer
If a card says “opponent,” choose one opponent unless it says “each opponent.”
If a card says “enemy,” it means any object controlled by an opponent.

### 7.5 Arbitration in multiplayer
Arbitration targets one opponent's Name unless a card explicitly creates a wider dispute.

### 7.6 Simultaneous wins
1. finish the current resolution step
2. compare Marks
3. highest total wins
4. if tied, tied players continue only until the next Mark is earned

---

## 8. Rules glossary

**Active player**: the player whose turn it is.  
**Allied**: controlled by the same player unless a team format says otherwise.  
**Bind**: legally restrain a valid target under bind conditions.  
**Captured**: moved into a scored or captured state by a capture effect.  
**Challenge**: a successful or attempted conflict against a unit or Boss on a chosen axis.  
**Control**: the player currently using and governing the object.  
**Corrupt**: invert or degrade a Name so it functions as a penalty or twisted law.  
**Controller**: the player currently controlling an object.  
**Enters**: moves into a zone or play area from another zone.  
**Exhaust**: change from ready to committed/inactive until readied again.  
**First time each turn**: only the first qualifying event for that object/controller during a single turn counts.  
**Guardian relation**: the defined protective relation between a unit and a Site or named object.  
**If able**: do as much as possible; if impossible, ignore only the impossible part unless a rule says otherwise.  
**Initiate**: begin an action as its acting source.  
**Instead**: denotes a replacement effect.  
**Leaves play**: moves from field-facing public play into another zone.  
**Legal relation**: a board/zone/ownership relation permitted by the effect.  
**Owner**: the player whose deck or starting pool the card belongs to.  
**Primary participant**: the main attacker or defender in combat.  
**Seize**: take control of a valid target, most often a Name.  
**Suppress**: keep a law/object present but inactive.  
**Support card**: a non-primary card that assists or modifies other actions.  
**Support unit**: a ready unit committed as combat or arbitration support where permitted.  
**Trial**: one axis-specific successful challenge recorded against a Boss.  

---

## 9. Appendix rulings summary

Use these canonical defaults when no card text overrides them:
- Names live in the Law Row
- Host Sigils live in the Host Sigil Slot
- invalid targets are not retargeted by default
- state-based checks happen after every meaningful resolution
- replacement beats normal resolution
- cannot beats can
- 2-player rules are primary; 3–4 player rules are an extension

---

# Section D — Boss and Arbitration Appendix

**Merged from:** `Kudurru_Kings_Boss_And_Arbitration_Appendix_v1_0.md`

# Kudurru Kings — Boss and Arbitration Appendix v1.0

## Purpose

Bosses and Arbitration are deep enough to require their own edge-case appendix. This document defines:
- Boss stance timing
- Boss aura interaction
- Boss control and field edge cases
- trial failure and completion behavior
- detailed Arbitration edge cases
- Name state ownership under seizure / suppression / corruption

---

# Part I — Boss Appendix

## 1. Boss stance timing

### 1.1 Default timing
Unless a Boss card defines a custom stance system:
- enters play **Guarded**
- after first unique Trial gained: becomes **Ascendant**
- after second unique Trial gained: becomes **Wrathful**
- after third unique Trial gained: becomes **Exposed**

### 1.2 Mandatory or optional?
Default stance changes are mandatory. A custom Boss may override this only if it explicitly says a stance change is optional.

### 1.3 Timing point
Stance changes occur immediately after a new unique Trial is recorded, before post-trial retaliation fully resolves.

---

## 2. Multiple aura interaction rules

### 2.1 Default limit
A Boss projects one aura law by default.

### 2.2 Multiple auras
If a Boss somehow gains multiple aura sources:
- only one default aura may remain active unless a card explicitly says it can project additional auras
- if multiple auras are legal, controller chooses the active one whenever state is recalculated

### 2.3 Aura stacking
Two auras with the same name do not stack unless a card says otherwise.

---

## 3. Trial logic

### 3.1 Unique Trials
A Boss records only one Trial per axis:
- Stone
- Veil
- Oath

Multiple successful challenges on the same axis do not create additional Trial counters unless a specific Boss says so.

### 3.2 Trial failure outcomes
If a challenge against a Boss fails:
- no Trial is gained
- the Boss remains in current stance
- any “on failed challenge” boss text resolves if present

### 3.3 Trial-complete
A Boss is Trial-complete when it has all three unique Trial axes recorded.

Trial-complete means:
- it may now be Bound if otherwise legal
- it becomes eligible for any “on Exposed” or “on completion” logic
- it does not lose Trial-complete status unless a card explicitly removes Trials

---

## 4. Boss defeat, capture, suppression, control change

### 4.1 Defeat
A Boss is defeated only when a rule or card explicitly states defeat, or when a capture/finish rule resolves its removal after valid conditions are met.

Being Downed alone does not equal defeat.

### 4.2 Capture
A Boss may be captured only if:
- it is Trial-complete or a card explicitly bypasses Trial requirements
- it is Downed or otherwise capturable
- all relevant capture conditions are satisfied

### 4.3 Suppression
If a Boss is suppressed by a rare effect:
- its text is treated as inactive to the extent the suppressing effect says
- suppression does not remove Trial counters unless explicitly stated
- suppression does not count as defeat or capture

### 4.4 Control change
If a Boss changes controller:
- ownership stays with original owner
- controller-facing aura and stance effects now belong to the new controller
- Trial counters remain on the Boss
- default stance does not reset
- if the new controller already controls another Boss with a mutually exclusive rule, that rule must be reconciled during state-based checks

---

## 5. Bosses and Fields

### 5.1 Field control
Bosses count as primary units for Field control unless their card says otherwise.

### 5.2 Boss inherent field authority
Bosses do not inherently control Fields just by existing there. Field control still follows normal control rules unless a Boss explicitly states otherwise.

### 5.3 Raid-like boss objectives
A Boss may define raid-style objectives. Default template:
- while this Boss occupies a specified Field or relation, treat it as a raid objective
- if the objective is completed, apply printed reward/state change
- this does not replace normal Boss defeat/capture scoring unless stated

---

## 6. Boss edge-case rulings

- if a Boss leaves play and re-enters, it is a new object and loses prior stance/trial data unless preserved by text
- if a Boss becomes Exposed and then loses a Trial by effect, stance recalculates immediately
- if multiple players contribute to a Trial-gaining challenge in multiplayer, active player is treated as the challenger unless the effect says otherwise
- if a Boss would both be captured and leave play by another effect simultaneously, apply explicit card text first; otherwise capture takes precedence if declared in Capture phase

---

# Part II — Arbitration Appendix

## 7. Arbitration targeting rules

### 7.1 Target Name leaves before resolution
If the target Name leaves the Law Row before totals compare:
- the Arbitration fizzles
- bids already committed are still spent unless a card refunds them
- no Marks are awarded
- the aggressor does not gain default failure Heat unless the target was removed by the aggressor's own effect as part of the same action

### 7.2 Multiple Names
By default, Arbitration targets one Name only.
A card may allow multiple Name targets, but must explicitly define:
- target count
- bid sharing or separate bids
- how outcomes are chosen

### 7.3 Suppressed Names
A suppressed Name may still be targeted by Arbitration unless a card says suppressed Names are untargetable.

### 7.4 Corrupted Names
A corrupted Name may still be targeted by Arbitration unless a card explicitly forbids it.

### 7.5 Rewriting
A suppressed Name may be rewritten only if an effect says it may be rewritten while suppressed. Otherwise suppression must end first.
A corrupted Name may be rewritten normally unless an effect says it is locked.

---

## 8. Witnesses, precedent, injunctions

### 8.1 Witness visibility
Default rule:
- witness commitment is hidden until reveal unless a card says it must be public

### 8.2 Precedent token visibility
Precedent tokens are public information.

### 8.3 Injunction stacking
By default, injunctions do not stack on the same Name unless a card explicitly says they do.
If multiple injunctions would apply:
- the newest legal injunction replaces the older one unless an effect says both persist

### 8.4 Counter-claims
Only one counter-claim may be raised per Arbitration unless an effect explicitly permits more.

---

## 9. Arbitration outcome ownership

### 9.1 Seize
On seizure:
- controller changes
- owner does not change
- the Name remains in the Law Row
- ongoing effects now benefit or burden the new controller according to the Name text

### 9.2 Suppress
On suppression:
- controller does not change unless the suppressing effect says otherwise
- the Name remains in the Law Row
- suppressed state is public

### 9.3 Corrupt
On corruption:
- controller stays the same unless the effect says otherwise
- owner does not change
- corrupted state is public
- if a corrupted Name later changes controller, the corrupted state persists unless an effect cleanses it

---

## 10. Arbitration compare procedure details

Default sequence:
1. declare target Name
2. validate target
3. both players secretly set Oath bid
4. allow public modifiers
5. reveal bids
6. apply hidden witnesses
7. apply Precedent
8. apply counter-claims
9. compare totals
10. spend final bids
11. apply outcome
12. run state-based checks

Tie = defender wins.

---

## 11. Arbitration failure and cancellation

### 11.1 Failed Arbitration
If aggressor loses:
- target Name remains
- aggressor gains +1 Heat
- defender may gain 1 Precedent if they won by 2 or more

### 11.2 Canceled Arbitration
If an Arbitration is canceled before compare:
- if cancellation happened after bids were locked, bids are spent unless the canceling effect says otherwise
- if cancellation happened before bids locked, no bids are spent
- no outcome applies

---

## 12. Arbitration in multiplayer

- an Arbitration names one defending opponent by default
- no third player may join unless a card allows intervention
- if a third player may intervene, their role must be explicitly defined as witness, modifier source, or counter-claim source
- default defender-win-on-tie still applies

---

## 13. Appendix summary rulings

Use these defaults unless a card overrides them:
- Boss stance changes are mandatory
- one default Boss aura only
- Trial counters are unique by axis
- Bosses do not inherently own Fields
- one Name per Arbitration by default
- suppressed and corrupted Names remain targetable by default
- witnesses hidden until reveal by default
- Precedent public by default
- corruption persists through controller change unless cleansed

---

# Section E — Gameplay Dynamics Framework

**Merged from:** `Kudurru_Kings_Gameplay_Dynamics_Framework_v1_0.md`

# Kudurru Kings — Gameplay Dynamics Framework v1.0

## Purpose

This document defines the dynamic layer of Kudurru Kings: the part that determines pacing, tension, momentum swings, comeback pressure, and how matches feel across opening, midgame, and endgame.

This document does not replace the canonical rules, rules appendix, implementation spec, or schema. It sits above them and answers:
- how fast decks should feel
- what kinds of advantage matter most
- how advantage should convert into pressure
- how players recover when behind
- how matches escalate and close
- what level of interaction and interruption the game should sustain

Use this document for:
- gameplay balance
- card set planning
- archetype tuning
- scenario tuning
- QA expectations for match texture
- digital tuning targets

---

## 1. Core dynamic thesis

Kudurru Kings should feel like a law-war struggle that escalates through jurisdiction, pressure conversion, and controlled overreach.

The game should not feel like:
- flat resource trading
- passive setup for too many turns
- purely incremental attrition
- arbitrary blowouts
- inevitable snowball after one early lead

It should feel like:
- space and law becoming more dangerous over time
- pressure shifting from one subsystem into another
- players choosing between safer lines and greedier lines
- late-game states feeling more brittle and consequential than early-game states

---

## 2. Tempo model

Kudurru Kings uses three primary tempo bands.

### 2.1 Fast tempo
Fast decks seek to establish pressure early and convert board initiative into Marks before the opponent stabilizes.

Typical fast-tempo traits:
- low-cost Characters
- aggressive Line pressure
- early raid pressure
- efficient combat consequences
- light support density
- moderate heat usage, but not full Heat abuse

Fast deck goals:
- contest first meaningful Field
- threaten first Mark by turns 2–3
- force the opponent into defensive spending
- punish greedy Name setups

### 2.2 Midrange tempo
Midrange decks seek to establish credible board presence, pivot between combat and law, and dominate turns 4–6.

Typical midrange traits:
- efficient multi-axis units
- strong support layering
- balanced combat and arbitration options
- stable Field control
- moderate Boss access

Midrange deck goals:
- survive early tempo loss
- claim one subsystem lead by turn 4
- convert local advantage into multi-system pressure
- close through combat, capture, or controlled legal superiority

### 2.3 Control tempo
Control decks seek to slow volatility, absorb early pressure, manipulate Heat and Names, and win through arbitration, lockdown, or inevitable late-game dominance.

Typical control traits:
- high-value Names
- Heat management
- timing-sensitive Edicts
- reactive Relics
- late Bosses or decisive endgame control pieces

Control deck goals:
- neutralize early pressure
- keep Fields contested long enough to avoid snowball
- convert opponent overextension into Heat penalties or law loss
- win through inevitability, not speed

---

## 3. Match rhythm targets

### 3.1 Opening game: turns 1–3
The opening should answer:
- who establishes first board presence
- who claims first safe Field relation
- whether either player commits early Heat
- whether Sites or Names become immediate priorities

Opening targets:
- at least one meaningful tactical choice each turn
- first combat typically by turn 2 or 3
- first major law or site pressure by turn 2–4
- no consistent empty three-turn setup pattern

Opening should feel:
- tense
- information-building
- slightly unstable
- rich in inferred intent

### 3.2 Midgame: turns 4–6

Midgame should answer:
- what kind of advantage each player is actually building
- whether combat or law currently drives the match
- whether a Boss should enter
- whether arbitration is opening or closing

Midgame targets:
- most matches should pivot here
- first major momentum swing should commonly happen here
- Field control should matter the most here
- Heat pressure should become visibly consequential here
- one subsystem lead should begin converting into another

### 3.3 Endgame: turns 7+
The endgame should feel more brittle than the opening.

Endgame should answer:
- who is converting pressure best
- whether the trailing player can still force a final swing
- whether a legal, combat, or raid closer will decide the game

Endgame targets:
- score pressure should be visible
- stall must become more difficult
- endgame should not usually last more than 2–4 turns after a decisive lead is established

---

## 4. Action economy philosophy

### 4.1 Meaningful-action target
A typical turn should produce 2–4 meaningful decisions depending on archetype and board state.

Examples of meaningful decisions:
- which subsystem to invest in
- whether to spend or bank Heat
- whether to deploy or hold support
- whether to open combat or arbitration
- whether to secure economy or push scoring pressure

### 4.2 Compression ceiling
No ordinary non-combo turn should:
- deploy too many threats
- flip multiple subsystems simultaneously
- erase the opponent’s last two turns of progress without prior setup

Canonical swing ceiling:
- a single ordinary turn may produce one major swing and one minor follow-up, but not multiple unrelated major swings unless a scenario or signature card explicitly enables it

### 4.3 High-efficiency play
A turn is high-efficiency when it:
- advances one subsystem directly
- prepares a second subsystem indirectly
- does not overexpose the player to obvious punishment

Examples:
- win combat and set up capture
- install a Name while defending a Field
- defend Arbitration while banking Heat for next turn

---

## 5. Pressure conversion map

Kudurru Kings is strongest when advantages convert cleanly.

### 5.1 Core conversion rules

#### Combat pressure -> Capture pressure
The primary output of combat should usually be:
- Wounds
- displacement into bad relations
- Silence on key units
- eventual Capture

Combat should only rarely score directly without passing through Capture, Raid, or explicit card text.

#### Field control -> Economy and tactical leverage
Field control should convert into:
- resource efficiency
- consequence advantage
- safer movement
- raid access
- arbitration posture

Field control should not directly grant too many raw Marks by default.

#### Heat pressure -> Legal openings and tactical liability
Heat should convert into:
- vulnerability to Edicts
- worse Arbitration posture
- harder multi-system turns
- forced discard or weaker legal sequencing
- specific punishments at thresholds

Heat should only convert directly into Marks through strong but narrow cards or threshold punishments.

#### Trial pressure -> Boss vulnerability
Trial progress should convert into:
- wider consequence legality
- capture access
- weakened aura protection

#### Resource edge -> Tempo and flexibility
Resource advantage should mostly convert into:
- stronger reactions
- more consistent subsystem pivoting

It should not automatically invalidate a stronger board or stronger law posture.

### 5.2 Illegal or unhealthy conversions
Avoid allowing:
- trivial Heat-to-Marks conversion
- automatic Field-control-to-Marks conversion
- low-risk Boss deployment turning directly into guaranteed scoring
- passive Names that both lock the board and create reliable scoring without contest

---

## 6. Comeback and anti-snowball structure

### 6.1 Design principle
Trailing players should have earned comeback lines, not free equality.

### 6.2 Canon comeback levers

#### A. Contested Field rebound
If a player starts End controlling zero Fields while an opponent controls two or more:
- the trailing player gains one contested rebound effect at the start of their next Main:
  - either +1 Sigil
  - or the first legal retreat/displace they control that turn ignores one Geas
This effect does not stack.

#### B. Behind-on-Marks tension lane
If a player is behind by 3 or more Marks:
- the first time each turn they successfully defend Arbitration or prevent a capture, they may remove 1 Audit Heat or draw 1 then discard 1

#### C. Overextension penalty
If a leading player begins Battle while:
- controlling more Fields
- leading in Marks
- and having lower Audit Heat than the opponent
then the trailing player gains +1 to the first defensive Arbitration or reactive legal effect they perform that turn

This is intentionally narrow; it creates counter-pressure without invalidating the lead.

### 6.3 Snowball caps
The game should resist:
- stable multi-turn lockouts
- repeated zero-risk scoring lines

### 6.4 Catch-up without humiliation
Comeback tools should:
- create counterplay
- improve decision quality

They should not:
- gift free Marks
- hard-reset the board
- erase earned structure without cost

---

## 7. Risk ladders

### 7.1 Global risk
Audit Heat remains the primary explicit global risk engine.

### 7.2 Local risk ladders

#### Site risk
Safe line:
- play Site for setup or economy

Greedy line:
- play Site early in exposed board states to force raid race or field commitment

#### Boss risk
Safe line:
- deploy Boss after at least one subsystem is already stabilized

Greedy line:
- deploy Boss early to force tempo collapse or pressure conversion

#### Host Sigil risk
Safe line:
- use Host Sigil to stabilize or protect a score lead

Greedy line:
- use Host Sigil as a swing extension when the board is still unstable

#### Relic investment risk
Safe line:
- play Relic onto stable units or known combat lines

Greedy line:
- overinvest in a unit vulnerable to Silence, Displace, or capture sequencing

### 7.3 Archetype risk ceilings
Fast decks:
- should risk board collapse if they fail to convert early pressure

Midrange decks:
- should risk losing to stronger specialization if they stay too generic too long

Control decks:
- should risk falling behind on Marks if they spend too long only denying

Heat decks:
- should risk self-destruction if they misjudge threshold timing

Boss decks:
- should risk tempo loss if their elite piece enters without support

---

## 8. Interaction density

### 8.1 Target interaction feel
Each turn should feel interactive enough that opponents can matter, but not so reactive that turns become stalled.

Healthy interaction density:
- players should disrupt or threaten each other often
- but not every action should provoke mandatory response calculus

### 8.2 Card-pool interaction target
At the full card-pool level:
- roughly 30–40% of cards should create direct counterplay, interruption, or denial
- roughly 40–50% should be proactive development or payoff
- the remainder should be glue, economy, or support conversion

### 8.3 Turn interruption ceiling
A standard turn should rarely involve:
- more than 1 major off-turn intervention by each opponent
- more than 1 default reaction stack in one subsystem unless cards explicitly create it

---

## 9. Card-family dynamic identities

### 9.1 Character
Dynamic role:
- primary tempo carriers
- battlefield pressure and score conversion engines

### 9.2 Boss
Dynamic role:
- volatility amplifiers
- subsystem warpers
- endgame or pivot threats

### 9.3 Pet
Dynamic role:
- efficiency enhancers
- tactical precision tools
- low-board-space upgrades

### 9.4 Relic
Dynamic role:
- persistence and conversion tools

### 9.5 Name
Dynamic role:
- law pressure
- match-shape modifier
- strategic distortion tool

### 9.6 Edict
Dynamic role:
- corrective force
- timing punish
- clean legal intervention

### 9.7 Site
Dynamic role:
- place-based opportunity and scoring leverage

### 9.8 Host Sigil
Dynamic role:
- mythic swing tool
- stabilizer or closer
- identity spike

---

## 10. Archetype ecosystem targets

### 10.1 Supported core archetypes
- Battle Attrition
- Arbitration Control
- Site Raid
- Bind/Capture
- Audit Punishment

### 10.2 Ecosystem goals
Each archetype should:
- prey on at least one archetype
- be weak to at least one archetype
- have one signature subsystem
- have one fallback subsystem
- possess a clear opening, midgame, and closing identity

### 10.3 Target matchup logic
Battle Attrition
- strong vs fragile setup decks
- weak vs pure legal denial if combat cannot stick

Arbitration Control
- strong vs slow Name-reliant decks
- weak vs fast board pressure and raid pressure

Site Raid
- strong vs decks that concede space
- weak vs displacement traps and strong local defense

Bind/Capture
- strong vs unit-heavy midrange
- weak vs dispersal, cleanse, and anti-bind lines

Audit Punishment
- strong vs greedy Heat and law manipulation decks
- weak vs low-Heat battlefield tempo if it never gets legal leverage

---

## 11. Match texture by stage

### 11.1 Opening texture
Desired feelings:
- uncertainty
- probing
- posture testing
- asymmetric setup

### 11.2 Midgame texture
Desired feelings:
- legal danger
- tactical branching
- subsystem collision
- meaningful overextension risk

### 11.3 Endgame texture
Desired feelings:
- fragility
- inevitability pressure
- one more opening decides it
- hard trade-offs between safety and closure

### 11.4 Stabilized board
A stabilized board is one where:
- both players can defend at least one subsystem
- no immediate score conversion is forced
- action quality still matters

### 11.5 Collapsing board
A collapsing board is one where:
- one subsystem failure opens at least one more
- capture or law loss becomes immediate
- defenders must choose which pressure source to respect

---

## 12. Closer patterns

The game should close through one of these patterns most often:
- capture closer
- raid closer
- arbitration closer
- boss closer
- heat closer

No single closer type should dominate the entire ecosystem.

---

## 13. Stall breakers

If a match stalls, the game should naturally push it forward.

Canonical stall breakers:
- rising Heat pressure through repeated support and Name use
- Field control economy
- raid opportunities
- Boss exposure through Trials
- endgame closer cards
- scenario modifiers

Optional format rule:
If no Marks change for two full rounds, the game enters Escalation:
- all Arbitration totals gain +1
- first successful combat each turn gains +1 on chosen axis
- audit penalties worsen by one step where applicable

---

## 14. Balance targets

### 14.1 Scoring pace
Standard match:
- first Mark commonly appears by turns 3–5
- decisive lead commonly established by turns 6–8
- most matches end before deep attrition exhaustion

### 14.2 Boss pacing
Bosses should usually:
- appear after a player has established at least partial subsystem footing
- matter immediately
- not end the game solely by entering

### 14.3 Name pacing
Names should feel:
- strong enough to matter
- risky enough to think about
- interactable enough not to feel oppressive

### 14.4 Swing tolerance
A healthy swing:
- changes one subsystem decisively
- pressures a second subsystem

An unhealthy swing:
- solves combat, law, space, economy, and score all at once without prior setup

---

## 15. Final doctrine

Kudurru Kings should create games where:
- systems are legible
- pressure escalates
- players are rewarded for conversion, not just possession
- behind players still have agency
- ahead players still have to close cleanly
- the final turns feel earned rather than automatic

---

# Section F — Archetype Matrix

**Merged from:** `Kudurru_Kings_Archetype_Matrix_v1_0.md`

# Kudurru Kings — Archetype Matrix v1.0

## Purpose

This document operationalizes the core Kudurru Kings archetypes. It defines:
- core game plans
- subsystem priorities
- pressure profiles
- opening / midgame / endgame identity
- prey / predator relationships
- dynamic weaknesses
- tuning targets

This is a balance and set-design document, not a player primer.

---

## 1. Core ecosystem rule

Every supported archetype must:
- have one primary win lane
- have one secondary win lane
- create at least one pressure type the opponent must respect
- be vulnerable to at least one clean counter-style
- make distinct mulligan and sequencing decisions

---

## 2. Archetype list

Canonical core archetypes:
1. Battle Attrition
2. Arbitration Control
3. Site Raid
4. Bind / Capture
5. Audit Punishment

Optional hybrid archetypes may exist, but they should derive from these five rather than bypass them.

---

## 3. Archetype profiles

## 3.1 Battle Attrition

### Core identity
Win by forcing efficient combats, accumulating Wounds, exhausting enemy defenders, and turning battlefield dominance into captures or score pressure.

### Primary subsystem
Combat

### Secondary subsystem
Field control

### Pressure profile
- early board pressure
- repeated small wins
- high local combat density
- modest Heat exposure

### Opening goals
- deploy efficient Characters
- claim first safe battle posture
- deny free Site establishment
- force opponent to spend inefficiently

### Midgame goals
- convert Wounds into capture threat
- hold at least one important Field
- punish weak defenders and stretched resources

### Endgame goals
- close with capture chains
- protect score lead through superior board state
- use minimal law pressure only if needed

### Typical strengths
- punishes slow setup
- forces immediate respect
- makes raw card quality matter less than tactical play

### Typical weaknesses
- vulnerable to strong Silence / legal denial
- may overcommit into Heat if support-heavy
- can stall if it fails to convert Wounds

### Preys on
- greedy Name engines
- fragile tempo-combo setups
- low-board control shells

### Loses to
- clean legal shutdown
- evasive raid pressure if it cannot anchor space
- heavy anti-combat displacement

---

## 3.2 Arbitration Control

### Core identity
Win by controlling the law layer, disrupting opponent Names, winning Oath bids, and converting legal dominance into score or board suppression.

### Primary subsystem
Arbitration / Names

### Secondary subsystem
Audit Heat manipulation

### Pressure profile
- low immediate board force
- high denial
- delayed inevitability
- medium to high interaction density

### Opening goals
- survive first board swings
- establish safe legal footing
- keep Heat manageable
- deny explosive enemy law starts

### Midgame goals
- seize or suppress key Names
- control Heat thresholds
- force the opponent into bad sequencing

### Endgame goals
- close through Name seizure, legal lock, or Heat-triggered collapse
- prevent comeback lines through precision denial

### Typical strengths
- dominates extended subsystem wars
- punishes overreach
- converts opponent greed into self-destruction

### Typical weaknesses
- vulnerable to early board tempo
- can fall behind on Marks if too reactive
- may fail if it never secures a closer

### Preys on
- slow high-Heat archetypes
- Name-reliant mirrors that lose bid efficiency
- Boss decks that require long setup

### Loses to
- fast pressure with low Heat footprint
- raid decks that score around the law layer
- decisive multi-threat battle openings

---

## 3.3 Site Raid

### Core identity
Win by turning Fields and Sites into contested scoring engines, forcing movement decisions, and exploiting spatial neglect.

### Primary subsystem
Site / Field control

### Secondary subsystem
Displacement / raid timing

### Pressure profile
- positional threat
- moderate combat
- low-to-medium Heat usage

### Opening goals
- establish or contest the first valuable Site
- create movement pressure
- force opponents to defend geography, not just stats

### Midgame goals
- use Fields to shape legal and tactical lines
- turn displacement into raid openings
- force awkward defender splits

### Endgame goals
- convert control state into protected score

### Typical strengths
- punishes players who ignore space
- can score without winning repeated attrition fights
- pressures slow legal decks indirectly

### Typical weaknesses
- vulnerable to high local defense
- struggles if Fields are repeatedly neutralized

### Preys on
- stationary control decks
- decks that concede Sites for card advantage
- overly linear combat lists

### Loses to
- displacement traps
- powerful local boss anchors
- heavy Sanctuary defensive shells

---

## 3.4 Bind / Capture

### Core identity
Win by Downing units, securing bind conditions, and converting battlefield advantage into direct score through capture.

### Primary subsystem
Capture

### Secondary subsystem
Oath combat and bind setup

### Pressure profile
- tactical sequencing
- deliberate conversion
- medium Heat exposure

### Opening goals
- establish units that can produce clean bind lines
- test the opponent’s anti-bind tools
- threaten future capture, not just immediate damage

### Midgame goals
- create Downed states across multiple lanes
- pressure Oath lines
- force the opponent to choose which targets to save

### Endgame goals
- capture 1–2 key pieces cleanly
- close through score spikes rather than slow attrition

### Typical strengths
- strongest pressure conversion into Marks
- punishes wounded and overextended boards
- dangerous in collapsing-board states

### Typical weaknesses
- weak if it cannot secure bind legality
- vulnerable to cleanse, mobility, and legal denial
- may overinvest in partial setup with no capture finish

### Preys on
- unit-heavy midrange
- boss-light battlefield decks
- players who spend too much to keep one unit alive

### Loses to
- evasive or low-board law shells
- anti-bind tech
- high mobility threshold decks

---

## 3.5 Audit Punishment

### Core identity
Win by turning opponent Heat and legal greed into active liabilities, then converting threshold pressure into score, tempo collapse, or legal shutdown.

### Primary subsystem
Audit Heat

### Secondary subsystem
Edicts / law punishment

### Pressure profile
- indirect threat
- punishment posture
- medium board presence
- asymmetric risk leverage

### Opening goals
- keep own Heat clean
- identify greedy opponent lines
- set up threshold punish tools

### Midgame goals
- force opponent to cross painful thresholds
- punish support-heavy or Name-heavy turns
- tax legal ambition

### Endgame goals
- close through failed audits, Heat-enhanced consequences, or denied recovery
- turn desperation turns into self-damage

### Typical strengths
- strongest anti-greed posture
- attacks player behavior, not just board state
- excellent against combo-like pressure engines

### Typical weaknesses
- weak if opponent stays clean and proactive
- may lack direct closing force
- can become too passive if punishment never lands

### Preys on
- Heat banking decks
- law-heavy control
- support-dense battle engines

### Loses to
- low-Heat pressure decks
- fast score lines that finish before thresholds matter
- broad board tempo that ignores legal risk

---

## 4. Ecosystem interaction matrix

### General target relationships
- Battle Attrition pressures Arbitration Control and soft Raid lists
- Arbitration Control pressures Audit Punishment mirrors and greedy Name shells, and can outlast Boss-heavy control
- Site Raid pressures Control decks that concede geography
- Bind / Capture pressures unit-dense boards and attrition mirrors
- Audit Punishment pressures Heat-greedy legal and support decks

### Balance doctrine
No archetype should:
- dominate all openers
- dominate all endgames
- score and deny at top efficiency simultaneously
- have no bad matchup

---

## 5. Stage-by-stage expectations

### Turns 1–3
- Battle Attrition should look strongest on board
- Raid should look strongest in positional setup
- Arbitration Control should look weakest on visible board but strongest in latent denial
- Bind/Capture should look threatening, not yet decisive
- Audit Punishment should look patient, not inert

### Turns 4–6
- Battle Attrition should either convert or begin to lose inevitability
- Arbitration Control should come online here
- Bind/Capture should begin creating true checkmate-style threats
- Audit Punishment should begin making Heat choices painful

### Turn 7+
- each archetype should still have a closer
- none should rely only on do more of the same
- endgame should expose the weakness of overcommitting to one subsystem too early

---

## 6. Archetype tuning metrics

### Battle Attrition
- highest early board contest rate
- moderate Heat accumulation
- strong but not automatic conversion to score

### Arbitration Control
- highest Name interaction rate
- strongest Oath-bid leverage
- medium-low early Marks, stronger late inevitability

### Site Raid
- highest Field-control and raid declaration rate
- moderate combat density

### Bind/Capture
- highest capture threat conversion
- strongest punishment of Downed states
- moderate dependency on combat setup

### Audit Punishment
- highest threshold-punish trigger rate
- strong anti-greed effect
- lower direct scoring unless opponent overreaches

---

## 7. Hybrid archetypes

Allowed hybrids:
- Attrition / Capture
- Raid / Arbitration
- Heat / Arbitration
- Boss Midrange / Field Control

Hybrid rule:
A hybrid must still clearly declare:
- its primary lane
- its fallback lane
- its actual closer

Do not let hybrid mean good at everything.

---

## 8. Failure modes to watch

### Battle Attrition failure
- too much raw efficiency
- makes other systems irrelevant

### Arbitration Control failure
- over-locking and stall generation

### Site Raid failure
- noninteractive race patterns
- free scoring from passive Site presence

### Bind/Capture failure
- over-reliable capture from too little setup
- makes Wounds functionally equal to score

### Audit Punishment failure
- punishes ordinary play too hard
- turns Heat into a trap mechanic rather than a risk engine

---

## 9. Final doctrine

The archetype ecosystem is healthy when:
- each lane feels real
- each lane can win
- each lane has fear targets and nightmare matchups
- match flow changes depending on archetype collision
- what kind of game this is becomes clear by the middle turns

---

# Section G — Faction Dynamics

**Merged from:** `Kudurru_Kings_Faction_Dynamics_v1_0.md`

# Kudurru Kings — Faction Dynamics v1.0

## Purpose

This document turns faction direction into concrete gameplay dynamics. It defines:
- how each faction feels to pilot
- what subsystem each faction bends hardest
- its default opening / midgame / endgame behavior
- matchup expectations
- mulligan priorities
- dynamic weaknesses

This document does not define final lore taxonomy or final card lists. It defines faction play rhythm.

---

## 1. Faction doctrine rule

A faction should not merely have flavor. A faction must change:
- what the player values early
- which subsystem they try to dominate
- how they absorb risk
- how they close games

No faction should be generic good cards with a different skin.

---

## 2. Canon faction dynamics set

This document operationalizes the previously approved direction that factions should differ through:
- field dominance
- heat exploitation
- veil specialization
- oath-bid manipulation
- displacement and line traps

To make that concrete, use the following dynamic faction set.

---

## 3. Faction profiles

## 3.1 Borderstone Guild — Field Dominion

### Core dynamic
Turns geography into leverage. Best at stable Field control, safe value, and territorial pressure.

### Signature systems
- Fields
- Sites
- local combat bonuses
- lawful structural play

### Opening behavior
- prioritize Sites and durable Characters
- secure one reliable Field early
- avoid reckless Heat lines

### Midgame behavior
- turn Field control into resource and tactical leverage
- force the opponent to cross bad Lines
- pressure raid denial and position-based combat

### Endgame behavior
- close through territory plus efficient capture or raid
- create a game state where the opponent must attack into worse relations

### Mulligan priorities
- 1 Site or stable Field enabler
- 1 durable Character
- 1 support piece that improves local control

### Strengths
- consistent board rhythm
- strong anti-chaos posture
- reliable conversion of space into value

### Weaknesses
- less explosive than heat-greedy factions
- vulnerable to hard legal distortion if it cannot keep space stable

### Dynamic fantasy
You fight on my terms, or you fight badly.

---

## 3.2 Floodborn Pact — Veil Mobility

### Core dynamic
Wins by misdirection, Silence, fluid positioning, and evasive pressure.

### Signature systems
- Veil combat
- displacement
- hidden or deceptive posture
- soft denial

### Opening behavior
- establish light board with evasive pressure
- threaten first awkward combat
- avoid hard commitment too early

### Midgame behavior
- distort support math
- force bad target choices
- use movement and Veil wins to break stability

### Endgame behavior
- close through selective collapse
- disable one key piece, then score before the opponent recovers

### Mulligan priorities
- Veil-positive opener
- one flexible support card
- one card that reshapes combat or movement

### Strengths
- strong tactical finesse
- excellent at making strong enemy cards matter less
- strong anti-midrange posture

### Weaknesses
- can fail if pressure never converts
- vulnerable to solid local defenses and anti-movement shells

### Dynamic fantasy
You never lose where you’re strongest; you make strength miss.

---

## 3.3 Skyloom Temple — Oath Adjudication

### Core dynamic
Dominates Oath, legal sequencing, and formal challenge structure.

### Signature systems
- Arbitration
- Oath combat
- law timing
- sanction-based control

### Opening behavior
- stabilize
- protect legal footing
- avoid overcommitting to visible board unless necessary

### Midgame behavior
- win critical Arbitrations
- force the opponent into legal asymmetry
- shape the match through the law layer

### Endgame behavior
- close through legal inevitability, seizure, and denied recovery
- make the opponent’s remaining threats illegal, expensive, or too late

### Mulligan priorities
- at least one law-facing card
- resource consistency
- one answer to early board pressure

### Strengths
- best Oath-bid identity
- strongest law-shaping tools
- excellent against greedy engines

### Weaknesses
- vulnerable to fast scoring pressure
- can be overrun if it misses stabilization

### Dynamic fantasy
You may act, but only under judgment.

---

## 3.4 Underwell Keepers — Capture and Grave Pressure

### Core dynamic
Thrives on weakened states, Downed bodies, and irreversible punishment.

### Signature systems
- capture
- bind
- attrition finishing
- post-conflict exploitation

### Opening behavior
- establish one or two sticky threats
- begin soft Wound pressure
- test whether the opponent can avoid vulnerable states

### Midgame behavior
- create multi-target capture tension
- turn one local failure into cascading fear

### Endgame behavior
- close through capture spikes
- make every surviving body feel unsafe

### Mulligan priorities
- one efficient attacker
- one bind enabler
- one card that punishes wounded or exhausted units

### Strengths
- best at converting partial damage into score
- punishes sloppy stabilization
- dangerous in collapsing-board states

### Weaknesses
- struggles versus low-board or evasive legal shells
- can fail if the opponent constantly resets relation quality

### Dynamic fantasy
If you are weakened, you are already halfway mine.

---

## 3.5 Fateforge — Heat and Risk Engineering

### Core dynamic
Turns calculated overreach into power. Best at Heat banking, threshold play, and dangerous tactical spikes.

### Signature systems
- Audit Heat
- cost-risk conversion
- sharp tactical amplification
- dangerous legal overreach

### Opening behavior
- stay just under pain thresholds when possible
- set up Heat-positive opportunities
- tempt the opponent into thinking the board is stable

### Midgame behavior
- convert Heat into reach, consequence upgrades, or legal pressure
- create turns where risk itself becomes tempo

### Endgame behavior
- close through explosive, dangerous swings
- risk self-damage for decisive advantage

### Mulligan priorities
- one safe stabilizer
- one Heat converter
- one payoff or threshold tool

### Strengths
- strongest greed lines
- can steal games from parity

### Weaknesses
- can self-destruct
- vulnerable to dedicated Audit Punishment or clean low-Heat pressure

### Dynamic fantasy
I break the law better than you can punish it.

---

## 4. Matchup expectations

### Borderstone Guild
- strong into Raid mirrors and anti-chaos matchups
- weak into heavy law distortion if it cannot keep territory stable

### Floodborn Pact
- strong into clumsy midrange and local-defense decks
- weak into clean Oath control and anti-movement lockdown

### Skyloom Temple
- strong into greedy law and Heat strategies
- weak into fast board-first tempo

### Underwell Keepers
- strong into unit-dense strategies
- weak into evasive or sparse-board control

### Fateforge
- strong into slow inevitability decks it can out-spike
- weak into precise punishment or fast no-nonsense tempo

---

## 5. Faction mulligan doctrine

Each faction should change mulligan behavior.

### Borderstone Guild
Keep:
- Field setup
- durable bodies
- stable support

### Floodborn Pact
Keep:
- mobility
- Veil-positive units
- tactical flexibility

### Skyloom Temple
Keep:
- law interaction
- defense against tempo
- Oath consistency

### Underwell Keepers
Keep:
- early body pressure
- bind lines
- exploit finishers

### Fateforge
Keep:
- safe opener plus one greed tool
- avoid hands that are all payoff and no stability

---

## 6. Faction balance doctrine

Each faction should:
- win through its preferred subsystem more often than others
- still be able to pivot
- have a recognizable weakness
- create different opening and endgame patterns

Do not balance factions by making everyone equally good at everything.

---

## 7. Dynamic guardrails

### Borderstone Guild
Do not let it become pure statball.

### Floodborn Pact
Do not let it become untouchable disruption with no finish problem.

### Skyloom Temple
Do not let it hard-lock too often.

### Underwell Keepers
Do not let every wound become inevitable capture.

### Fateforge
Do not let Heat conversion become mathematically mandatory every game.

---

## 8. Final doctrine

A player should be able to identify a faction by feel within the first two turns:
- what it values
- what it threatens
- what it fears
- how it intends to win

---

# Section H — Endgame and Comeback Rules

**Merged from:** `Kudurru_Kings_Endgame_and_Comeback_Rules_v1_0.md`

# Kudurru Kings — Endgame and Comeback Rules v1.0

## Purpose

This document formalizes:
- anti-snowball rules
- endgame escalation
- stall breakers
- closer patterns

It ensures the game remains skillful while preventing early subsystem leads from becoming inevitability too quickly.

---

## 1. Design principle

A lead should matter.
A lead should not become automatic victory.
A comeback should be possible.
A comeback should not be free.

---

## 2. Endgame definition

A match is in endgame state when any one of the following is true:
- a player is within 2 Marks of the victory threshold
- a Boss is Trial-complete and still active
- one player controls two Fields and leads in Marks
- one player is Lawbroke Candidate and the opponent has a valid score line
- no Marks have changed for two full rounds

When endgame state begins:
- place an Endgame marker
- both players are considered to know the match is entering closure pressure

---


If a player is behind by 3 or more Marks:
- once on their next turn, they may choose one:
  - gain +1 Sigil
  - remove 1 Audit Heat
  - the first defender-side supporter they commit this turn adds +1 extra on the chosen axis

This does not stack turn-to-turn.

If a player starts their turn controlling zero Fields while an opponent controls two or more:
- their first legal movement, retreat, or displacement escape this turn may ignore one Geas

If a player is behind in Marks and loses an Arbitration by 1 or less, they may:
- gain 1 Precedent token
or
- remove 1 Heat

This preserves law agency for the trailing player.

---

## 4. Anti-snowball rules

### 4.1 Layered lead check
If a player simultaneously:
- leads in Marks
- controls more Fields
- and has lower Audit Heat
then they are considered to have stacked advantage.

While a player has stacked advantage:
- the opponent's first successful reactive legal effect each turn gains +1 strength if numeric, or +1 duration step if duration-based and variable
- this bonus applies only once each turn

### 4.2 No free cascade scoring
Unless a card explicitly says otherwise:
- one successful score event may not automatically trigger another score event from the same action chain

This prevents one tactical success from becoming multiple free Marks without additional setup.

### 4.3 Board lock caution
If a player begins three consecutive turns with:
- more ready units
- more Fields
- and more Marks
then the trailing player gains Last Appeal on their next turn:
- the first Arbitration they declare costs 1 less Oath
or
- the first Site raid they declare gains +1 on the primary relevant axis

This effect does not stack.

---

## 5. Endgame escalation

If the match enters endgame state, apply the following:

### 5.1 Escalation round counter
At the start of each full round in endgame, increase the Escalation counter by 1.

### 5.2 Escalation effects
**Escalation 1**
- no automatic effect; endgame is now active

**Escalation 2**
- first successful combat each turn gains +1 on the chosen axis

**Escalation 3**
- first Arbitration each turn gains +1 total to both sides after bids are revealed

**Escalation 4**
- if no Marks change this round, both players gain +1 Heat at End

**Escalation 5+**
- first time each turn a player fails to convert an eligible capture or raid into score, they gain +1 Heat

This is intentionally harsh. Deep stalls should not persist.

---

## 6. Stall breakers

### 6.1 Passive stall detection
A stall exists if:
- no Marks change for two full rounds
- no Boss gains a new Trial
- no Name changes controller, state, or suppression condition

If a stall exists, apply endgame escalation immediately if not already active.

### 6.2 Active stall breakers
The game should naturally break stalls through:
- support-generated Heat
- Field control economy
- Trials on Bosses
- Arbitration pressure
- closer cards

### 6.3 Optional hard anti-stall mode
Formats may enable Court Collapse:
- after Escalation 4, if another full round passes with no score change, the player with fewer total active subsystem advantages loses ties on all compares until Marks change

Subsystem advantages:
- higher Marks
- more controlled Fields
- lower Heat
- more active Names
- more ready primary units

---

## 7. Closer patterns

The game should close through one of the following patterns.

### 7.1 Capture closer
- repeated combat pressure
- a unit becomes Downed
- bind or capture line is secured
- Marks convert decisively

### 7.2 Raid closer
- defender is forced to respect the wrong relation
- Site converts into final scoring

### 7.3 Arbitration closer
- one Name changes state or controller
- law layer collapses
- score or legal lock follows immediately

### 7.4 Boss closer
- Boss survives to reshape the board
- Trial timing is mismanaged
- opponent loses their final safe line

### 7.5 Heat closer
- threshold pressure finally lands
- opponent cannot both stabilize and remain lawful
- punishments convert into final opening

No closer type should own more than the entire late game.

---

## 8. Emergency losing-player agency

If a player begins their turn both:
- behind by 4 or more Marks
- and at risk of lethal scoring next round
they gain Desperate Petition once that turn:

Choose one:
- first Edict this turn costs 1 less Sigil
- first defender-side reaction this turn gains +1 numeric value where relevant
- first legal capture prevention this turn ignores one Heat rider

This is not enough to fully reset a losing board. It is enough to create a real final decision.

---

## 9. Endgame board-state guidance

### Healthy endgame states
- both players still have at least one real line
- one player is ahead, but closure is not yet automatic
- score, law, and space all matter

### Unhealthy endgame states
- only one subsystem matters and it is already unwinnable
- the losing player cannot create any meaningful branch
- closure is delayed for many turns despite decisive advantage

---

## 10. Score pacing rules

Target endgame pacing:
- once a player reaches within 2 Marks of victory, the match should usually end within 1–3 full rounds
- once a player hits Lawbroke Candidate under pressure, the game should feel close to breaking open

---

## 11. QA expectations

QA should verify:
- behind-on-Marks bonuses create decisions, not free equalization
- stacked-advantage checks stop runaway certainty without making leads feel fake
- Escalation meaningfully accelerates stalled matches
- closer patterns remain varied across archetypes
- final turns feel tense, not procedural

---

## 12. Final doctrine

A good Kudurru Kings endgame should feel like:
- the table tightening
- law becoming harsher
- space becoming more dangerous
- every commitment mattering more
- the losing player still having one last real chance
- the winning player still needing to execute cleanly

---

# Section I — Shipping Canon Addendum v1.0

## Purpose

This section updates the finalized gameplay doctrine with explicit shipping-level canon that was previously identified as remaining product-definition work.

## I.1 Official multiplayer shipping stance

Multiplayer is now canonically a full shipping feature for:
- 1 player
- 2 players
- 3 players
- 4 players

More than 4 simultaneous players is permitted only if gameplay permits after validation of:
- rules clarity
- pace and match quality
- UI legibility
- state readability
- system performance
- deterministic resolution integrity

### Multiplayer shipping doctrine
- 2-player remains the primary balance baseline
- 1-player, 3-player, and 4-player are first-class supported shipping modes
- all core systems must work in multiplayer:
  - combat
  - capture
  - arbitration
  - field control
  - boss trials
  - audit heat
  - endgame escalation
- multiplayer support is not optional-only product scope anymore

## I.2 Canon shipping gaps

The following are now recognized as official remaining shipping gaps:

### A. Card-by-card content completion
The schema exists, but every shipping card still requires:
- final authored text
- final hook set
- validation-complete data
- balance-ready values

### B. Faction-to-card shipping assignment
Faction identity is defined, but final shipping rosters still require:
- complete assignment of units and support pieces
- neutral policy
- roster balance
- faction package completeness

### C. Official format/scenario package
The game requires a fully locked format layer including:
- official scenario catalog
- short / standard / long formats
- draft / sealed / tournament policy, if shipping
- sideboard / rematch / best-of policy where relevant

### D. Build-to-canon reconciliation
The current app still contains implementation simplifications and drift from canon.
Shipping requires full resolver, phase, system, and multiplayer alignment.

### E. UI/state exposure compliance
Shipping requires clean exposure of all mandatory visible state:
- Field dominance
- Trial counters
- Audit escalation
- Name ownership
- capture / bind / raid eligibility

### F. Final live balance and tuning closure
Dynamics doctrine exists, but shipping still requires:
- final curves
- final rate bands
- matchup spread targets
- live tuning thresholds
- card-by-card tuning closure

## I.3 Priority ranking

### Highest priority
1. Build alignment to canon
2. Card-by-card content completion
3. Final faction roster mapping
4. Official format/scenario package
5. UI/state exposure compliance

### Secondary
6. Multiplayer as full product mode through 4 players, with more than 4 only if validated
7. Numerical balance and live tuning targets

## I.4 Shipping doctrine rule

A subsystem is not shipping-complete merely because it is canonically described. It is shipping-complete only when:
- doctrine is locked
- implementation matches doctrine
- UI exposes required state
- content is finalized
- balance targets are met for intended player counts
---

# Section J — Reconciliation Patch Addendum v1.0

## Purpose

This addendum resolves doctrine inconsistencies identified during audit and records current build facts directly in canon-facing documentation.

## J.1 Multiplayer doctrine reconciliation

Where earlier embedded appendix text described:
- 2-player as the primary ruleset, and
- 3–4 player free-for-all as an optional supported extension,

that wording is now superseded.

### Reconciled multiplayer canon
Canonical supported counts are:
- 1 player
- 2 players
- 3 players
- 4 players

2-player remains the primary balance baseline.  
3-player and 4-player are first-class supported shipping modes.  
More than 4 simultaneous players is permitted only if gameplay quality, rules clarity, UI legibility, and system performance remain acceptable after validation.

This reconciliation overrides any older “optional extension” wording still embedded from pre-shipping drafts.

## J.2 Current build snapshot — canonized implementation record

The current Base44 build snapshot presently demonstrates the following implemented behavior:

### Turn spine
- Upkeep
- Draw
- Edicts
- Main
- Battle
- Capture
- End

### Implemented baseline behavior
- starting resources are Sinew 2 / Sigil 1 / Oath 1
- players currently track Measure Marks and Audit Heat
- Draw currently refills toward hand limit 6
- Edicts currently baseline to law-style installs that consume Sigil and add Heat
- Main currently deploys Characters, Pets, Relics, Sites, Bosses, and Host Sigils
- Battle currently resolves a simplified deterministic axis comparison model
- Capture currently converts downed units into score in the implemented flow
- End currently grants +1 Sinew / +1 Sigil / +1 Oath
- the current UI visibly supports a 4-seat multiplayer presentation and phase-ready sync indicators

### Canon note on build snapshot
These implementation facts are now canonized as the **current build snapshot**, but they do not automatically override target-rules canon unless explicitly promoted into the rules layer.

## J.3 Source-precedence reconciliation

The practical source-precedence model is now:

1. Final Gameplay Doctrine
2. Final Engineering and Data Doctrine
3. Shipping Gaps document
4. current Base44 build snapshot
5. historical legacy materials only as archive/reference context if still retained outside the project folder

Any older wording that points to earlier consolidation framing is superseded by this authority order.

## J.4 Current known build-to-canon drift

The current build still differs from full target canon in these major ways:
- Draw refills to 6 instead of using canonical draw-1 flow
- combat is simplified relative to expressive target combat
- arbitration depth is not fully implemented
- field control economy is not fully surfaced
- full match-state visibility requirements are not yet fully exposed
- some tutorial/build messaging still reflects older mechanic assumptions

These differences remain valid shipping gaps until implementation and UI are reconciled.

---

## Card Image Composition Canon

Kudurru Kings cards use a layered image format.

### Front composition order
1. Background color layer by **family**
2. Border layer by **rarity**
3. Shared background image layer
4. Main card layer

### Asset rules
- family background layer is selected by `family`
- rarity border layer is selected by `rarity`
- Ultra cards use the **ultra background color asset** and the **ultra border asset**
- shared front image asset is `front_background.png`
- shared front main/template asset is `card front.png`

### Back asset package
The current card-image package also includes:
- `back_background.png`
- `back_main.png`
- `card back.png`

These are production/rendering assets and do not change gameplay rules.

### Current layered asset filenames
Family background assets:
- `back_color_character.png`
- `back_color_boss.png`
- `back_color_pet.png`
- `back_color_relic.png`
- `back_color_name.png`
- `back_color_edict.png`
- `back_color_site.png`
- `back_color_host_sigil.png`

Special override:
- `back_color_ultra.png`

Rarity border assets:
- `border_common.png`
- `border_uncommon.png`
- `border_rare.png`
- `border_super_rare.png`
- `border_ultra.png`
- `border_legendary.png`

This visual card-composition canon defines render/build layering only. It does not introduce new gameplay mechanics.
