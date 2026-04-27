# Kudurru Kings — Acceptance Test Suite v1

## 0. Purpose

This document defines the **acceptance test suite** for Kudurru Kings.

It exists to verify that:
- **Shipping Rules v1** is implemented correctly,
- **Canonical Gameplay Schema v1** is represented correctly in data,
- **CSV Migration Map v1** is producing valid canonical records,
- and runtime behavior matches the locked game rules.

This test suite is written as a **pass/fail behavior contract**. It is not a design wishlist.

---

## 1. Authority order

1. **Shipping Rules v1**
2. **Canonical Gameplay Schema v1**
3. **CSV Migration Map v1**
4. **Acceptance Test Suite v1**

If a test expectation conflicts with the rules or schema, the rules/schema win and the test must be corrected.

---

## 2. Test suite goals

This suite validates six categories:
- rules correctness
- schema correctness
- migration correctness
- runtime state-machine correctness
- deck legality correctness
- UI-state visibility correctness

---

## 3. Test result format

Every test case should be recorded with:
- `test_id`
- `category`
- `title`
- `preconditions`
- `input/setup`
- `action`
- `expected_result`
- `actual_result`
- `status` = Pass / Fail / Blocked
- `notes`

---

## 4. Test environments

### 4.1 Data validation environment
Used for:
- canonical gameplay master validation
- migration output validation
- export generation validation

### 4.2 Rules simulation environment
Used for:
- combat resolution
- tie Face-off
- state transitions
- boss trials
- arbitration
- scoring
- income conditions

### 4.3 UI verification environment
Used for:
- required state visibility
- readability of income conditions
- visibility of bind/downed/capture/trial states

---

## 5. Global pass criteria

The build passes Acceptance Test Suite v1 only if:
- all critical tests pass,
- no deprecated gameplay fields exist in canonical authority,
- no rules-critical behavior depends solely on prose,
- and no runtime behavior contradicts Shipping Rules v1.

---

# 6. Data and migration validation tests

## ATS-DATA-001 — Canonical master contains no deprecated gameplay fields
**Preconditions:** canonical gameplay master exists

**Action:** inspect canonical schema columns

**Expected result:** canonical master contains no gameplay-authority columns named:
- `wind`
- `eye`
- `weight`

---

## ATS-DATA-002 — Combat-axis `authority` exists and legacy combat-stat `oath` does not
**Action:** inspect canonical combat stat columns

**Expected result:**
- `authority` exists
- legacy combat-stat `oath` does not exist as a combat stat column
- resource `cost_oath` may exist separately

---

## ATS-DATA-003 — Every launch row has valid `owner_faction`
**Action:** validate all launch content rows

**Expected result:** every launch row has one of:
- BorderstoneGuild
- FloodbornPact
- SkyloomTemple
- UnderwellKeepers
- Fateforge

No blanks. No neutral.

---

## ATS-DATA-004 — Canonical rarity vocabulary only
**Action:** inspect `rarity`

**Expected result:** only these values are allowed:
- Common
- Uncommon
- Rare
- SuperRare
- Legendary
- Ultra

---

## ATS-DATA-005 — Ultra restriction
**Action:** inspect all rows with `rarity = Ultra`

**Expected result:** only Anu and Adamu are Ultra.

---

## ATS-DATA-006 — Combat-capable rows have full combat fields
**Action:** validate every row where `can_attack = true` or `can_support = true`

**Expected result:** row must have non-null:
- `stone`
- `veil`
- `authority`
- `vitality`
- `wound_threshold`

---

## ATS-DATA-007 — Boss rows have required boss fields
**Action:** validate all `card_family = Boss`

**Expected result:** boss rows must include:
- `upkeep_oath`
- `boss_trial_required`
- `boss_trial_axes_required`
- `boss_capturable_before_trial_complete`
- `boss_stance_start`
- `boss_stance_progression`

---

