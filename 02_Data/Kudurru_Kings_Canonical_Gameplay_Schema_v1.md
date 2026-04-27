# Kudurru Kings — Canonical Gameplay Schema v1

## 0. Purpose

This document defines the **canonical gameplay data schema** for Kudurru Kings.

It exists to translate **Shipping Rules v1** into a build-enforceable data model. The schema is the single source of truth for gameplay data. Export files, render files, production sheets, and convenience CSVs must be generated from this schema rather than manually maintained in parallel.

This schema is designed to:
- support deterministic combat,
- support rules legality without relying on prose-only text,
- support deck validation,
- support boss trials and capture logic,
- support law/arbitration systems,
- support UI state visibility,
- and support export/regeneration for production pipelines.

---

## 1. Data authority order

1. **Shipping Rules v1**
2. **Canonical Gameplay Schema v1**
3. Canonical gameplay master data built on this schema
4. Generated export / production / render files

---

## 2. Record model

The canonical gameplay master is **one row per card record**.

Each row must fully describe:
- identity,
- family,
- legality,
- costs,
- stats,
- states supported,
- timing permissions,
- scoring hooks,
- faction and rarity,
- and family-specific gameplay attributes.

A row may omit family-specific fields only when those omissions are legal under the schema rules below.

---

## 3. Field classes

Fields are grouped into these classes:
- **Identity**
- **Classification**
- **Legality**
- **Economy / Costs**
- **Combat Stats**
- **State / Lifecycle**
- **Timing / Rules Engine**
- **Scoring**
- **Law / Heat / Arbitration**
- **Board / Spatial**
- **Family-Specific Extensions**
- **UX / Content Support**
- **Pipeline / Export Support**

---

## 4. Global rules for schema design

### 4.1 No critical prose-only legality
If a rule affects legality, timing, state transition, scoring, or engine evaluation, it must exist in a structured field whenever practical.

### 4.2 Prose is supplemental
`rules_text` is supplemental explanatory text. It may elaborate on behavior, but it must not be the only source of any critical rules behavior that can be modeled structurally.

### 4.3 Family-specific nulls are allowed
Fields that do not apply to a family may be blank/null only if the schema explicitly allows null for that family.

### 4.4 Deprecated legacy fields are removed
The following legacy gameplay fields are removed from canonical gameplay authority:
- `wind`
- `eye`
- `weight`

### 4.5 Export-only fields are not gameplay authority
Presentation/export fields may be derived downstream but are not part of gameplay authority unless explicitly included here.

---

## 5. Canonical field dictionary

## 5.1 Identity fields

| Field | Type | Required | Notes |
|---|---|---:|---|
| `card_id` | string | yes | Permanent unique identifier. Never reused. |
| `card_slug` | string | yes | Stable machine-safe identifier. |
| `card_name` | string | yes | Display name. |
| `set_code` | string | yes | Set / release grouping. |
| `card_number` | integer | yes | Human-facing collector/order number. |
| `version_code` | string | no | For alternate printings or rules-compatible variants. |
| `is_reprint` | boolean | yes | True if this record is a reprint. |
| `source_card_id` | string | no | Source identity if reprint/variant. |

### 5.1.1 Identity constraints
- `card_id` must be globally unique.
- `card_slug` must be globally unique.
- `card_name` may repeat only if allowed by reprint/variant rules.

---

## 5.2 Classification fields

| Field | Type | Required | Notes |
|---|---|---:|---|
| `card_family` | enum | yes | Character, Boss, Edict, HostSigil, Name, Pet, Relic, Site |
| `owner_faction` | enum | yes | BorderstoneGuild, FloodbornPact, SkyloomTemple, UnderwellKeepers, Fateforge |
| `rarity` | enum | yes | Common, Uncommon, Rare, SuperRare, Legendary, Ultra |
| `subtype_primary` | string | no | Family-specific subtyping. |
| `subtype_secondary` | string | no | Optional extra subtype. |
| `trait_tags` | string[] | yes | Searchable gameplay traits. |
| `keyword_tags` | string[] | yes | Structured gameplay keywords. |

