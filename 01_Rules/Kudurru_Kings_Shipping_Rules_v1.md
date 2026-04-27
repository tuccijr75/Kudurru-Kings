# Kudurru Kings — Shipping Rules v1

## 0. Authority and Purpose

This document is the single live gameplay authority for **Kudurru Kings**.

It replaces conflicting gameplay authority spread across earlier doctrine, engineering notes, and current-build snapshot documents. Older documents may still be kept for historical or implementation reference, but they are not rules authority once this document is adopted.

### 0.1 Authority order
1. **This document**
2. Supporting engineering implementation derived from this document
3. Data/schema derived from this document
4. Export/production/render files derived from the canonical gameplay data

### 0.2 Design intent
Kudurru Kings is a **deterministic tactical law-war card game** built around:
- positional control,
- card synergies,
- dynamic field and objective pressure,
- legal/law manipulation,
- deterministic combat,
- capture and boss trial systems,
- and escalating risk through Audit Heat.

Winning without strategy should be difficult. Strong cards matter, but they are intended to matter through decision density, setup, sequencing, synergy, and board state.

---

## 1. Supported Modes and Player Counts

### 1.1 Supported player counts
Shipping support includes:
- **1 player** (solo)
- **2 players**
- **3 players**
- **4 players**

### 1.2 Standard mode
There is **one Standard mode**. Standard mode always includes a **Scenario / Objective layer**.

### 1.3 Digital presentation baseline
The digital baseline is a **4-seat board/UI presentation**, even when fewer than 4 players are present.

---

## 2. Win Condition

### 2.1 Primary win condition
The standard win condition is:
- **First player to 10 Marks wins**.

### 2.2 Simultaneous resolution
If multiple scoring events would resolve in the same resolution window, complete that resolution window fully, then determine whether one or more players have reached 10 Marks.

### 2.3 Scenario interaction
Scenarios may create pressure, objectives, thresholds, or state changes, but they do not replace the default 10-Mark win condition unless a future rules addendum explicitly says so.

---

## 3. Card Families

The shipping game contains the following card families:
- **Character**
- **Boss**
- **Edict**
- **Host Sigil**
- **Name**
- **Pet**
- **Relic**
- **Site**

### 3.1 Family purpose overview
- **Characters** are the primary tactical units.
- **Bosses** are apex battlefield entities with Trials, stances, upkeep, and special capture rules.
- **Edicts** are one-shot legal / tactical plays.
- **Host Sigils** are powerful persistent anchors with special identity and control implications.
- **Names** are persistent law objects that shape the board and rules environment.
- **Pets** are support-capable battlefield entities with combat relevance.
- **Relics** are persistent support / utility assets.
- **Sites** are board objects that interact with field control, raids, and scoring.

---

## 4. Factions

### 4.1 Launch factions
The launch factions are:
- **Borderstone Guild**
- **Floodborn Pact**
- **Skyloom Temple**
- **Underwell Keepers**
- **Fateforge**

### 4.2 Faction ownership
Every launch card must have exactly one **owner faction**.

### 4.3 Neutral cards
There are **no neutral launch cards**.

### 4.4 Standard deck faction model
Standard legality uses a **hybrid faction model**:
- Some cards explicitly enforce faction locks or faction restrictions.
- Cards without a faction restriction may be mixed legally.
- Standard deck legality is therefore not strict faction-pure by default, but faction locks remain authoritative when printed or structurally defined.

---

## 5. Rarity

### 5.1 Canon rarity ladder
The canonical rarity ladder is:
- **Common**
- **Uncommon**
- **Rare**
- **Super Rare**
- **Legendary**
- **Ultra**

### 5.2 Scoring interaction
Rarity **never directly changes Mark rewards**.

### 5.3 Stat interaction
Rarity may influence printed card power, complexity, specialization, or stat density, but not scoring values directly.

### 5.4 Ultra cards
The only Ultra cards are:
- **Anu**
- **Adamu**

---

## 6. Deck Construction

### 6.1 Deck size
A Standard deck contains exactly **36 cards**.

### 6.2 Opening hand
Each player begins with an opening hand of **6 cards**.

### 6.3 Mulligan
Each player receives **one free full redraw to 6**.

