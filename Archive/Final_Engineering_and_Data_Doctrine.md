# Kudurru Kings — Final Engineering and Data Doctrine v1.1

## Purpose

This is the consolidated engineering-facing doctrine for Kudurru Kings. It merges the card schema and implementation spec, and updates them with shipping-level engineering targets.

## Authority order inside this file

1. Card schema and authoring standards
2. Implementation specification
3. Shipping production addendum

---

# Section A — Card Schema and Authoring Standards

**Merged from:** `Kudurru_Kings_Card_Schema_v1_0.md`

# Kudurru Kings — Card Schema v1.0

## Purpose

This document defines the canonical card data model for Kudurru Kings. It exists to align:
- card content production
- CSV exports
- JSON/game data
- rules templating
- legality validation

This schema is authoritative for all card families in the master set.

---

## 1. Universal field model

Every card record must include the following universal fields.

### Required universal fields
- `card_id` — unique stable identifier
- `name` — canonical printed name
- `family` — Character / Boss / Pet / Relic / Name / Edict / Site / HostSigil
- `rarity` — Common / Uncommon / Rare / SuperRare / Legendary if used
- `set_code` — set or release identifier
- `rules_text` — canonical printed rules text
- `flavor_text` — optional but recommended text field
- `stone` — integer, default 0 if not used
- `veil` — integer, default 0 if not used
- `oath` — integer, default 0 if not used
- `cost_sinew` — integer
- `cost_sigil` — integer
- `cost_oath` — integer
- `owner_faction` — canonical faction or neutral
- `keywords` — pipe-delimited or array list of rules keywords
- `tags` — pipe-delimited or array list of content tags
- `is_unique` — boolean
- `is_legendary` — boolean
- `is_super_rare` — boolean
- `art_prompt_ref` — optional external art/prompt linkage
- `notes_design` — non-player-facing design notes, optional

### Optional universal fields
- `subtitle`
- `release_status`
- `lore_region`
- `voice_family`
- `ai_flags`
- `scenario_only`
- `tutorial_only`

---

## 2. Family-specific schema

## 2.1 Character

### Required Character fields
- `unit_class`
- `deployment_field_rule`
- `support_allowed` — boolean
- `capture_value` — default 1
- `wound_limit` — default 2
- `can_initiate_battle` — boolean

### Optional Character fields
- `on_enter`
- `on_upkeep`
- `on_battle`
- `on_capture`
- `passive_law`
- `line_affinity`
- `field_affinity`
- `signature_axis`

## 2.2 Boss

Boss inherits Character fields and also requires:
- `oath_upkeep`
- `trial_required` — default 3
- `boss_axis_profile`
- `default_stance`
- `boss_aura_default`
- `boss_retaliation_default`
- `capture_value` — default 2

Optional Boss fields:
- `stance_system`
- `trial_reward`
- `raid_objective_text`
- `phase_pressure_text`

## 2.3 Pet

Required:
- `support_allowed`
- `pet_role`

Optional:
- `attached_to`
- `escort_rule`
- `companion_trigger`

## 2.4 Relic

Required:
- `relic_type`
- `persistence_mode`

Optional:
- `equip_rule`
- `law_row_interaction`
- `field_anchor_rule`

## 2.5 Name

Required:
- `name_scope`
- `heat_on_install` — default 1
- `heat_on_rewrite` — default 1
- `name_effect_mode`
- `law_row_slot_rule`

Optional:
- `suppressed_text`
- `corrupted_text`
- `arbitration_modifier`
- `injunction_interaction`

## 2.6 Edict

Required:
- `timing_class`
- `resolution_type`

Optional:
- `response_window`
- `heat_delta`
- `audit_hook`
- `replacement_mode`

## 2.7 Site

Required:
- `site_type`
- `raid_condition`
- `raid_reward`
- `guardian_relation_rule`

Optional:
- `on_raided`
- `control_bonus`
- `field_tag_override`

## 2.8 HostSigil

Required:
- `host_sigil_role`
- `slot_limit_rule`
- `persistent_doctrine`

Optional:
- `pre_game_reveal`
- `resource_shaping`
- `jurisdiction_anchor`
- `faction_override_rule`

---

## 3. Derived gameplay flags

