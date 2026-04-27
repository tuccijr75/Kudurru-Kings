# Kudurru Kings — CSV Migration Map v1

## 0. Purpose

This document defines how to migrate existing gameplay spreadsheets/CSVs into the **Canonical Gameplay Schema v1**.

It is the bridge between:
- legacy gameplay masters,
- partially normalized export files,
- and the new canonical gameplay master.

This migration map exists to make the transition **mechanical**, not interpretive.

---

## 1. Migration authority order

1. **Shipping Rules v1**
2. **Canonical Gameplay Schema v1**
3. **This Migration Map v1**
4. Current legacy masters and export files

If a legacy value conflicts with Shipping Rules v1 or Gameplay Schema v1, the legacy value loses.

---

## 2. Source files in scope

This migration map applies to these source categories:
- legacy gameplay master CSVs
- legacy unit master CSVs
- export `master.csv`
- export `production_master.csv`
- any supplemental faction/content assignment sheets used to backfill missing canonical fields

### 2.1 Source-of-truth rule
The canonical gameplay master created from this migration becomes the only gameplay-authoritative dataset.

### 2.2 Non-authoritative files
`master.csv` and `production_master.csv` are downstream outputs only. They are not patched by hand except for emergency diagnostics. They must be regenerated from the canonical gameplay master after migration.

---

## 3. Target output

The target output of this migration is:
- **one canonical gameplay master table**
- one row per card record
- with exact fields required by Gameplay Schema v1
- no deprecated gameplay-authority columns
- no critical gameplay logic stored only in prose

Recommended working file name:
- `gameplay_master_v1`

---

## 4. Migration phases

### Phase 1 — Freeze sources
- duplicate all current masters into a frozen archive snapshot
- mark them read-only for gameplay authority purposes
- identify the working migration copy

### Phase 2 — Build canonical column set
- create empty canonical gameplay master using Gameplay Schema v1 headers
- do not begin by editing export files

### Phase 3 — Hard-map identity/classification/economy/combat fields
- map direct carry-over fields first
- rename legacy fields where canonical replacements are explicit
- delete deprecated fields immediately from canonical authority

### Phase 4 — Backfill family-specific systems
- boss trials
- names/arbitration
- sites/raids
- host sigils
- faction ownership
- legality flags

### Phase 5 — Normalize rules text into structured fields
- move any repeated legality/timing/scoring/state logic out of prose
- retain prose as explanation only

### Phase 6 — Validate
- run row-level validation
- run family-level validation
- run deck legality validation assumptions
- run scoring/state-system validation

### Phase 7 — Regenerate downstream exports
- generate `master.csv`
- generate `production_master.csv`
- regenerate render/export support as needed

---

## 5. Hard removals

These columns are removed from canonical gameplay authority and must not appear in the new canonical gameplay master:
- `wind`
- `eye`
- `weight`

### 5.1 Handling rule
- If these values have no approved gameplay meaning in Shipping Rules v1, drop them.
- Do not preserve them as gameplay fields.
- Do not rename them into unofficial replacement fields.
- If historically useful, keep them only in archived frozen source snapshots, not in canonical authority.

---

## 6. Hard renames / canonical replacements

## 6.1 Confirmed renames

| Legacy / old meaning | Canonical field | Action |
|---|---|---|
| combat-axis `oath` stat | `authority` | rename |
| vague faction/source column(s) | `owner_faction` | normalize |
| prose-only legality | structured legality fields | expand / split |
| prose-only boss/site/name behavior | family-specific schema fields | expand / split |
| freeform cost language | `cost_sinew`, `cost_sigil`, `cost_oath` | normalize |

### 6.1.1 Important note on Oath vs Authority
- **Oath** remains the resource name.
- **Authority** is the combat-axis stat.
- Any old combat-stat column still named `oath` must be migrated to `authority`.

---

## 7. Keep but formalize

These legacy gameplay fields remain, but must be redefined under canonical schema support:
- `guard`
- `first_strike`
- `initiative`

### 7.1 Required action
- carry forward these values if present
- normalize type and default values
- ensure every relevant row has explicit value, not blank ambiguity
- define gameplay meaning strictly in implementation docs/tests

---

## 8. Direct carry-over mappings

These fields are expected to carry directly or near-directly into the canonical gameplay master where present.