### 6.4 Copy and composition rules
A legal Standard deck follows these baseline rules:
- maximum **2 copies** of a named card,
- maximum **1 copy** of a given Super Rare,
- maximum **1 Host Sigil**,
- minimum **12 Characters**,
- minimum **2 Sites**,
- minimum **4 support cards** from Pets + Relics,
- maximum **3 Bosses**,
- maximum **3 Names**.

### 6.5 Enforcement location
Deck legality enforcement may be implemented in the **deck builder** rather than in-match runtime.

---

## 7. Resources

### 7.1 Resource types
The only gameplay resources are:
- **Sinew**
- **Sigil**
- **Oath**

### 7.2 Starting resources
Each player begins the match with:
- **Sinew 2**
- **Sigil 1**
- **Oath 1**

### 7.3 Resource meanings
- **Sinew** = physical exertion, force, and battlefield pressure
- **Sigil** = inscription, ritual, site/law manipulation, and engineered influence
- **Oath** = binding obligation, sanctioned intent, and high-order commitment

---

## 8. Combat Axes

Combat uses three deterministic combat axes:
- **Stone**
- **Veil**
- **Authority**

> Note: **Authority** is the combat-axis term used to avoid conflict with the resource term **Oath**.

### 8.1 Axis identity
- **Stone** represents force, structure, impact, and direct physical contest
- **Veil** represents misdirection, displacement, finesse, infiltration, and indirect advantage
- **Authority** represents sanction, command, legitimacy, pressure, and decisive control

---

## 9. Zones and Board State

### 9.1 Core zones
The game uses the following core zones:
- Deck
- Hand
- Field / battlefield presence
- Law area (Names, legal board objects as applicable)
- Support rows / support positions as implemented by card type
- Discard
- Owner deck return path
- Resolution / capture state windows
- Scenario / objective space

### 9.2 No graveyard zone
There is **no graveyard** as a named persistent gameplay zone in Shipping Rules v1.

### 9.3 Card return behavior
When a rule returns a card to deck, the default interpretation is:
- the card goes to the owner’s **discard path / return path**, then shuffles back into the owner’s deck according to implementation timing.

---

## 10. Match Setup

### 10.1 Standard setup sequence
1. Determine player order.
2. Load the Scenario / Objective layer.
3. Each player presents a legal 36-card deck.
4. Each player begins with Sinew 2 / Sigil 1 / Oath 1.
5. Each player draws 6 cards.
6. Each player may take one free full mulligan to 6.
7. Resolve any scenario-specific opening instructions.
8. Begin play with the first player.

---

## 11. Turn Structure

The shipping turn uses a **7-step loop**.

1. **Upkeep**
2. **Draw**
3. **Edicts**
4. **Main**
5. **Battle**
6. **Resolution**
7. **End**

### 11.1 Upkeep
Upkeep handles:
- upkeep costs,
- Boss Oath upkeep,
- effect expiration tied to controller upkeep,
- and other upkeep-based triggers.

### 11.2 Draw
At the start of Draw, the active player **refills hand to 6**.

### 11.3 Edicts
The Edicts step is where players may deploy or resolve Edicts and other law/timing actions that are legal in this step.

### 11.4 Main
The Main step is where players deploy and establish board state, including legal plays of Characters, Bosses, Pets, Relics, Sites, Host Sigils, and other assets that are legal in Main.

### 11.5 Battle
The Battle step is where deterministic combat is declared and resolved.

### 11.6 Resolution
Resolution is a distinct post-battle step that includes:
- battle cleanup,
- capture legality checks,
- capture attempts,
- failed or declined capture handling,
- raid resolution,
- and other post-combat state conversions.

### 11.7 End
The End step handles:
- end-step triggers,
- dynamic resource gain,
- discard to hand limit,
- scenario condition review,
- and turn closure.

---

## 12. Draw and Hand Rules

### 12.1 Draw rule
At the start of Draw, refill hand to **6**.

### 12.2 Hand limit
The normal hand-size target and hand limit is **6**.

### 12.3 End-step discard
At End, discard down to **6** if above 6.

### 12.4 Heat relief discard
Cards may be discarded for Audit Heat relief according to value-based or card-defined rules. The baseline game supports **variable** card-to-Heat relief, not a universal fixed ratio.

---

## 13. Dynamic End-Phase Resource Gain

Resource gain occurs in the **End** step and is dynamic.

### 13.1 Sinew gain
Gain **+1 Sinew** if you control the **most ready combat units across active Fields**.