### 5.2.1 Classification constraints
- Every launch card must have exactly one `owner_faction`.
- No launch card may have a neutral/null faction.
- `rarity = Ultra` is allowed only for Anu and Adamu.

---

## 5.3 Legality fields

| Field | Type | Required | Notes |
|---|---|---:|---|
| `is_collectible` | boolean | yes | Collectible card vs scenario/system object. |
| `is_standard_legal` | boolean | yes | Standard legality flag. |
| `scenario_only` | boolean | yes | Restricted to scenario generation/use. |
| `tutorial_only` | boolean | yes | Restricted to tutorial content. |
| `is_unique` | boolean | yes | Only one instance may legally exist under uniqueness rules. |
| `is_legendary` | boolean | yes | Used for deck/build/rules constraints as applicable. |
| `deck_copy_limit` | integer | yes | Maximum copies allowed in deck. |
| `requires_faction_lock` | boolean | yes | Whether the card imposes faction-build restrictions. |
| `allowed_splash` | boolean | yes | Whether card may appear outside a strict faction lock if one exists systemically. |
| `legal_player_counts` | string[] | yes | e.g. ["1","2","3","4"] |

### 5.3.1 Legality constraints
- `deck_copy_limit` must reflect deck rules and card-specific exceptions.
- `scenario_only = true` implies `is_standard_legal = false` unless explicitly overridden later by format rules.

---

## 5.4 Economy / cost fields

| Field | Type | Required | Notes |
|---|---|---:|---|
| `cost_sinew` | integer | yes | Base Sinew cost. Default 0 if none. |
| `cost_sigil` | integer | yes | Base Sigil cost. Default 0 if none. |
| `cost_oath` | integer | yes | Base Oath cost. Default 0 if none. |
| `upkeep_oath` | integer | yes | Oath upkeep; especially used by Bosses. Default 0. |
| `cost_scaling_rule` | enum | no | None, DynamicByState, DynamicByField, DynamicByHeat, DynamicByScenario, Custom |
| `cost_scaling_value` | string | no | Encoded structured parameters or rule ref. |
| `heat_cost` | integer | yes | Direct Heat cost if any. Default 0. |

### 5.4.1 Economy constraints
- All cost fields are non-negative integers.
- Bosses generally use `upkeep_oath > 0` unless explicitly exceptional.

---

## 5.5 Combat stats fields

| Field | Type | Required | Notes |
|---|---|---:|---|
| `stone` | integer | family-required | Required for Character, Boss, Pet if combat-capable. |
| `veil` | integer | family-required | Required for Character, Boss, Pet if combat-capable. |
| `authority` | integer | family-required | Required for Character, Boss, Pet if combat-capable. |
| `vitality` | integer | family-required | Required for combat-capable cards. |
| `guard` | integer | yes | Default 0. Supports stat + protector behavior. |
| `first_strike` | boolean | yes | Timing ability flag. |
| `initiative` | integer | yes | Combat sequencing value. Default 0 if not applicable. |
| `can_attack` | boolean | yes | Whether card may initiate Battle. |
| `can_support` | boolean | yes | Whether card may act as supporter. |
| `support_value_rule` | enum | yes | None, HalfRoundedUp, PrintedValue, Custom |

### 5.5.1 Combat constraints
- `stone`, `veil`, `authority`, and `vitality` are required for combat-capable cards.
- Non-combat cards may set these to 0 and `can_attack = false`, `can_support = false`.

---

## 5.6 State / lifecycle fields