The engine may derive these fields, but content teams should understand them:
- `is_unit`
- `is_support`
- `is_law`
- `is_permanent`
- `is_capture_eligible`
- `creates_heat`
- `creates_field_state`
- `creates_line_state`
- `has_reaction_timing`
- `has_interrupt_timing`
- `is_arbitration_piece`

These should not replace authored source fields.

---

## 4. CSV schema

### Canon CSV header order
1. `card_id`
2. `name`
3. `subtitle`
4. `family`
5. `rarity`
6. `set_code`
7. `owner_faction`
8. `stone`
9. `veil`
10. `oath`
11. `cost_sinew`
12. `cost_sigil`
13. `cost_oath`
14. `oath_upkeep`
15. `unit_class`
16. `site_type`
17. `host_sigil_role`
18. `name_scope`
19. `timing_class`
20. `relic_type`
21. `pet_role`
22. `keywords`
23. `tags`
24. `rules_text`
25. `flavor_text`
26. `is_unique`
27. `is_legendary`
28. `is_super_rare`
29. `scenario_only`
30. `tutorial_only`
31. `art_prompt_ref`
32. `notes_design`

Family-specific exports may add columns to the right, but these base columns must remain stable.

---

## 5. Canon JSON schema

```json
{
  "card_id": "KK-SET-0001",
  "name": "Example Card",
  "family": "Character",
  "rarity": "Rare",
  "set_code": "SET1",
  "owner_faction": "Neutral",
  "stone": 3,
  "veil": 1,
  "oath": 2,
  "cost": { "sinew": 1, "sigil": 0, "oath": 1 },
  "keywords": ["Ready", "Support"],
  "tags": ["warfield", "river"],
  "rules_text": "When this enters a Warfield, gain 1 Sinew.",
  "flags": {
    "is_unique": false,
    "is_legendary": false,
    "is_super_rare": false,
    "scenario_only": false,
    "tutorial_only": false
  },
  "family_data": {
    "unit_class": "Soldier",
    "support_allowed": true,
    "capture_value": 1
  }
}
```

### Canon JSON rules
- universal fields live at top level
- costs may be grouped as `cost`
- family-specific data belongs in `family_data`
- booleans should remain booleans, not string values

---

## 6. Text templating standard

Card text must use consistent rules language.

### Sentence templates
Use these standard structures:

**Trigger**
- “When [event], [effect].”
- “At the start of [phase], [effect].”
- “After [event], [effect].”

**Static**
- “Units in this Field have [effect].”
- “This Name causes [effect].”

**Replacement**
- “If [event] would happen, [replacement] instead.”

**Conditional**
- “If [condition], [effect].”
- “If you do, [effect].”

**Duration**
- “Until your next Upkeep...”
- “This turn...”
- “While this remains in the Law Row...”

**Limit**
- “Once each turn...”
- “The first time each turn...”

### Reserved terms
Use canonical glossary terms only:
- seize
- suppress
- corrupt
- control
- challenge
- trial
- ready
- exhaust
- enters
- leaves play
- initiate
- controller
- owner
- primary participant
- support unit
- legal target
- if able
- instead
- cannot

Do not invent synonyms casually.

---

## 7. Timing hook fields

Cards may attach to timing via the following authored fields:
- `timing_class`
- `phase_window`
- `trigger_event`
- `replacement_event`
- `response_window`
- `duration_rule`

If a card has a non-default timing behavior, one of these fields should capture it explicitly.

---

## 8. Legality validation rules

### Deck legality checks
- deck size must equal 36
- max 2 copies per name
- max 1 copy of a given Super Rare
- max 1 Host Sigil
- min 12 Characters
- min 2 Sites
- min 4 Pets + Relics combined
- max 3 Bosses
- max 3 Names

### Card-level validation checks
- required universal fields present
- family value valid
- stats non-negative integers
- costs non-negative integers
- keywords valid against glossary
- no unsupported timing class
- no unsupported family-specific field misuse
- rules text non-empty
- unique `card_id`
- canonical `name` must match master export

### Boss validation
- `oath_upkeep` required
- `trial_required` required
- `default_stance` required unless custom `stance_system` provided

### Name validation
- `heat_on_install` and `name_scope` required
- law-row assumptions must remain valid

### Site validation
- `raid_condition` and `raid_reward` required

### Host Sigil validation
- slot behavior must not imply multi-sigil control unless a scenario explicitly permits it

---

## 9. Export normalization rules

