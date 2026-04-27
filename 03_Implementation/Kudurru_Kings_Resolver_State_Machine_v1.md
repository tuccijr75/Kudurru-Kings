# Kudurru Kings — Resolver / State Machine Spec v1

## 0. Purpose

This document defines the **runtime resolver order** and **state machine contract** for Kudurru Kings.

It translates:
- **Shipping Rules v1**,
- **Canonical Gameplay Schema v1**,
- **CSV Migration Map v1**,
- and **Acceptance Test Suite v1**

into a single execution model for the engine.

This document answers one question:

> In what exact order does the game evaluate legality, resolve actions, transition states, apply scoring, and update visible board state?

This is not a design note. It is a runtime sequencing contract.

---

## 1. Authority order

1. **Shipping Rules v1**
2. **Canonical Gameplay Schema v1**
3. **CSV Migration Map v1**
4. **Acceptance Test Suite v1**
5. **Resolver / State Machine Spec v1**

If this resolver spec conflicts with Shipping Rules v1, the rules document wins and this spec must be corrected.

---

## 2. Engine model overview

Kudurru Kings uses a **deterministic phase-based action engine**.

The engine processes gameplay through:
- phase gates,
- legality checks,
- declaration steps,
- deterministic comparison,
- state transitions,
- trigger windows,
- scoring windows,
- and end-step reconciliation.

No random resolution exists in core combat except where rules explicitly define a deterministic deck-reveal tiebreak process such as **Face-off**.

---

## 3. Core runtime concepts

## 3.1 Static authored data
Static authored data comes from the canonical gameplay master and includes:
- identity,
- family,
- faction,
- rarity,
- stats,
- costs,
- timing permissions,
- scoring flags,
- family-specific rule fields.

## 3.2 Runtime state
Runtime state is computed and updated during play and includes:
- ready/exhausted state,
- wound count,
- downed state,
- bound state,
- defeated state,
- field control,
- objective control,
- capture eligibility,
- trial progress,
- Heat total,
- Marks total,
- resource totals,
- turn/phase ownership.

## 3.3 Zones
The runtime tracks the following functional zones:
- Deck
- Hand
- Field
- Law area
- Support positions/rows as applicable
- Discard / return path
- Scenario / objective layer
- Resolution windows

There is no dedicated graveyard zone in Shipping Rules v1.

---

## 4. Match-level state machine

## 4.1 Match states
A match moves through these high-level states:
1. `MatchSetup`
2. `TurnStart`
3. `Upkeep`
4. `Draw`
5. `Edicts`
6. `Main`
7. `Battle`
8. `Resolution`
9. `End`
10. `VictoryCheck`
11. `MatchEnd`

## 4.2 Loop rule
The engine advances one active player through the 7-step turn loop, then rotates to the next player unless MatchEnd is reached.

---

## 5. Match setup order

## 5.1 Setup sequence
Runtime setup order is:
1. load legal player count and seat layout
2. determine player order
3. load Scenario / Objective layer
4. validate presented decks
5. initialize resources for each player:
   - Sinew 2
   - Sigil 1
   - Oath 1
6. shuffle decks
7. draw 6 cards per player
8. offer one free full mulligan to 6
9. apply scenario opening effects
10. enter `TurnStart` for first player

## 5.2 Setup legality failure
If any deck fails legality, match setup cannot complete.

---

## 6. Turn/phase runtime order

The phase order is fixed:
1. Upkeep
2. Draw
3. Edicts
4. Main
5. Battle
6. Resolution
7. End

## 6.1 Phase transition rule
The engine may not skip to a later phase unless:
- all mandatory phase checks are complete,
- no unresolved mandatory trigger remains,
- and no unresolved action stack/window remains open.

---

## 7. Global action resolution template

Every attempted action resolves through the same master template:

1. **Action request created**
2. **Phase legality check**
3. **Zone legality check**
4. **Resource / cost legality check**
5. **Faction / deck / uniqueness legality check if relevant**
6. **Target legality check if target required**
7. **Action declaration lock**
8. **Cost payment / commitment**
9. **Replacement / prevention hooks**
10. **Primary effect resolution**
11. **Immediate state updates**
12. **State-based checks**
13. **Triggered effects queued**
14. **Triggered effects resolved in priority order**
15. **Scoring window evaluation**
16. **Victory check**
17. **UI/state refresh**

This is the core engine contract.

---

## 8. State-based checks

After any action resolves, the engine runs state-based checks in this order:

1. wound threshold check
2. Downed assignment
3. illegal Bound removal check
4. Defeated state legality reconciliation
5. Boss trial/capture legality reconciliation
6. unique-slot / uniqueness reconciliation
7. field-control recompute if needed
8. objective-control recompute if needed
9. capture eligibility recompute
10. Heat floor clamp
11. illegal target/state cleanup

## 8.1 Wound threshold check
If current wounds >= wound_threshold, the unit becomes `Downed`.

## 8.2 Downed consequences
When Downed is assigned:
- unit remains on field
- flip marker applies
- unit no longer counts for Field control
- unit continues occupying its slot
- unit remains targetable if rule allows

## 8.3 Bound legality check
By default, a normal unit cannot be Bound unless it is already Downed, unless an override exists.

## 8.4 Defeated legality check
Defeated units:
- remain on field
- do not count for Field control
- occupy slots
- are not targetable
- are not capturable

## 8.5 Heat floor check
Heat may never go below 0.

---

## 9. Upkeep phase resolver

## 9.1 Upkeep order
1. enter Upkeep
2. resolve mandatory upkeep triggers
3. check Boss Oath upkeep
4. apply upkeep-based expirations
5. apply upkeep restorations or upkeep-cost failures if any rules define them
6. run state-based checks
7. close Upkeep

## 9.2 Boss upkeep check
For each controlled Boss:
- inspect `upkeep_oath`
- if cost can and will be paid, deduct Oath
- if cost cannot or is not paid, apply the Boss’s defined upkeep-failure rule

---

## 10. Draw phase resolver

## 10.1 Draw order
1. enter Draw
2. compute current hand size
3. draw until hand size = 6 unless replacement rule changes draw behavior
4. resolve draw triggers
5. run state-based checks
6. close Draw

---

## 11. Edicts phase resolver

## 11.1 Edicts action window
Allowed actions are any with legal timing that includes Edicts.

## 11.2 Edict resolution order
When an Edict is played:
1. validate timing/class/zone
2. validate targets if needed
3. pay costs
4. resolve primary effect
5. because Edicts are one-shot by default, move to default post-resolution destination
6. run state-based checks
7. queue and resolve triggered effects
8. refresh visible law state

## 11.3 Name interaction in Edicts phase
If a Name is installed during a legal Edicts window:
- enter law-object placement flow
- apply Heat on install
- recompute arbitration relevance and ownership visibility
- run state-based checks

---

## 12. Main phase resolver

## 12.1 Main action window
Allowed actions include legal deployment and establishment actions for:
- Characters
- Bosses
- Pets
- Relics
- Sites
- Host Sigils
- other cards whose timing includes Main

## 12.2 Main play order
For any Main-phase play:
1. validate timing and zone
2. validate unique-slot rules if applicable
3. validate faction/legality restrictions
4. validate costs
5. pay costs
6. place card into correct zone
7. apply on-enter rules
8. run state-based checks
9. queue and resolve triggers
10. refresh UI-visible board state

## 12.3 Host Sigil slot rule
If a Host Sigil would violate unique-slot occupancy, the action fails or resolves through an explicit replacement rule defined by card/system logic.

---

## 13. Battle phase resolver

## 13.1 Battle declaration order
A combat declaration resolves in this order:
1. validate attacker exists and can attack
2. validate defender is legal
3. validate chosen axis is one of Stone / Veil / Authority
4. lock attacker, defender, and contested axis
5. open supporter assignment subwindow
6. open resource spend subwindow
7. compute final combat values
8. compare values
9. if not tied, assign successful attack result/effects
10. if tied, enter Face-off resolver
11. apply combat exhaustion/commitment states
12. run state-based checks
13. queue and resolve triggers
14. refresh capture eligibility

## 13.2 Default success rule
If attack succeeds and no special consequence is enabled, deal exactly **1 wound** to defender Vitality.

## 13.3 Supporter assignment subwindow
Each side may assign at most one legal supporter.

### Supporter processing order
1. validate supporter legality
2. commit supporter
3. apply support value rule
4. apply Heat relief on support if relevant

## 13.4 Resource spend subwindow
Each side may spend up to 2 matching resources.

### Matching resource map
- Stone -> Sinew
- Veil -> Sigil
- Authority -> Oath

Attempting to spend 3 or more matching resources in one combat is illegal unless an override exists.

## 13.5 Combat comparison
After all modifiers and legal spends:
- compare attacker total vs defender total on the contested axis
- higher total wins
- equal total triggers Face-off

---

## 14. Face-off resolver

Face-off is the deterministic tie-break system.