| Field | Type | Required | Notes |
|---|---|---:|---|
| `wound_threshold` | integer | family-required | Default 2 for most normal combat units unless overridden. |
| `supports_wounded_state` | boolean | yes | Default true for combat-capable cards. |
| `supports_downed_state` | boolean | yes | Default true for combat-capable cards. |
| `supports_bound_state` | boolean | yes | Whether Bound can apply. |
| `supports_defeated_state` | boolean | yes | Whether Defeated can apply. |
| `downed_marker_type` | enum | yes | None, Flip, Rotate, Token, Custom. Default Flip where applicable. |
| `counts_for_field_control_when_downed` | boolean | yes | Locked false for normal rules. |
| `counts_for_field_control_when_defeated` | boolean | yes | Locked false for normal rules. |
| `occupies_slot_when_downed` | boolean | yes | Locked true where downed applies. |
| `occupies_slot_when_defeated` | boolean | yes | Locked true where defeated applies. |
| `targetable_when_downed` | boolean | yes | Locked true for standard rules. |
| `targetable_when_defeated` | boolean | yes | Locked false for standard rules. |
| `capturable_when_downed` | boolean | yes | Not sufficient by itself; capture legality also requires Bound. |
| `capturable_when_defeated` | boolean | yes | Locked false for standard rules. |
| `auto_restore_rounds_if_defeated` | integer | yes | Default 2 for standard defeated behavior. |
| `defeated_restore_destination_primary` | enum | yes | Hand |
| `defeated_restore_destination_fallback` | enum | yes | Deck |

### 5.6.1 Lifecycle constraints
- Normal unit capture pipeline requires `Downed -> Bound -> Capture`.
- `targetable_when_defeated` must default to false.
- `capturable_when_defeated` must default to false.

---

## 5.7 Timing / rules engine fields

| Field | Type | Required | Notes |
|---|---|---:|---|
| `play_timing` | enum[] | yes | Upkeep, Draw, Edicts, Main, Battle, Resolution, End, ReactionWindow, Custom |
| `timing_class` | enum | yes | Action, Reaction, Triggered, Static, Replacement, Interrupt, Passive |
| `legal_zones_to_play_from` | enum[] | yes | Hand, Field, LawArea, ScenarioSpace, Custom |
| `enters_play_zone` | enum | yes | Field, LawArea, SupportRow, SiteRow, HostSlot, None |
| `leaves_play_default_destination` | enum | yes | Discard, DeckReturn, StayFieldDefeated, Exile, Custom |
| `trigger_windows` | enum[] | yes | Structured trigger hooks. |
| `resolution_priority_group` | integer | yes | Ordering bucket if needed. |
| `requires_target` | boolean | yes | Whether card/effect needs explicit target selection. |
| `target_rule_ref` | string | no | Structured rule reference for targets. |
| `can_be_played_during_opponent_turn` | boolean | yes | Explicit timing permission. |
| `consumes_play_action` | boolean | yes | For action economy if used. |

---

## 5.8 Scoring fields

| Field | Type | Required | Notes |
|---|---|---:|---|
| `mark_reward_capture` | integer | yes | Default 0 if none. |
| `mark_reward_plain_defeat` | integer | yes | Default 0 if none. |
| `mark_reward_name_seizure` | integer | yes | Usually 0 except rule-bearing objects. |
| `mark_reward_site_raid` | integer | yes | Usually 0 except Sites/scenario objects. |
| `mark_reward_arbitration_no_seizure` | integer | yes | Usually 0 except law objects if modeled directly. |
| `score_overlap_rule` | enum | yes | HigherSingleReward, Cumulative, Replace, Custom |

### 5.8.1 Default scoring constraints
- Ordinary captured Character: `mark_reward_capture = 1`
- Boss capture: `mark_reward_capture = 2`
- Ordinary plain defeat: `mark_reward_plain_defeat = 1`
- Site raid objects should support `mark_reward_site_raid = 2`
- Rarity must not modify scoring directly.

---

## 5.9 Law / Heat / Arbitration fields