When exporting:
- use `name`, not title aliases
- use `family` canonical values exactly
- use integer stats and costs
- keep absent optional fields empty, not invented
- preserve master-card membership from the authoritative export

When ingesting:
- trim whitespace
- normalize family names
- normalize boolean strings to booleans
- reject unknown timing classes
- reject unknown keyword tokens unless approved

---

## 10. Authoring guidance by family

### Characters
Prioritize:
- one clear role
- one axis identity
- one field or line relation if needed

### Bosses
Prioritize:
- trial profile
- stance logic
- aura law or encounter pressure

### Names
Prioritize:
- law effect
- heat implication
- arbitration interaction

### Edicts
Prioritize:
- timing
- legal intervention
- concise resolution

### Sites
Prioritize:
- raid condition
- raid reward
- guardian relation clarity

### Host Sigils
Prioritize:
- deck identity
- persistent doctrine
- slot uniqueness

---

## 11. Final schema rule

The schema exists to stop drift between:
- content docs
- card exports
- game implementation
- rules text

If a new mechanic cannot fit the schema cleanly, update the schema first rather than letting content improvise structure.

---

# Section B — Implementation Specification

**Merged from:** `Kudurru_Kings_Implementation_Spec_v1_0.md`

# Kudurru Kings — Implementation Spec v1.0

## Purpose

This document translates the canonical rules into implementation-facing structures:
- enums
- state transitions
- resolver order
- event hooks
- UI-required state flags
- combat / arbitration / boss pseudocode

This spec is for engineering, QA, and systems design alignment.

---

## 1. Canon enums

### 1.1 Phases
```ts
type Phase =
  | "UPKEEP"
  | "DRAW"
  | "EDICTS"
  | "MAIN"
  | "BATTLE"
  | "CAPTURE"
  | "END";
```

### 1.2 Families
```ts
type CardFamily =
  | "CHARACTER"
  | "BOSS"
  | "PET"
  | "RELIC"
  | "NAME"
  | "EDICT"
  | "SITE"
  | "HOST_SIGIL";
```

### 1.3 Axis
```ts
type Axis = "STONE" | "VEIL" | "OATH";
```

### 1.4 Consequences
```ts
type Consequence = "WOUND" | "DISPLACE" | "SILENCE" | "BIND";
```

### 1.5 Zones
```ts
type Zone =
  | "DECK"
  | "HAND"
  | "FIELD"
  | "LAW_ROW"
  | "RELIC_ROW"
  | "HOST_SIGIL_SLOT"
  | "DISCARD"
  | "EXILE"
  | "CAPTURED"
  | "SCENARIO";
```

### 1.6 Field tags
```ts
type FieldTag = "SANCTUARY" | "THRESHOLD" | "WILDS" | "WARFIELD";
```

### 1.7 Field control
```ts
type FieldControl = "NEUTRAL" | "CONTESTED" | "CONTROLLED";
```

### 1.8 Unit states
```ts
type UnitState =
  | "READY"
  | "EXHAUSTED"
  | "WOUNDED"
  | "DOWNED"
  | "SILENCED"
  | "BOUND"
  | "STAGGERED";
```

### 1.9 Boss stance
```ts
type BossStance = "GUARDED" | "ASCENDANT" | "WRATHFUL" | "EXPOSED";
```

### 1.10 Audit ladder
```ts
type AuditTier = "CLEAR" | "WATCHED" | "CENSOR_WRAITH" | "TRIBUNAL" | "LAWBROKE";
```

### 1.11 Timing class
```ts
type TimingClass = "PHASE_ACTION" | "REACTION" | "INTERRUPT" | "REPLACEMENT" | "STATIC";
```

### 1.12 Arbitration outcome
```ts
type ArbitrationOutcome = "SEIZE" | "SUPPRESS" | "CORRUPT" | "DEFEND";
```

---

## 2. Core state model