### 13.2 Sigil gain
Gain **+1 Sigil** if you control at least one **Site** or **Host Sigil**.

### 13.3 Authority/Oath gain condition
Gain **+1 Oath** if you control the current **Scenario / Objective condition**.

### 13.4 Fallback gain
If you gain none of the above resources this way, gain **+1 Sinew** as a fallback.

### 13.5 UI requirement
The UI must always show these three End-phase income conditions explicitly before the player ends their turn.

---

## 14. Combat Rules

### 14.1 Combat identity
Combat is **deterministic**.

### 14.2 Declaring combat
A combat declaration must choose:
- an attacker,
- a defender,
- and a combat axis:
  - Stone,
  - Veil,
  - or Authority.

### 14.3 Consequences
There is **no universal default declared consequence system**. Consequence access is dynamic and depends on cards, fields, and active conditions.

### 14.4 Default successful attack result
If an attack succeeds and no special consequence is enabled, it deals **1 wound to Vitality**.

### 14.5 Supporters
Each side may contribute **one supporter** by default if legal.

### 14.6 Resource spend
Each side may spend up to **2 matching resources** by default if legal.

### 14.7 Supporter Heat interaction
Supporters **relieve Audit Heat** rather than increasing it.

### 14.8 Deterministic comparison
Combat compares the chosen axis after all legal modifications.

---

## 15. Tie Resolution — Face-off

If a combat comparison ties, resolve a **Face-off**.

### 15.1 Face-off procedure
1. Each player reveals the top valid combat card from their deck.
2. Valid cards for Face-off are:
   - **Character**
   - **Boss**
   - **Pet**
3. Card text is ignored during Face-off.
4. Compare the **same contested axis** from the original battle.
5. No supporters and no resource spend are used in Face-off.
6. If still tied, repeat.
7. Revealed Face-off cards are shuffled back into deck after the Face-off chain resolves.
8. If a player has no valid combat card to reveal, that player loses the Face-off.

---

## 16. Vitality and Wounds

### 16.1 Vitality
Every combat-capable card has a **Vitality** value.

### 16.2 Wounds
Wounds reduce Vitality.

### 16.3 Default unit threshold
Most normal units default to a wound threshold of **2** unless a printed card rule/stat says otherwise.

### 16.4 Boss threshold
Bosses generally have higher printed thresholds than standard units.

### 16.5 Rarity interaction
Rarity does not directly set wound thresholds. Thresholds are defined by printed card values.

---

## 17. State Model

Shipping Rules v1 uses the following important states:
- Ready
- Exhausted
- Wounded
- Downed
- Bound
- Defeated
- Silenced
- Staggered

### 17.1 Ready
The card may act or support if otherwise legal.

### 17.2 Exhausted
The card has committed or been spent and cannot act/support again unless readied.

### 17.3 Wounded
The card has taken damage against its Vitality total.

### 17.4 Downed
A card becomes Downed once it has reached its wound threshold.

#### Downed rules
- Downed cards stay **on the field**.
- Downed cards are visually marked by being **flipped**.
- Downed cards do **not** count for Field control.
- Downed cards **do** still occupy a slot.
- Downed cards **can** still be targeted by effects.

### 17.5 Bound
Bound is a legal restraint state.

#### Bound legality
A normal unit may only be Bound once it is **Downed**, unless a card explicitly overrides this.

### 17.6 Defeated
Defeated is a distinct state from Downed.

#### Defeated rules
- Defeated cards remain **on the field**.
- Defeated cards do **not** count for Field control.
- Defeated cards still occupy a slot.
- Defeated cards may be **revived**.
- Defeated cards may **not** be targeted.
- Defeated cards may **not** be captured.
- Defeated cards auto-restore after **2 full rounds**.
- On auto-restore, the card returns to the owner’s **hand if there is space**, otherwise to the owner’s **deck**.

### 17.7 Defeated origin
A unit may become Defeated:
- by specific card/effect text,
- or when a capture is failed or declined under the capture rules.

---

## 18. Bind and Capture

### 18.1 Capture sequence for normal units
The normal-unit capture sequence is:
1. the unit receives wounds,
2. the unit becomes **Downed**,
3. the unit becomes **Bound**,
4. the unit becomes legally **Capturable**,
5. a legal capture attempt is made in Resolution.

### 18.2 Capture legality
A normal unit must be **Downed first**, then **Bound**, then it may be Captured.