## ATS-DATA-008 — Name rows have required law/arbitration fields
**Action:** validate all `card_family = Name`

**Expected result:** name rows must include:
- `is_name_object = true`
- `name_install_heat`
- `name_rewrite_heat_rule`
- `name_arbitrable`
- `arbitration_bid_enabled`

---

## ATS-DATA-009 — Site rows have required raid fields
**Action:** validate all `card_family = Site`

**Expected result:** site rows must include:
- `site_type`
- `site_raid_enabled`
- `raid_condition_ref`
- `raid_reward_marks`

---

## ATS-DATA-010 — Rules-critical logic is not prose-only
**Action:** inspect rows with non-empty `rules_text`

**Expected result:** critical legality/timing/state/scoring logic has structured field support and is not present only in prose.

---

# 7. Deck legality tests

## ATS-DECK-001 — Legal 36-card deck validates
**Setup:** create a deck meeting all Standard rules

**Expected result:** deck validates successfully.

---

## ATS-DECK-002 — Deck size under 36 fails
**Setup:** 35-card deck

**Expected result:** validation fails.

---

## ATS-DECK-003 — Deck size over 36 fails
**Setup:** 37-card deck

**Expected result:** validation fails.

---

## ATS-DECK-004 — Too many copies of named card fails
**Setup:** 3 copies of same normal named card

**Expected result:** validation fails unless that card has explicit override.

---

## ATS-DECK-005 — Too many Super Rare copies fails
**Setup:** 2 copies of same Super Rare

**Expected result:** validation fails.

---

## ATS-DECK-006 — More than one Host Sigil fails
**Setup:** deck with 2 Host Sigils

**Expected result:** validation fails.

---

## ATS-DECK-007 — Fewer than 12 Characters fails
**Setup:** deck with 11 Characters

**Expected result:** validation fails.

---

## ATS-DECK-008 — Fewer than 2 Sites fails
**Setup:** deck with 1 Site

**Expected result:** validation fails.

---

## ATS-DECK-009 — Fewer than 4 support cards from Pets + Relics fails
**Setup:** deck with 3 support cards across Pets + Relics

**Expected result:** validation fails.

---

## ATS-DECK-010 — More than 3 Bosses fails
**Setup:** deck with 4 Bosses

**Expected result:** validation fails.

---

## ATS-DECK-011 — More than 3 Names fails
**Setup:** deck with 4 Names

**Expected result:** validation fails.

---

## ATS-DECK-012 — Hybrid faction deck with no faction-locked conflict passes
**Setup:** multi-faction deck containing only cards legal under hybrid rules

**Expected result:** validation passes.

---

## ATS-DECK-013 — Faction-locked deck conflict fails
**Setup:** include card requiring faction lock plus illegal splash combination

**Expected result:** validation fails.

---

# 8. Match setup and turn-flow tests

## ATS-FLOW-001 — Standard match setup initializes correctly
**Expected result:**
- Scenario/Objective layer loaded
- each player starts with Sinew 2 / Sigil 1 / Oath 1
- each player draws 6
- one free full mulligan available

---

## ATS-FLOW-002 — Draw step refills to 6
**Setup:** active player starts Draw with 4 cards

**Expected result:** player ends Draw with 6 cards unless a replacement rule changes this.

---

## ATS-FLOW-003 — End-step discard trims to 6
**Setup:** player ends turn with 8 cards

**Expected result:** player must discard down to 6.

---

## ATS-FLOW-004 — Turn structure preserves 7-step sequence
**Expected result:**
1. Upkeep
2. Draw
3. Edicts
4. Main
5. Battle
6. Resolution
7. End

---

## ATS-FLOW-005 — Capture is only legal in Resolution
**Setup:** target is Downed+Bound before Resolution

**Expected result:** capture may not be completed during Battle or Main; only during Resolution.

---

# 9. Combat tests

## ATS-COMBAT-001 — Combat requires declared axis
**Expected result:** combat declaration without Stone/Veil/Authority fails.