```ts
interface GameState {
  gameId: string;
  turnNumber: number;
  activePlayerId: string;
  phase: Phase;
  markTarget: number;
  players: PlayerState[];
  fields: FieldState[];
  lines: LineState[];
  lawRow: LawState[];
  scenario: ScenarioState[];
  eventLog: GameEvent[];
}

interface PlayerState {
  playerId: string;
  seatIndex: number;
  resources: { sinew: number; sigil: number; oath: number };
  marks: number;
  auditHeat: number;
  auditTier: AuditTier;
  deckCount: number;
  handIds: string[];
  discardIds: string[];
  exileIds: string[];
  capturedIds: string[];
  hostSigilId?: string;
  precedentTokens: number;
}

interface PermanentState {
  instanceId: string;
  cardId: string;
  family: CardFamily;
  controllerId: string;
  ownerId: string;
  zone: Zone;
  fieldId?: string;
  stone: number;
  veil: number;
  oath: number;
  wounds: number;
  states: UnitState[];
  suppressed?: boolean;
  corrupted?: boolean;
}

interface BossState extends PermanentState {
  trialAxes: Axis[];
  stance: BossStance;
}

interface FieldState {
  fieldId: string;
  tag: FieldTag;
  occupants: string[];
  controllerId?: string;
  controlState: FieldControl;
  overlays: string[];
}

interface LineState {
  lineId: string;
  fromFieldId: string;
  toFieldId: string;
  states: string[];
}

interface LawState {
  lawId: string;
  cardId: string;
  controllerId: string;
  ownerId: string;
  suppressed: boolean;
  corrupted: boolean;
}
```

---

## 3. State transitions

### 3.1 Wound -> Downed
- if `wounds >= 2`, add `DOWNED`
- do not automatically remove from field
- queue capture eligibility recalculation

### 3.2 Bound legality
- if `BOUND` present but bind conditions are false, remove `BOUND` during state-based check

### 3.3 Silence expiration
- on controller's Upkeep, remove `SILENCED` if its duration expires

### 3.4 Leave and re-enter
- remove all transient states
- treat as new object instance unless the engine intentionally preserves instance identity

### 3.5 Boss stance transitions
Default transition table:
- on enter: `GUARDED`
- after first unique Trial: `ASCENDANT`
- after second unique Trial: `WRATHFUL`
- after third unique Trial: `EXPOSED`

### 3.6 Audit tier transitions
- 0–2: CLEAR
- 3–4: WATCHED
- 5–6: CENSOR_WRAITH
- 7–8: TRIBUNAL
- 9+: LAWBROKE

Recalculate after every Heat change.

---

## 4. Resolver order

Canonical top-level action resolution order:
1. declare action
2. validate legality
3. lock targets / context
4. open response window if allowed
5. apply replacements
6. resolve primary effect
7. apply prevention
8. move cards / set states
9. run state-based checks
10. queue resulting triggers
11. resolve queued triggers in order
12. recalculate derived state
13. check victory

---

## 5. Event hooks

### 5.1 Core events
```ts
type GameEventType =
  | "TURN_STARTED"
  | "PHASE_STARTED"
  | "PHASE_ENDED"
  | "CARD_PLAYED"
  | "CARD_RESOLVED"
  | "RESOURCE_CHANGED"
  | "HEAT_CHANGED"
  | "AUDIT_TIER_CHANGED"
  | "FIELD_CONTROL_CHANGED"
  | "LINE_CROSSED"
  | "GEAS_TRIGGERED"
  | "COMBAT_DECLARED"
  | "SUPPORT_COMMITTED"
  | "COMBAT_TOTALS_LOCKED"
  | "COMBAT_RESOLVED"
  | "CONSEQUENCE_APPLIED"
  | "CONSEQUENCE_CHAIN_APPLIED"
  | "UNIT_CAPTURED"
  | "BOSS_TRIAL_GAINED"
  | "BOSS_STANCE_CHANGED"
  | "ARBITRATION_DECLARED"
  | "ARBITRATION_REVEALED"
  | "ARBITRATION_RESOLVED"
  | "NAME_STATE_CHANGED"
  | "SCENARIO_APPLIED"
  | "MARKS_CHANGED"
  | "VICTORY_CHECK";
```

### 5.2 Mandatory event payload examples
- `RESOURCE_CHANGED`: playerId, before, after, reason
- `HEAT_CHANGED`: playerId, before, after, source
- `COMBAT_DECLARED`: attackerId, defenderId, axis, consequence, fieldId
- `ARBITRATION_RESOLVED`: attackerId, defenderId, targetLawId, finalBids, outcome

---

## 6. Phase action matrix

### UPKEEP
Allowed:
- pay mandatory upkeep
- resolve upkeep triggers
- clear upkeep-expiring states

### DRAW
Allowed:
- draw 1
- resolve draw triggers

### EDICTS
Allowed:
- play Name
- play Edict
- declare Arbitration
- lawful cooling actions if a card allows