### 18.3 Resolution timing
Capture is only legal during the **Resolution** step/substep after a valid Bind check.

### 18.4 Declined capture
If a player chooses not to capture a valid Downed+Bound unit, that unit becomes **Defeated**.

### 18.5 Failed capture
If a capture attempt fails, the target becomes **Defeated**.

### 18.6 Scoring from capture
- Character capture = **1 Mark**
- Boss capture = **2 Marks**

### 18.7 Collection-copy reward
When a player captures a card, the capturing player gains a **permanent collection copy** of that card outside the match economy.

### 18.8 Ownership protection
The losing player never permanently loses ownership of captured cards. Capture only affects the current match state.

---

## 19. Defeat Scoring

### 19.1 Plain defeat
Plain defeat without capture scores **1 Mark** for ordinary units.

### 19.2 Boss defeat
Bosses do not automatically follow the same plain-defeat scoring rule as ordinary units.

### 19.3 Overlap rule
If defeat and capture would overlap, apply the **higher single reward** only.

---

## 20. Boss Rules

### 20.1 Boss identity
Bosses are a distinct apex subsystem, not simply larger Characters.

### 20.2 Boss upkeep
Bosses require **Oath upkeep** by default.

### 20.3 Trial requirement
The default Boss requirement is **3 unique Trials**.

### 20.4 Trial axes
Trials must be won on distinct axes:
- Stone
- Veil
- Authority

Repeated wins on the same axis do not advance default Trial completion.

### 20.5 Boss capture legality
Bosses cannot be captured until they are **Trial-complete**, unless a card explicitly overrides this.

### 20.6 Boss stance ladder
Bosses use the following stance ladder:
- **Guarded**
- **Ascendant**
- **Wrathful**
- **Exposed**

### 20.7 Boss value
Boss capture scores **2 Marks**.

### 20.8 Boss aura / retaliation
Boss aura and retaliation systems are part of Shipping Rules v1 and are intended to remain active gameplay systems.

---

## 21. Fields, Lines, and Geasa

### 21.1 Field subsystem
Fields are a live shipping subsystem.

### 21.2 Line subsystem
Lines are live shipping jurisdiction / traversal boundaries.

### 21.3 Geasa subsystem
Geasa are live shipping consequences tied to crossing Lines or otherwise violating field/jurisdiction conditions.

### 21.4 Active Field limit
The default active Field limit is **2**.

### 21.5 Field tags
The active Field tags are:
- Sanctuary
- Threshold
- Wilds
- Warfield

### 21.6 Field control importance
Field control affects:
- tactical position,
- economy,
- and scenario pressure.

### 21.7 Implementation note
If the current build enforces Fields/Lines/Geasa weakly, that is an **implementation gap**, not a design cut.

---

## 22. Sites and Raids

### 22.1 Sites
Sites are active gameplay objects and deckbuilding requirements.

### 22.2 Raids
Site raids are part of Shipping Rules v1.

### 22.3 Raid scoring
A successful Site raid scores **2 Marks**.

---

## 23. Names and Edicts

### 23.1 Names
Names are **persistent law objects**.

### 23.2 Edicts
Edicts are **one-shot plays**.

### 23.3 Edicts timing
Edicts are resolved in their legal windows, including the Edicts step and any allowed special timing windows granted by card text.

### 23.4 Heat from Names
Installing a Name adds **+1 Audit Heat** by default.

### 23.5 Rewrite Heat
Rewriting or swapping a Name adds Audit Heat according to the **value of the card** involved.

---

## 24. Arbitration

### 24.1 Arbitration status
Arbitration is a shipping subsystem.

### 24.2 Baseline procedure
Arbitration uses a hidden **Oath bid** baseline.

### 24.3 Ties in Arbitration
Ties in Arbitration do not automatically favor the defender. They resolve through a **Face-off chain** until a winner is determined or a player has no valid combat card.

### 24.4 Success options
On Arbitration success, the acting player may choose:
- **Seize**
- **Suppress**
- **Corrupt**

### 24.5 Name seizure scoring
Successful Name seizure scores **1 Mark**.

### 24.6 Expanded arbitration features
Expanded arbitration features are not all mandatory in Shipping Rules v1. The most valuable first expanded feature to retain is:
- **Injunctions**

---

## 25. Audit Heat

### 25.1 Audit Heat status
Audit Heat is a core shipping mechanic.