---

## ATS-COMBAT-002 — Normal successful attack with no special consequence deals 1 wound
**Setup:** successful attack, no enabled special consequence

**Expected result:** defender takes exactly 1 wound to Vitality.

---

## ATS-COMBAT-003 — One supporter per side maximum
**Setup:** attempt to assign 2 supporters to one side

**Expected result:** second supporter assignment is illegal.

---

## ATS-COMBAT-004 — Up to 2 matching resources may be spent
**Setup:** attempt to spend 3 matching resources in one combat

**Expected result:** illegal.

---

## ATS-COMBAT-005 — Supporter relieves Heat
**Setup:** side commits supporter while having Heat > 0

**Expected result:** Heat relief occurs according to implemented support rule, not Heat increase.

---

## ATS-COMBAT-006 — Tie triggers Face-off
**Setup:** combat comparison ties

**Expected result:** Face-off begins immediately.

---

## ATS-COMBAT-007 — Face-off uses top valid combat card only
**Setup:** deck top card is non-combat card, next card is combat-valid

**Expected result:** system reveals top valid combat card, not invalid card.

---

## ATS-COMBAT-008 — Face-off ignores card text
**Setup:** revealed Face-off card has rules text affecting combat

**Expected result:** card text is ignored in Face-off.

---

## ATS-COMBAT-009 — Face-off compares original contested axis only
**Expected result:** revealed cards are compared using the same axis as the tied battle.

---

## ATS-COMBAT-010 — Face-off reshuffles revealed cards back into deck
**Expected result:** after face-off resolves, revealed tie-break cards return to deck and deck is reshuffled.

---

## ATS-COMBAT-011 — Player with no valid Face-off card loses tie-break
**Expected result:** that player loses Face-off immediately.

---

# 10. Vitality, Downed, Bound, Capture, Defeated tests

## ATS-STATE-001 — Most normal units Down at threshold 2 unless overridden
**Setup:** ordinary unit with default threshold takes 2 wounds

**Expected result:** unit becomes Downed.

---

## ATS-STATE-002 — Boss threshold uses printed value, not fixed default 2
**Setup:** boss with printed threshold > 2

**Expected result:** boss does not Down early at 2 unless its printed threshold is 2.

---

## ATS-STATE-003 — Downed unit stays on field
**Expected result:** Downed card remains in field slot.

---

## ATS-STATE-004 — Downed unit flips visually
**Expected result:** Downed card uses flipped marker state.

---

## ATS-STATE-005 — Downed unit does not count for Field control
**Expected result:** Downed unit excluded from Field-control calculations.

---

## ATS-STATE-006 — Downed unit still occupies slot
**Expected result:** Downed unit blocks slot/use as occupied object.

---

## ATS-STATE-007 — Downed unit can still be targeted
**Expected result:** legal effects may still target Downed unit.

---

## ATS-STATE-008 — Bound is illegal unless target is Downed, absent override
**Setup:** non-Downed target with no override

**Expected result:** Bind attempt fails legality.

---

## ATS-STATE-009 — Normal unit capture requires Downed then Bound
**Setup:** target only Downed but not Bound

**Expected result:** capture illegal.

---

## ATS-STATE-010 — Valid Downed+Bound target is Capturable in Resolution
**Setup:** target Downed+Bound during Resolution

**Expected result:** capture legal.

---

## ATS-STATE-011 — Declined valid capture causes Defeated
**Expected result:** target becomes Defeated.

---

## ATS-STATE-012 — Failed capture causes Defeated
**Expected result:** target becomes Defeated.

---

## ATS-STATE-013 — Defeated unit remains on field
**Expected result:** Defeated card stays on field.

---

## ATS-STATE-014 — Defeated unit is not targetable
**Expected result:** targeting Defeated unit fails.

---