### MAIN
Allowed:
- deploy Character / Boss / Pet / Relic / Site / Host Sigil
- perform allowed reposition / setup actions

### BATTLE
Allowed:
- declare combat
- commit support
- spend matching resources
- play valid reactions

### CAPTURE
Allowed:
- declare capture target
- resolve raids
- resolve post-battle seizure/capture conversions

### END
Allowed:
- cleanup
- income gain
- field-control economy
- end-step audit/heat riders
- victory re-check

---

## 7. UI-required state flags

The UI should not infer these loosely. Expose them directly.

### Player flags
- `canPlayName`
- `canPlayEdict`
- `canDeclareArbitration`
- `heatTier`
- `isLawbrokeCandidate`
- `precedentCount`

### Card / unit flags
- `isReady`
- `isExhausted`
- `isDowned`
- `isBound`
- `isSilenced`
- `isCaptureEligible`
- `isBindEligible`
- `isSupportEligible`
- `canInitiateBattle`
- `legalConsequences[]`
- `bossTrialAxes[]`
- `bossIsTrialComplete`
- `bossStance`

### Board flags
- `fieldControlState`
- `fieldControllerId`
- `fieldOverlays[]`
- `lineStates[]`
- `lineWillTriggerGeas`
- `raidEligible`
- `arbitrationTargetable`

---

## 8. Combat resolver pseudocode

```ts
function resolveCombat(input: CombatInput, state: GameState): GameState {
  validateCombatDeclaration(input, state);

  const context = lockCombatContext(input, state);

  commitPrimaryParticipants(context, state);

  openSupportWindow(context, state);
  openSpendWindow(context, state);
  openNarrowReactionWindow(context, state);

  const atkTotal = computeCombatTotal(context.attackerSide, state);
  const defTotal = computeCombatTotal(context.defenderSide, state);

  emit("COMBAT_TOTALS_LOCKED", { atkTotal, defTotal, axis: context.axis });

  if (atkTotal === defTotal) {
    exhaustAllCommitted(context, state);
    emit("COMBAT_RESOLVED", { result: "TIE" });
    return runStateChecks(state);
  }

  const attackerWon = atkTotal > defTotal;
  if (!attackerWon) {
    exhaustAllCommitted(context, state);
    emit("COMBAT_RESOLVED", { result: "DEFENDER_HOLD" });
    return runStateChecks(state);
  }

  applyConsequence(context, state);
  maybeApplyConsequenceChain(context, state);
  exhaustAllCommitted(context, state);

  emit("COMBAT_RESOLVED", { result: "ATTACKER_SUCCESS", consequence: context.consequence });
  return runStateChecks(state);
}
```

---

## 9. Arbitration resolver pseudocode

```ts
function resolveArbitration(input: ArbitrationInput, state: GameState): GameState {
  validateArbitration(input, state);

  const ctx = lockArbitrationContext(input, state);

  emit("ARBITRATION_DECLARED", { targetLawId: ctx.targetLawId });

  collectSecretBids(ctx, state);
  collectPublicModifiers(ctx, state);
  revealBids(ctx, state);
  applyWitnesses(ctx, state);
  applyPrecedent(ctx, state);
  applyCounterClaims(ctx, state);

  const attackerTotal = getFinalArbitrationTotal(ctx.attackerSide);
  const defenderTotal = getFinalArbitrationTotal(ctx.defenderSide);

  spendBids(ctx, state);

  if (attackerTotal <= defenderTotal) {
    addHeat(ctx.attackerId, 1, "ARBITRATION_FAILED", state);
    emit("ARBITRATION_RESOLVED", { outcome: "DEFEND" });
    return runStateChecks(state);
  }

  const outcome = chooseArbitrationOutcome(ctx, state); // SEIZE / SUPPRESS / CORRUPT
  applyArbitrationOutcome(ctx, outcome, state);
  addMarks(ctx.attackerId, 1, "ARBITRATION_SUCCESS", state);

  emit("ARBITRATION_RESOLVED", { outcome });
  return runStateChecks(state);
}
```

---

## 10. Boss resolver pseudocode