## 14.1 Face-off entry
Face-off begins only after a tied combat comparison or tied arbitration chain that requires Face-off.

## 14.2 Face-off order
1. for each side, reveal top valid combat card from deck
2. valid Face-off cards are:
   - Character
   - Boss
   - Pet
3. ignore card text entirely
4. compare same contested axis as the original tied contest
5. if one side wins, Face-off ends
6. if tie persists, repeat
7. when Face-off ends, reshuffle revealed Face-off cards back into deck
8. if a side has no valid Face-off card, that side loses immediately

## 14.3 Face-off does not use
- supporters
- resource spend
- card text
- alternate axis choice

---

## 15. Resolution phase resolver

Resolution is a distinct post-battle phase.

## 15.1 Resolution order
1. enter Resolution
2. process post-battle cleanup
3. recompute Downed/Bound/Capturable states
4. process legal capture attempts
5. process declined capture results
6. process failed capture results
7. process Site raid resolution
8. process post-battle score events
9. run state-based checks
10. queue and resolve triggers
11. refresh all visible post-battle state
12. close Resolution

---

## 16. Capture resolver

## 16.1 Normal-unit capture legality
A normal unit is legally capturable only if all are true:
- unit is Downed
- unit is Bound
- current phase is Resolution
- unit is not already Defeated
- no effect prevents capture

## 16.2 Capture attempt order
1. validate capture legality
2. commit capture action
3. apply prevention/replacement effects if any
4. if capture succeeds:
   - apply capture result
   - assign Mark reward
   - apply permanent collection-copy reward metadata
   - remove/transition match-state ownership as defined by implementation
5. if capture fails:
   - target becomes Defeated
6. if player declines a valid capture:
   - target becomes Defeated
7. run state-based checks
8. queue and resolve triggers
9. evaluate scoring overlap
10. perform victory check

## 16.3 Scoring from capture
- Character capture = 1 Mark
- Boss capture = 2 Marks

## 16.4 Overlap rule
If defeat and capture would overlap, only the **higher single reward** is granted.

---

## 17. Defeated resolver

## 17.1 Defeated entry
A unit becomes Defeated when:
- a specific effect says so, or
- a valid capture is declined, or
- a capture attempt fails.

## 17.2 Defeated state application
When a unit becomes Defeated:
- remain on field
- remove targetability
- remove capture eligibility
- remove Field-control contribution
- retain slot occupancy
- start defeat restore counter

## 17.3 Defeated restore counter
The restore counter advances by **full rounds**, not individual turns.

## 17.4 Defeated auto-restore order
After 2 full rounds:
1. if owner has hand space, move unit to owner hand
2. otherwise move unit to owner deck/return path
3. clear Defeated runtime state
4. refresh board occupancy and control status

## 17.5 Revive effects
If a revive effect legally resolves before auto-restore:
- remove Defeated state
- apply effect-defined restore placement/state
- refresh board state

---

## 18. Boss trial resolver

## 18.1 Trial progress tracking
Each Boss tracks trial progress by axis:
- Stone
- Veil
- Authority

## 18.2 Trial increment rule
Default Boss rule:
- a distinct successful trial on a new axis increments progress
- repeating the same axis does not increment progress again unless override exists

## 18.3 Trial completion
A Boss is Trial-complete when required unique trial count is met.

## 18.4 Boss capture legality check
Before any Boss capture:
- if not Trial-complete and no override exists -> capture illegal
- if Trial-complete -> capture may proceed if other conditions are satisfied

## 18.5 Boss stance progression order
Default stance progression:
1. Guarded
2. Ascendant
3. Wrathful
4. Exposed

The engine must recompute stance when relevant trial thresholds are crossed.

---

## 19. Names and law resolver

## 19.1 Name install order
1. validate legal timing/zone/cost
2. pay costs
3. place Name into law area
4. apply Heat on install
5. register Name ownership
6. register arbitration availability if applicable
7. run state-based checks
8. resolve triggers
9. refresh law-area UI

## 19.2 Name rewrite order
1. validate rewrite legality
2. apply rewrite Heat by card value rule
3. replace/update relevant law state
4. run state-based checks
5. resolve triggers

## 19.3 Edict resolution reminder
Edicts are one-shot by default and should not persist after resolution unless a specific override exists.

---

## 20. Arbitration resolver

## 20.1 Arbitration entry
An arbitration action begins when a legal arbitration-capable action targets a valid law object.