| Legacy field | Canonical field | Action |
|---|---|---|
| `card_id` | `card_id` | carry |
| `name` | `card_name` | rename |
| `card_name` | `card_name` | carry |
| `card_family` | `card_family` | carry/normalize enum |
| `rarity` | `rarity` | normalize enum vocabulary |
| `stone` | `stone` | carry |
| `veil` | `veil` | carry |
| `oath` (combat stat) | `authority` | rename |
| `initiative` | `initiative` | carry |
| `guard` | `guard` | carry |
| `first_strike` | `first_strike` | carry |
| `rules_text` | `rules_text` | carry, then normalize structured logic out |
| `lore_text` | `lore_text` | carry |

### 8.1 Common legacy aliases to inspect
Where current files use alternate naming, normalize into canonical equivalents:
- `name` -> `card_name`
- `family` -> `card_family`
- `faction` / `owner` / `source_faction` -> `owner_faction`
- `rank` / `unit_rank` -> evaluate into subtype or remove if non-canonical
- `text` / `effect_text` -> `rules_text`

---

## 9. New canonical fields that require backfill

These fields are required by the canonical schema and will usually not be fully available in legacy masters. They must be backfilled.

## 9.1 Identity / classification backfills
- `card_slug`
- `set_code`
- `card_number`
- `is_reprint`
- `source_card_id`
- `subtype_primary`
- `subtype_secondary`
- `trait_tags`
- `keyword_tags`

## 9.2 Legality backfills
- `is_collectible`
- `is_standard_legal`
- `scenario_only`
- `tutorial_only`
- `is_unique`
- `is_legendary`
- `deck_copy_limit`
- `requires_faction_lock`
- `allowed_splash`
- `legal_player_counts`

## 9.3 Economy backfills
- `cost_sinew`
- `cost_sigil`
- `cost_oath`
- `upkeep_oath`
- `cost_scaling_rule`
- `cost_scaling_value`
- `heat_cost`

## 9.4 Combat/state backfills
- `vitality`
- `wound_threshold`
- `can_attack`
- `can_support`
- `support_value_rule`
- `supports_wounded_state`
- `supports_downed_state`
- `supports_bound_state`
- `supports_defeated_state`
- `downed_marker_type`
- `counts_for_field_control_when_downed`
- `counts_for_field_control_when_defeated`
- `occupies_slot_when_downed`
- `occupies_slot_when_defeated`
- `targetable_when_downed`
- `targetable_when_defeated`
- `capturable_when_downed`
- `capturable_when_defeated`
- `auto_restore_rounds_if_defeated`
- `defeated_restore_destination_primary`
- `defeated_restore_destination_fallback`

## 9.5 Timing/rules-engine backfills
- `play_timing`
- `timing_class`
- `legal_zones_to_play_from`
- `enters_play_zone`
- `leaves_play_default_destination`
- `trigger_windows`
- `resolution_priority_group`
- `requires_target`
- `target_rule_ref`
- `can_be_played_during_opponent_turn`
- `consumes_play_action`

## 9.6 Scoring backfills
- `mark_reward_capture`
- `mark_reward_plain_defeat`
- `mark_reward_name_seizure`
- `mark_reward_site_raid`
- `mark_reward_arbitration_no_seizure`
- `score_overlap_rule`

## 9.7 Law/heat/arbitration backfills
- `is_name_object`
- `is_edict_object`
- `heat_on_install`
- `heat_on_rewrite_rule`
- `heat_on_support`
- `heat_spend_allowed`
- `heat_spend_use_tags`
- `arbitration_bid_enabled`
- `arbitration_success_options`
- `arbitration_tie_rule`
- `supports_injunctions`

## 9.8 Board/spatial backfills
- `field_relevance`
- `line_relevance`
- `geasa_relevance`
- `field_tag_affinity`
- `site_control_relevant`
- `objective_control_relevant`
- `ready_combat_unit_for_control`
- `blocks_slot_when_present`

---

## 10. Family-specific backfill rules

## 10.1 Characters
Characters must be backfilled to ensure they have:
- combat axes
- vitality
- wound threshold
- attack/support legality
- plain defeat and capture scoring
- faction ownership
- standard legality