| Field | Type | Required | Notes |
|---|---|---:|---|
| `is_name_object` | boolean | yes | Persistent law object flag. |
| `is_edict_object` | boolean | yes | One-shot law/tactical play flag. |
| `heat_on_install` | integer | yes | Default 0; Names default 1 unless overridden. |
| `heat_on_rewrite_rule` | enum | yes | None, ByCardValue, Fixed, Custom |
| `heat_on_support` | integer | yes | May be negative if support relieves Heat. |
| `heat_spend_allowed` | boolean | yes | Whether card/system may spend Heat. |
| `heat_spend_use_tags` | string[] | yes | e.g. revival, recovery |
| `arbitration_bid_enabled` | boolean | yes | Relevant for Name/law interactions. |
| `arbitration_success_options` | enum[] | yes | Seize, Suppress, Corrupt |
| `arbitration_tie_rule` | enum | yes | FaceOffChain, DefenderWins, Custom |
| `supports_injunctions` | boolean | yes | Expanded arbitration support flag. |

### 5.9.1 Law constraints
- Names must set `is_name_object = true`.
- Edicts must set `is_edict_object = true`.
- Edicts are one-shot and should not use persistent board-state flags unless specifically exceptional.

---

## 5.10 Board / spatial fields

| Field | Type | Required | Notes |
|---|---|---:|---|
| `field_relevance` | boolean | yes | Whether card interacts with Field system. |
| `line_relevance` | boolean | yes | Whether card interacts with Line system. |
| `geasa_relevance` | boolean | yes | Whether card creates/triggers/modifies Geasa. |
| `field_tag_affinity` | enum[] | no | Sanctuary, Threshold, Wilds, Warfield |
| `site_control_relevant` | boolean | yes | Whether control of this object matters for Site-related rules. |
| `objective_control_relevant` | boolean | yes | Whether this object contributes to Objective control. |
| `ready_combat_unit_for_control` | boolean | yes | Whether this card counts as a ready combat unit for End-phase Sinew evaluation. |
| `blocks_slot_when_present` | boolean | yes | Occupancy logic support. |

---

## 5.11 Boss-specific fields

| Field | Type | Required | Notes |
|---|---|---:|---|
| `boss_trial_required` | integer | Boss-required | Default 3. |
| `boss_trial_axes_required` | enum[] | Boss-required | Stone, Veil, Authority |
| `boss_trial_repeat_counts` | boolean | Boss-required | Default false. |
| `boss_capturable_before_trial_complete` | boolean | Boss-required | Default false. |
| `boss_stance_start` | enum | Boss-required | Guarded |
| `boss_stance_progression` | enum[] | Boss-required | Guarded, Ascendant, Wrathful, Exposed |
| `boss_has_aura` | boolean | Boss-required | Default as printed. |
| `boss_has_retaliation` | boolean | Boss-required | Default as printed. |
| `boss_mark_reward_capture` | integer | Boss-required | Default 2 |

---

## 5.12 Site-specific fields

| Field | Type | Required | Notes |
|---|---|---:|---|
| `site_type` | enum | Site-required | Family-specific site subtype. |
| `site_raid_enabled` | boolean | Site-required | Default true unless special case. |
| `raid_condition_ref` | string | Site-required | Structured rule ref. |
| `raid_reward_marks` | integer | Site-required | Default 2 |
| `site_generates_sigil_income` | boolean | Site-required | Important for End-phase logic. |

---

## 5.13 Name-specific fields

| Field | Type | Required | Notes |
|---|---|---:|---|
| `name_scope` | enum | Name-required | Self, Field, Global, Opponent, Objective, Custom |
| `name_persistent` | boolean | Name-required | Default true |
| `name_install_heat` | integer | Name-required | Default 1 |
| `name_rewrite_heat_rule` | enum | Name-required | Usually ByCardValue |
| `name_arbitrable` | boolean | Name-required | Default true |

---

## 5.14 Edict-specific fields

| Field | Type | Required | Notes |
|---|---|---:|---|
| `edict_one_shot` | boolean | Edict-required | Locked true by default |
| `edict_window_tags` | string[] | Edict-required | Legal timing windows |
| `edict_persists_after_resolution` | boolean | Edict-required | Default false |