## 20.2 Arbitration order
1. validate arbitration legality
2. identify acting player and responding player
3. collect hidden Oath bids
4. reveal bids
5. compute arbitration totals including legal modifiers
6. if a winner exists, proceed to success/failure outcome
7. if tied, enter Face-off chain
8. on success, acting player chooses legal option among:
   - Seize
   - Suppress
   - Corrupt
9. apply result
10. assign scoring as applicable
11. run state-based checks
12. resolve triggers
13. refresh law ownership and UI visibility

## 20.3 Arbitration scoring
- successful Name seizure = 1 Mark
- arbitration win without seizure = 1 Mark where rules/modeling say applicable

## 20.4 Injunction support
If `supports_injunctions = true`, injunction logic may enter arbitration resolution as an additional legality or outcome layer.

---

## 21. Audit Heat resolver

## 21.1 Heat update order
Whenever Heat changes:
1. apply delta
2. clamp at minimum 0
3. recompute Heat band
4. refresh UI display
5. check any Heat-threshold triggers

## 21.2 Standard Heat ladder
- 0–2 Clear
- 3–4 Watched
- 5–6 Censor Wraith
- 7–8 Tribunal
- 9+ Lawbroke

## 21.3 Standard Heat sources
By default, runtime should support:
- Name install Heat
- Name rewrite Heat
- support-related Heat relief
- effect-defined Heat spend/use

## 21.4 Heat spend order
1. validate spend is legal
2. validate target/use is own-card revival/recovery unless override exists
3. deduct Heat immediately
4. apply revive/recovery effect
5. recompute Heat band
6. run state-based checks

---

## 22. End phase resolver

## 22.1 End order
1. enter End
2. resolve end-step triggers
3. compute dynamic resource gain conditions
4. apply resource gains
5. apply fallback Sinew if needed
6. enforce discard down to 6
7. recompute scenario/objective control
8. run state-based checks
9. resolve triggers caused by end-step changes
10. perform victory check
11. close turn

## 22.2 Dynamic gain order
Evaluate in this order:
1. Sinew condition
2. Sigil condition
3. Oath condition
4. fallback condition

### Sinew condition
Gain +1 Sinew if player controls the most ready combat units across active Fields.

### Sigil condition
Gain +1 Sigil if player controls at least one qualifying Site or Host Sigil.

### Oath condition
Gain +1 Oath if player controls the current Scenario / Objective condition.

### Fallback condition
If none of the above grant resources, gain +1 Sinew.

## 22.3 UI requirement
End-step income preview must be updated before turn closure so the player can see which conditions were met.

---

## 23. Victory check resolver

## 23.1 Victory check timing
Victory checks run:
- after scoring events
- after Resolution scoring windows
- after End-step state reconciliation
- and any other time a rule explicitly changes Marks

## 23.2 Victory rule
If one or more players have reached 10 Marks:
1. complete the current resolution window
2. compare eligible winners
3. if single highest valid winner exists, match ends
4. if tied and no tie-break rule resolves winner here, continue according to future tie-resolution policy if implemented

---

## 24. UI refresh contract

After every completed action window, the engine must refresh these visible or inspectable states:
- field dominance
- trial counters
- audit level
- name ownership
- bind status
- downed status
- capture eligibility
- raid eligibility
- end-phase income preview

No hidden-debug-only dependency is allowed for these states.

---

## 25. Error / illegal action handling

## 25.1 Illegal actions
If an action fails legality before declaration lock:
- no cost is paid
- no state changes
- action is rejected
- UI explains failure reason if possible

## 25.2 Illegal action after partial declaration
If an action becomes illegal after declaration lock due to replacement/prevention/validation outcome:
- follow effect-specific failure rule if defined
- otherwise cancel unresolved portions
- preserve already-locked legal changes only if rules explicitly permit

---

## 26. Release-critical resolver invariants

The following must always hold true:
- combat always uses Stone, Veil, or Authority
- successful basic attack without special consequence = 1 wound
- tie = Face-off
- Downed stays on field and flips
- Bound requires Downed unless override exists
- normal capture requires Downed + Bound in Resolution
- declined/failed capture => Defeated
- Defeated remains on field, untargetable, uncapturable, auto-restores after 2 full rounds
- boss capture requires Trial-complete unless override exists
- Heat cannot go below 0
- End-step income follows dynamic 3-condition model plus fallback
- scoring overlap uses higher single reward

---

## 27. Immediate next step after this spec

With this resolver spec in place, the next correct execution steps are:
1. migrate the canonical gameplay master
2. run validation gates
3. execute Acceptance Test Suite v1
4. correct any failures in data or runtime sequencing

This document should be treated as the runtime sequencing contract for Kudurru Kings.