### Character default fill guidance
- `supports_wounded_state = true`
- `supports_downed_state = true`
- `supports_bound_state = true`
- `supports_defeated_state = true`
- `downed_marker_type = Flip`
- `counts_for_field_control_when_downed = false`
- `counts_for_field_control_when_defeated = false`
- `occupies_slot_when_downed = true`
- `occupies_slot_when_defeated = true`
- `targetable_when_downed = true`
- `targetable_when_defeated = false`
- `capturable_when_downed = true`
- `capturable_when_defeated = false`
- `auto_restore_rounds_if_defeated = 2`
- `defeated_restore_destination_primary = Hand`
- `defeated_restore_destination_fallback = Deck`
- `mark_reward_capture = 1`
- `mark_reward_plain_defeat = 1`
- `score_overlap_rule = HigherSingleReward`

## 10.2 Bosses
Bosses require explicit backfill for:
- Oath upkeep
- trial requirement
- required trial axes
- trial repeat rule
- capture legality before trial completion
- stance start and progression
- aura/retaliation flags
- boss capture score

### Boss default fill guidance
- `upkeep_oath > 0` unless explicitly exceptional
- `boss_trial_required = 3`
- `boss_trial_axes_required = [Stone, Veil, Authority]`
- `boss_trial_repeat_counts = false`
- `boss_capturable_before_trial_complete = false`
- `boss_stance_start = Guarded`
- `boss_stance_progression = [Guarded, Ascendant, Wrathful, Exposed]`
- `boss_mark_reward_capture = 2`

## 10.3 Names
Names require explicit backfill for:
- persistence
- install Heat
- rewrite Heat rule
- scope
- arbitration enablement

### Name default fill guidance
- `is_name_object = true`
- `name_persistent = true`
- `name_install_heat = 1`
- `name_rewrite_heat_rule = ByCardValue`
- `name_arbitrable = true`
- `heat_on_install = 1`
- `arbitration_bid_enabled = true`
- `arbitration_success_options = [Seize, Suppress, Corrupt]`
- `arbitration_tie_rule = FaceOffChain`
- `supports_injunctions = true` only when intentionally enabled

## 10.4 Edicts
Edicts require explicit backfill for:
- one-shot status
- legal timing windows
- non-persistence after resolution

### Edict default fill guidance
- `is_edict_object = true`
- `edict_one_shot = true`
- `edict_persists_after_resolution = false`

## 10.5 Sites
Sites require explicit backfill for:
- site subtype
- raid enablement
- raid condition reference
- raid reward
- sigil-income qualification
- control relevance

### Site default fill guidance
- `site_raid_enabled = true` unless card says otherwise
- `raid_reward_marks = 2`
- `site_generates_sigil_income = true` only if qualifying under end-phase rule
- `site_control_relevant = true`

## 10.6 Host Sigils
Host Sigils require explicit backfill for:
- unique slot logic
- control relevance
- sigil-income qualification

### Host Sigil default fill guidance
- `host_sigil_unique_slot = true`
- `host_sigil_control_relevant = true`
- `host_sigil_generates_sigil_income = true` only if it satisfies the end-phase Sigil rule

## 10.7 Pets
Pets require explicit backfill for:
- combat eligibility
- support specialization
- face-off eligibility

### Pet default fill guidance
- `pet_faceoff_eligible = true` if combat-valid
- `can_support = true` unless design says otherwise

## 10.8 Relics
Relics require explicit backfill for:
- persistence
- row/slot type
- timing class

---

## 11. Rarity normalization map

Legacy rarity vocabularies must be normalized into the canonical ladder:
- Common
- Uncommon
- Rare
- Super Rare
- Legendary
- Ultra

### 11.1 Normalization rule
If old rarity labels do not match canonical values exactly, create a temporary translation table during migration.

### 11.2 Recommended translation template
| Legacy rarity | Canonical rarity | Status |
|---|---|---|
| low | Common or Uncommon | requires explicit assignment |
| mid | Uncommon or Rare | requires explicit assignment |
| high | Rare or Super Rare | requires explicit assignment |
| rare | Rare | likely direct |
| super | Super Rare | likely direct |
| ultra | Ultra | direct |
| legendary | Legendary | direct |

### 11.3 Rule
Do not guess at ambiguous rarity remaps in final data. Use a one-time translation decision table and then normalize permanently.

---

## 12. Faction backfill map

Every launch card must be assigned exactly one faction.