## ATS-STATE-015 — Defeated unit is not capturable
**Expected result:** capture attempt against Defeated unit fails.

---

## ATS-STATE-016 — Defeated unit may be revived
**Setup:** revival effect targeting/handling defeated state under allowed rule flow

**Expected result:** revive succeeds if effect allows it.

---

## ATS-STATE-017 — Defeated unit auto-restores after 2 full rounds
**Expected result:** after exactly 2 full rounds, unit leaves defeated field state and restores.

---

## ATS-STATE-018 — Defeated restore prefers hand, then deck
**Setup:** one case with hand space, one case with full hand

**Expected result:**
- with space -> hand
- if full -> deck

---

# 11. Boss system tests

## ATS-BOSS-001 — Boss requires Oath upkeep
**Expected result:** Boss upkeep check occurs during Upkeep.

---

## ATS-BOSS-002 — Boss default trial requirement is 3 unique Trials
**Expected result:** boss requires 3 distinct-axis trial completions unless overridden.

---

## ATS-BOSS-003 — Repeated trial on same axis does not count twice by default
**Expected result:** repeated Stone, Veil, or Authority success on same axis does not increment duplicate trial credit.

---

## ATS-BOSS-004 — Boss not capturable before trial completion
**Expected result:** capture attempt fails unless boss is Trial-complete or override exists.

---

## ATS-BOSS-005 — Boss stance progression follows canonical ladder
**Expected result:** Guarded -> Ascendant -> Wrathful -> Exposed progression functions correctly.

---

## ATS-BOSS-006 — Boss capture scores 2 Marks
**Expected result:** successful boss capture awards 2 Marks.

---

## ATS-BOSS-007 — Boss aura and retaliation flags are respected
**Expected result:** rows enabling these behaviors trigger corresponding engine systems.

---

# 12. Sites, Fields, Lines, and Geasa tests

## ATS-FIELD-001 — Maximum active Fields = 2
**Expected result:** third active Field is illegal or handled by replacement rule.

---

## ATS-FIELD-002 — Field control counts only ready combat units
**Expected result:** End-phase Sinew condition uses only ready combat units across active Fields.

---

## ATS-FIELD-003 — Downed and Defeated units excluded from Field control
**Expected result:** neither contributes to field-control counts.

---

## ATS-FIELD-004 — Site control can satisfy Sigil gain condition
**Expected result:** controlling at least one qualifying Site grants Sigil at End.

---

## ATS-FIELD-005 — Host Sigil control can satisfy Sigil gain condition
**Expected result:** controlling at least one qualifying Host Sigil grants Sigil at End.

---

## ATS-FIELD-006 — Objective control satisfies Oath gain condition
**Expected result:** controlling current Scenario/Objective grants +1 Oath at End.

---

## ATS-FIELD-007 — Fallback Sinew applies if no income condition met
**Expected result:** if player satisfies none of Sinew/Sigil/Oath conditions, they still gain +1 Sinew.

---

## ATS-FIELD-008 — Geasa-relevant crossing triggers legal consequences
**Expected result:** crossing or violating Lines/Geasa rules triggers their defined effects when applicable.

---

## ATS-FIELD-009 — Successful Site raid scores 2 Marks
**Expected result:** legal raid awards 2 Marks.

---

# 13. Names, Edicts, Arbitration, and Heat tests

## ATS-LAW-001 — Name install adds +1 Heat by default
**Expected result:** installing a standard Name increases Heat by 1 unless explicit override exists.

---

## ATS-LAW-002 — Name rewrite Heat follows card-value rule
**Expected result:** rewrite/swap Heat uses ByCardValue logic where applicable.

---

## ATS-LAW-003 — Edict is one-shot
**Expected result:** standard Edict resolves and does not persist after resolution unless explicit exception exists.

---

## ATS-LAW-004 — Arbitration uses hidden Oath bid
**Expected result:** arbitration setup includes concealed Oath bid from relevant participants.

---