```ts
function applyBossTrial(bossId: string, axis: Axis, challengerId: string, state: GameState): GameState {
  const boss = getBoss(bossId, state);
  if (boss.trialAxes.includes(axis)) return state;

  boss.trialAxes.push(axis);
  emit("BOSS_TRIAL_GAINED", { bossId, axis });

  boss.stance = getBossStanceFromTrials(boss.trialAxes.length);
  emit("BOSS_STANCE_CHANGED", { bossId, stance: boss.stance });

  applyBossRetaliationIfNeeded(bossId, challengerId, state);

  return runStateChecks(state);
}
```

---

## 11. Capture validation inputs

```ts
interface CaptureValidationInput {
  activePlayerId: string;
  targetUnitId: string;
  sourceIds?: string[];
  currentPhase: Phase;
  targetStates: UnitState[];
  targetFamily: CardFamily;
  isBossTrialComplete?: boolean;
}
```

Validation checks:
- phase must be CAPTURE unless a card overrides
- target must be enemy-controlled
- target must be Downed or Bound, or explicitly capturable
- if target is Boss and Bind is required, Boss must be Trial-complete unless text overrides
- target must still be on the field or in a capturable relation

---

## 12. Timing windows map

### General
- declaration window
- response window if allowed
- resolution
- state check
- trigger queue

### Combat
- declare
- support
- spend
- narrow reaction
- totals lock
- resolve consequence
- consequence chain
- state check

### Arbitration
- declare target
- secret bid
- public modifier
- reveal
- witness / precedent / counter-claim application
- compare
- outcome application
- state check

### Audit
- trigger
- reduction/replacement
- penalty resolution
- state check

---

## 13. Engineering rules

- one canonical resolver per subsystem
- no UI-owned rules logic
- no bot-owned rules logic
- derived flags must be computed from authoritative state, not guessed
- state-based checks must run after every major resolution

---

## 14. Implementation completion definition

The implementation layer is complete when:
- all enums are frozen
- all action legality checks are explicit
- combat, arbitration, capture, and boss trial resolution are deterministic
- UI flags match rule state exactly
- event log is sufficient to replay a turn without ambiguity

---

# Section C — Shipping Production Addendum v1.0

## Purpose

This section records the remaining engineering/content production gaps that still exist even though schema and implementation structure are defined.

## C.1 Card-production completion requirements
Shipping requires:
- every card record to pass schema validation
- every family-specific field to be populated where required
- every timing-hook field to be assigned where applicable
- final text templating cleanup
- final numeric tuning pass
- final legality validation against shipping formats

## C.2 Multiplayer implementation target
Shipping engineering target:
- full support for 2, 3, and 4 simultaneous players
- more than 4 only if validated for gameplay quality and system performance

Required engineering completion includes:
- turn-order support
- multiplayer targeting
- arbitration in multiplayer
- field-control recalculation for 3–4 players
- simultaneous-win resolution
- concession/elimination handling
- 4-player UI scaling and state visibility
- performance stability under 4-player resolution density

## C.3 Canon-reconciliation completion rule
The build is not complete until current implementation behavior no longer conflicts with canonical phase, combat, arbitration, boss, state, and visibility doctrine.

## C.4 Live-tuning completion rule
Numerical balance remains open until:
- final cost curves are locked
- per-family rate bands are locked
- matchup spread targets are defined
- live balance thresholds are defined
- card-by-card tuning outcomes are accepted
---

# Section D — Reconciliation Patch Addendum v1.0

## Purpose

This addendum records the audited engineering reconciliation between shipping doctrine and the current build snapshot.

## D.1 Multiplayer engineering reconciliation
Where older embedded wording implied 3–4 players were optional support, the current engineering target is now reconciled to:

- 2-player shipping support
- 3-player shipping support
- 4-player shipping support
- more than 4 only if validated

2-player remains the primary balance baseline, but 3–4 players are no longer treated as optional-only implementation scope.

## D.2 Current build snapshot recorded for engineering
The current Base44 build presently reflects:
- 7-phase turn progression
- 4-seat player presentation
- phase-done synchronization
- draw-to-hand-limit behavior rather than canonical draw-1
- simplified combat resolver shape
- direct implemented capture scoring flow
- end-step resource gain of +1 Sinew / +1 Sigil / +1 Oath

These facts should be treated as the current implementation baseline for reconciliation work.

## D.3 Engineering consequence
Engineering completion now requires not only shipping support for 2–4 players, but also explicit closure of the following drift:
- draw model reconciliation
- combat resolver reconciliation
- arbitration depth reconciliation
- field-control and visibility reconciliation
- multiplayer UI/state legibility for 3–4 active players