### 12.1 Backfill order
1. use locked faction assignment documents if available
2. use explicit faction labels already present in source rows
3. if still missing, assign via approved faction roster mapping
4. no row may ship with blank faction

### 12.2 Validation rule
A launch row with blank `owner_faction` fails migration.

---

## 13. Scoring backfill map

Apply these defaults unless a card-specific rules exception exists:

| Card context | Canonical field values |
|---|---|
| ordinary Character | `mark_reward_capture = 1`, `mark_reward_plain_defeat = 1` |
| Boss | `mark_reward_capture = 2`, boss plain defeat not auto-assumed |
| Name seizure-capable law object | `mark_reward_name_seizure = 1` where applicable |
| Site | `mark_reward_site_raid = 2` where applicable |
| arbitration win without seizure | `mark_reward_arbitration_no_seizure = 1` where modeled/applicable |
| overlap cases | `score_overlap_rule = HigherSingleReward` |

---

## 14. Dynamic income backfill map

These fields matter for the End-phase resource engine.

### 14.1 Sinew condition support
Backfill `ready_combat_unit_for_control` for all combat-capable units.

### 14.2 Sigil condition support
Backfill:
- `site_generates_sigil_income`
- `host_sigil_generates_sigil_income`
- `site_control_relevant`
- `host_sigil_control_relevant`

### 14.3 Oath condition support
Backfill `objective_control_relevant` on any object that contributes to Scenario / Objective control.

---

## 15. Rules-text normalization workflow

Any row whose rules behavior is currently trapped in prose must be normalized in this order:

1. identify legality/timing/state/scoring effects in prose
2. map each one to existing structured schema fields
3. if no field exists, propose schema extension before migration continues
4. reduce `rules_text` to explanatory summary after structure is captured

### 15.1 Priority categories for prose extraction
Normalize these first:
- play timing
- target rules
- attack/support legality
- boss trial behavior
- site raid behavior
- name install/rewrite heat
- arbitration permissions
- defeated/restore behavior
- capture exceptions

---

## 16. Validation gates

## 16.1 Gate 1 — identity integrity
Fail if:
- duplicate `card_id`
- duplicate `card_slug`
- missing `card_name`
- missing `card_family`

## 16.2 Gate 2 — classification integrity
Fail if:
- invalid faction
- blank faction on launch content
- invalid rarity vocabulary
- Ultra assigned to non-Anu/non-Adamu card

## 16.3 Gate 3 — combat integrity
Fail if combat-capable row lacks:
- `stone`
- `veil`
- `authority`
- `vitality`
- `wound_threshold`

## 16.4 Gate 4 — family integrity
Fail if family row lacks required family-specific fields.

## 16.5 Gate 5 — scoring integrity
Fail if:
- scoring fields conflict with canonical defaults without explicit override
- rarity directly changes scoring

## 16.6 Gate 6 — deprecated field integrity
Fail if canonical master still contains:
- `wind`
- `eye`
- `weight`

---

## 17. Export regeneration policy

After migration and validation:
1. generate gameplay-engine export
2. generate `master.csv`
3. generate `production_master.csv`
4. generate UI bindings / render pack refs as needed

### 17.1 Rule
Do not edit export outputs manually to solve gameplay issues. Fix the canonical gameplay master, then regenerate.

---

## 18. Recommended working tabs / sheets

Use these tabs or files during migration:
- `source_legacy_cards`
- `source_legacy_units`
- `source_export_master`
- `source_export_production`
- `rarity_translation`
- `faction_backfill`
- `rules_text_extraction`
- `canonical_gameplay_master`
- `validation_errors`

---

## 19. Migration checklist

- [ ] freeze legacy sources
- [ ] create canonical header sheet
- [ ] map direct carry-over columns
- [ ] rename `oath` combat stat to `authority`
- [ ] remove `wind`, `eye`, `weight`
- [ ] normalize rarity vocabulary
- [ ] backfill faction ownership
- [ ] backfill legality fields
- [ ] backfill family-specific fields
- [ ] normalize scoring fields
- [ ] normalize timing/state fields
- [ ] extract critical rules from prose
- [ ] validate all rows
- [ ] regenerate exports

---

## 20. Immediate next artifact after migration map

After this migration map is approved, the next artifact should be:
- **Acceptance Test Suite v1**

That test suite should validate the exact rule behaviors that the migrated data is intended to support.