## ATS-LAW-005 — Arbitration ties use Face-off chain, not defender auto-win
**Expected result:** tie enters Face-off chain.

---

## ATS-LAW-006 — Arbitration success offers Seize / Suppress / Corrupt
**Expected result:** on success, acting player is offered exactly the legal success modes available.

---

## ATS-LAW-007 — Name seizure awards 1 Mark
**Expected result:** successful seizure scores 1 Mark.

---

## ATS-LAW-008 — Arbitration win without seizure awards 1 Mark where applicable
**Expected result:** rule-supported non-seizure arbitration win awards 1 Mark.

---

## ATS-LAW-009 — Injunction support flag is respected
**Expected result:** rows flagged for injunction support can participate in injunction mechanics.

---

## ATS-HEAT-001 — Heat floor is 0
**Expected result:** no sequence can reduce Heat below 0.

---

## ATS-HEAT-002 — Heat spend removes Heat immediately
**Expected result:** when Heat is spent, the Heat track updates immediately.

---

## ATS-HEAT-003 — Heat spend allowed only for own-card revival/recovery by default
**Expected result:** default Heat spend cannot target opponent recovery or unrelated systems without explicit override.

---

## ATS-HEAT-004 — Heat ladder thresholds display and evaluate correctly
**Expected result:**
- 0–2 Clear
- 3–4 Watched
- 5–6 Censor Wraith
- 7–8 Tribunal
- 9+ Lawbroke

---

# 14. Scoring tests

## ATS-SCORE-001 — Character capture awards 1 Mark

## ATS-SCORE-002 — Boss capture awards 2 Marks

## ATS-SCORE-003 — Name seizure awards 1 Mark

## ATS-SCORE-004 — Site raid awards 2 Marks

## ATS-SCORE-005 — Plain defeat without capture awards 1 Mark for ordinary units

## ATS-SCORE-006 — Rarity does not modify score
**Expected result:** same scoring event yields same Marks regardless of rarity.

---

## ATS-SCORE-007 — Overlap uses higher single reward
**Setup:** event chain where defeat and capture would otherwise overlap

**Expected result:** system grants only the higher single reward.

---

# 15. UI visibility tests

## ATS-UI-001 — Field dominance visible
## ATS-UI-002 — Trial counters visible
## ATS-UI-003 — Audit level visible
## ATS-UI-004 — Name ownership visible
## ATS-UI-005 — Bind status visible
## ATS-UI-006 — Downed status visible
## ATS-UI-007 — Capture eligibility visible
## ATS-UI-008 — Raid eligibility visible
## ATS-UI-009 — End-phase income preview visible

### 15.1 UI pass rule
Each of the above states must be visible or inspectable without requiring hidden debug tools.

---

# 16. Export regeneration tests

## ATS-EXPORT-001 — `master.csv` regenerates from canonical master
**Expected result:** export builds successfully from canonical gameplay master.

---

## ATS-EXPORT-002 — `production_master.csv` regenerates from canonical master
**Expected result:** export builds successfully from canonical gameplay master.

---

## ATS-EXPORT-003 — Exports do not reintroduce deprecated gameplay fields as authoritative columns
**Expected result:** downstream exports may contain presentation data, but no deprecated gameplay field becomes authoritative again.

---

# 17. Release gate

The build may not be considered rules-valid for Shipping Rules v1 unless all of the following are true:
- critical data tests pass
- critical combat/state tests pass
- critical deck legality tests pass
- boss/arbitration/heat tests pass
- scoring tests pass
- UI visibility tests pass
- export regeneration tests pass

---

# 18. Immediate next artifact

After Acceptance Test Suite v1, the next artifact should be:
- **Resolver / State Machine Spec v1**

That document should define the exact runtime order of:
- legality checks
- attack declaration
- modifier application
- tie resolution
- state transitions
- trigger windows
- capture conversion
- scoring application
- end-step income
- and restore behavior.