---

## 5.15 Host Sigil-specific fields

| Field | Type | Required | Notes |
|---|---|---:|---|
| `host_sigil_unique_slot` | boolean | HostSigil-required | Default true |
| `host_sigil_control_relevant` | boolean | HostSigil-required | Default true |
| `host_sigil_generates_sigil_income` | boolean | HostSigil-required | Default true if it should count for End-phase Sigil gain |

---

## 5.16 Pet-specific fields

| Field | Type | Required | Notes |
|---|---|---:|---|
| `pet_support_specialist` | boolean | Pet-required | Whether tuned mainly for support role |
| `pet_faceoff_eligible` | boolean | Pet-required | Locked true if combat-valid |

---

## 5.17 Relic-specific fields

| Field | Type | Required | Notes |
|---|---|---:|---|
| `relic_persistent` | boolean | Relic-required | Default true |
| `relic_row_slot_type` | enum | Relic-required | SupportRow, FieldAttachment, Global, Custom |

---

## 5.18 UX / content support fields

| Field | Type | Required | Notes |
|---|---|---:|---|
| `rules_text` | text | yes | Human-facing explanation, never sole critical rules source. |
| `rules_summary_short` | string | yes | Short UI summary. |
| `lore_text` | text | no | Flavor/lore only. |
| `ui_badge_tags` | string[] | yes | Visible state/identity chips. |
| `search_tags` | string[] | yes | UX findability. |

---

## 5.19 Pipeline / export support fields

| Field | Type | Required | Notes |
|---|---|---:|---|
| `art_prompt_ref` | string | no | Source art prompt reference if used. |
| `render_template_ref` | string | no | Downstream export/render ref. |
| `asset_package_ref` | string | no | Asset packaging reference. |
| `front_visual_family` | string | no | Downstream render support. |
| `back_visual_family` | string | no | Downstream render support. |
| `ultra_visual_override` | boolean | yes | Default false |
| `export_enabled` | boolean | yes | Whether row participates in downstream exports |

### 5.19.1 Pipeline rule
These fields are downstream support only. They must not redefine gameplay behavior.

---

## 6. Family-specific minimum field requirements

## 6.1 Character minimums
Required non-null fields:
- `card_id`
- `card_name`
- `card_family`
- `owner_faction`
- `rarity`
- `cost_sinew`
- `cost_sigil`
- `cost_oath`
- `stone`
- `veil`
- `authority`
- `vitality`
- `wound_threshold`
- `can_attack`
- `can_support`
- `mark_reward_capture`
- `mark_reward_plain_defeat`

## 6.2 Boss minimums
All Character combat minimums plus:
- `upkeep_oath`
- `boss_trial_required`
- `boss_trial_axes_required`
- `boss_capturable_before_trial_complete`
- `boss_stance_start`
- `boss_stance_progression`
- `boss_mark_reward_capture`

## 6.3 Name minimums
Required non-null fields:
- `card_id`
- `card_name`
- `card_family`
- `owner_faction`
- `rarity`
- `cost_sinew`
- `cost_sigil`
- `cost_oath`
- `is_name_object`
- `name_scope`
- `name_persistent`
- `name_install_heat`
- `name_rewrite_heat_rule`
- `name_arbitrable`

## 6.4 Edict minimums
Required non-null fields:
- `card_id`
- `card_name`
- `card_family`
- `owner_faction`
- `rarity`
- `cost_sinew`
- `cost_sigil`
- `cost_oath`
- `is_edict_object`
- `edict_one_shot`
- `edict_window_tags`
- `edict_persists_after_resolution`

## 6.5 Site minimums
Required non-null fields:
- `card_id`
- `card_name`
- `card_family`
- `owner_faction`
- `rarity`
- `site_type`
- `site_raid_enabled`
- `raid_condition_ref`
- `raid_reward_marks`
- `site_generates_sigil_income`