### 25.2 Heat ladder
The ladder remains:
- **0–2 Clear**
- **3–4 Watched**
- **5–6 Censor Wraith**
- **7–8 Tribunal**
- **9+ Lawbroke**

### 25.3 Heat floor
Heat cannot go below **0**.

### 25.4 Heat spend
Heat is both:
- a risk meter,
- and a spendable recovery resource.

### 25.5 Spend application
The locked default spend application is:
- **revival / recovery on your own cards only**.

### 25.6 Spend timing
Spent Heat is removed immediately from the Heat track.

---

## 26. Scoring Summary

The Standard scoring table is:
- Character capture = **1 Mark**
- Boss capture = **2 Marks**
- Name seizure = **1 Mark**
- Site raid = **2 Marks**
- Plain defeat without capture = **1 Mark**
- Arbitration win without seizure = **1 Mark**

Rarity never directly changes Mark rewards.

---

## 27. Guard, First Strike, Initiative

These remain valid gameplay values and must be formally supported.

### 27.1 Guard
Guard functions as **both**:
- a stat modifier concept,
- and a target restriction / protector rule where applicable.

### 27.2 First Strike
First Strike is a real timing ability in combat resolution.

### 27.3 Initiative
Initiative is used for **combat sequencing**, not general turn-order sequencing.

---

## 28. Scenario and Objective Layer

### 28.1 Shipping status
Scenarios are shipping.

### 28.2 Standard integration
Every Standard match includes a Scenario / Objective layer.

### 28.3 Objective economy link
The current Scenario / Objective condition also determines one of the dynamic End-phase resource gain conditions.

---

## 29. Collection and Progression Rules

### 29.1 Ultra progression
Ultra acquisition requires all three:
- **Apex Sigils**
- card-specific **Fragments**
- and a progression gate.

### 29.2 Fragment specificity
Ultra fragments remain card-specific.

### 29.3 Account gate
The current intended minimum Ultra unlock gate remains tied to a higher account progression threshold.

---

## 30. Canonical Gameplay Schema Requirements

The canonical gameplay schema must support structured fields including, but not limited to:
- owner_faction
- cost_sinew
- cost_sigil
- cost_oath
- keywords
- tags
- is_unique
- is_legendary
- scenario_only
- timing_class
- trial_required
- site_type
- raid_condition
- heat_on_install

### 30.1 Removed deprecated fields
The following fields are deprecated and removed from canonical gameplay authority:
- wind
- eye
- weight

### 30.2 Text authority rule
Freeform `rules_text` may not be the only place a critical legality rule lives if a structured field can represent it.

### 30.3 Deprecation policy
Deprecated fields are not retained once Shipping Rules v1 and the canonical gameplay schema are locked.

---

## 31. Asset and Export Pipeline

### 31.1 Asset pipeline
The layered render pipeline remains the official asset pipeline.

### 31.2 Export status
`master.csv` and `production_master.csv` are output/export layers only. They must be regenerated from the canonical gameplay master and updated to meet current build standards.

### 31.3 Ultra visuals
Ultra visual overrides remain part of the official asset pipeline.

### 31.4 Family visual identity
Card family visual assignments remain locked.

---

## 32. UI Visibility Requirements

The following must always be visible or inspectable in the UI:
- field dominance
- trial counters
- audit level
- name ownership
- bind status
- downed status
- capture eligibility
- raid eligibility
- End-phase income conditions

Incomplete visibility of these systems is a **shipping gap**, not a polish item.

---

## 33. Final Canon Statements

### 33.1 Collection-copy rule
Captured cards grant the winner a **permanent collection copy**, but the loser never permanently loses owned cards; capture only affects the current match state.

### 33.2 Rarity / Marks rule
Rarity never directly changes Mark rewards; it only influences printed card power/value.

### 33.3 Deprecation rule
Deprecated fields are not retained once Shipping Rules v1 and the canonical gameplay schema are locked.

---

## 34. Implementation Notes (Non-Rules)

The following are not design uncertainties. They are implementation tasks:
- merging prior doctrine into this rules authority,
- updating data schema to reflect this document,
- removing deprecated fields,
- regenerating export files,
- enforcing UI visibility requirements,
- and bringing current build behavior into alignment with these rules.

Once adopted, this document should be treated as the **only live gameplay rules authority** for Kudurru Kings.