## 6.6 Host Sigil minimums
Required non-null fields:
- `card_id`
- `card_name`
- `card_family`
- `owner_faction`
- `rarity`
- `host_sigil_unique_slot`
- `host_sigil_control_relevant`
- `host_sigil_generates_sigil_income`

## 6.7 Pet minimums
Required non-null fields:
- `card_id`
- `card_name`
- `card_family`
- `owner_faction`
- `rarity`
- combat fields if combat-capable
- `pet_faceoff_eligible`

## 6.8 Relic minimums
Required non-null fields:
- `card_id`
- `card_name`
- `card_family`
- `owner_faction`
- `rarity`
- `relic_persistent`
- `relic_row_slot_type`

---

## 7. Rules-engine derived values

These values should be computed by engine/runtime rather than authored manually when possible:
- current_ready_state
- current_exhausted_state
- current_wound_count
- current_downed_state
- current_bound_state
- current_defeated_state
- current_capture_eligibility
- current_field_control_status
- current_objective_control_status
- current_end_phase_income_preview
- current_trial_progress
- current_heat_total

These are **runtime state values**, not static card-authoring fields.

---

## 8. Validation rules

## 8.1 Global validation
- Every row must have a unique `card_id` and `card_slug`.
- Every launch row must have a valid `owner_faction`.
- Every row must use canonical rarity values only.
- No canonical row may include deprecated gameplay fields.

## 8.2 Combat validation
- If `can_attack = true` or `can_support = true`, then `stone`, `veil`, `authority`, `vitality`, and `wound_threshold` must be present.
- `wound_threshold` must be >= 1.
- `vitality` must be >= 1 for combat-capable rows.

## 8.3 Boss validation
- Boss rows must define trial requirements and stance data.
- Boss rows must define capture legality before trial completion.
- Boss rows must define Oath upkeep.

## 8.4 Name validation
- Name rows must define heat install/rewrite behavior.
- Name rows must define arbitration relevance.

## 8.5 Site validation
- Site rows must define raid condition and raid reward.
- Site rows must define whether they satisfy End-phase Sigil gain condition.

## 8.6 Host Sigil validation
- Host Sigil rows must define slot uniqueness.
- Host Sigil rows must define whether they satisfy End-phase Sigil gain condition.

## 8.7 Scoring validation
- Rarity must not alter scoring fields.
- Score overlap rule must be explicitly set.

---

## 9. Recommended canonical storage format

### 9.1 Authoring format
Use a canonical spreadsheet or table with exact schema columns.

### 9.2 Exchange format
Generate machine exports as needed, such as:
- CSV
- JSON
- engine-ready data bundles

### 9.3 Normalization guidance
Prefer:
- enums over prose when values are finite,
- booleans over ambiguous text when binary,
- arrays/tags for repeatable structured flags,
- rule refs for complex repeated systems.

---

## 10. Deprecated-to-canonical migration direction

### 10.1 Hard removals
Remove from gameplay authority:
- `wind`
- `eye`
- `weight`

### 10.2 Renames / replacements
- combat-axis `oath` stat -> `authority`
- vague faction/source text -> `owner_faction`
- prose-only legality -> structured legality fields
- prose-only boss/site/name mechanics -> family-specific fields

### 10.3 Keep but formalize
Keep and formally define:
- `guard`
- `first_strike`
- `initiative`

---

## 11. Build outputs that must derive from this schema

The following must be generated from the canonical gameplay master using this schema:
- deck builder legality views
- gameplay engine card data
- runtime UI data bindings
- export `master.csv`
- export `production_master.csv`
- render pack mappings
- scenario/objective integrations

---

## 12. Immediate next implementation artifacts

After adopting this schema, the next required artifacts are:
1. **CSV Migration Map v1**
2. **Acceptance Test Suite v1**
3. **Resolver / State Machine Spec v1**
4. regenerated export files

This schema should be treated as the canonical gameplay data contract for Kudurru Kings.

