# Kudurru Kings — Canonical Gameplay Master Template v1

## 0. Purpose

This document defines the **authoring template** for the canonical gameplay master.

It converts:
- Shipping Rules v1
- Canonical Gameplay Schema v1
- CSV Migration Map v1
- Acceptance Test Suite v1
- Resolver / State Machine Spec v1

into a practical card-authoring table specification.

This is the sheet/template that should be used to build `gameplay_master_v1`.

---

## 1. Authoring rule

The canonical gameplay master must be authored as **one row per card record** using the exact column order in this template.

All downstream exports derive from this table.

---

## 2. Recommended column order

## 2.1 Identity
1. `card_id`
2. `card_slug`
3. `card_name`
4. `set_code`
5. `card_number`
6. `version_code`
7. `is_reprint`
8. `source_card_id`

## 2.2 Classification
9. `card_family`
10. `owner_faction`
11. `rarity`
12. `subtype_primary`
13. `subtype_secondary`
14. `trait_tags`
15. `keyword_tags`

## 2.3 Legality
16. `is_collectible`
17. `is_standard_legal`
18. `scenario_only`
19. `tutorial_only`
20. `is_unique`
21. `is_legendary`
22. `deck_copy_limit`
23. `requires_faction_lock`
24. `allowed_splash`
25. `legal_player_counts`

## 2.4 Economy / cost
26. `cost_sinew`
27. `cost_sigil`
28. `cost_oath`
29. `upkeep_oath`
30. `cost_scaling_rule`
31. `cost_scaling_value`
32. `heat_cost`

## 2.5 Combat stats
33. `stone`
34. `veil`
35. `authority`
36. `vitality`
37. `guard`
38. `first_strike`
39. `initiative`
40. `can_attack`
41. `can_support`
42. `support_value_rule`

## 2.6 State / lifecycle
43. `wound_threshold`
44. `supports_wounded_state`
45. `supports_downed_state`
46. `supports_bound_state`
47. `supports_defeated_state`
48. `downed_marker_type`
49. `counts_for_field_control_when_downed`
50. `counts_for_field_control_when_defeated`
51. `occupies_slot_when_downed`
52. `occupies_slot_when_defeated`
53. `targetable_when_downed`
54. `targetable_when_defeated`
55. `capturable_when_downed`
56. `capturable_when_defeated`
57. `auto_restore_rounds_if_defeated`
58. `defeated_restore_destination_primary`
59. `defeated_restore_destination_fallback`

## 2.7 Timing / rules engine
60. `play_timing`
61. `timing_class`
62. `legal_zones_to_play_from`
63. `enters_play_zone`
64. `leaves_play_default_destination`
65. `trigger_windows`
66. `resolution_priority_group`
67. `requires_target`
68. `target_rule_ref`
69. `can_be_played_during_opponent_turn`
70. `consumes_play_action`

## 2.8 Scoring
71. `mark_reward_capture`
72. `mark_reward_plain_defeat`
73. `mark_reward_name_seizure`
74. `mark_reward_site_raid`
75. `mark_reward_arbitration_no_seizure`
76. `score_overlap_rule`

## 2.9 Law / Heat / Arbitration
77. `is_name_object`
78. `is_edict_object`
79. `heat_on_install`
80. `heat_on_rewrite_rule`
81. `heat_on_support`
82. `heat_spend_allowed`
83. `heat_spend_use_tags`
84. `arbitration_bid_enabled`
85. `arbitration_success_options`
86. `arbitration_tie_rule`
87. `supports_injunctions`

## 2.10 Board / spatial
88. `field_relevance`
89. `line_relevance`
90. `geasa_relevance`
91. `field_tag_affinity`
92. `site_control_relevant`
93. `objective_control_relevant`
94. `ready_combat_unit_for_control`
95. `blocks_slot_when_present`

## 2.11 Boss extensions
96. `boss_trial_required`
97. `boss_trial_axes_required`
98. `boss_trial_repeat_counts`
99. `boss_capturable_before_trial_complete`
100. `boss_stance_start`
101. `boss_stance_progression`
102. `boss_has_aura`
103. `boss_has_retaliation`
104. `boss_mark_reward_capture`

## 2.12 Site extensions
105. `site_type`
106. `site_raid_enabled`
107. `raid_condition_ref`
108. `raid_reward_marks`
109. `site_generates_sigil_income`

## 2.13 Name extensions
110. `name_scope`
111. `name_persistent`
112. `name_install_heat`
113. `name_rewrite_heat_rule`
114. `name_arbitrable`

## 2.14 Edict extensions
115. `edict_one_shot`
116. `edict_window_tags`
117. `edict_persists_after_resolution`

## 2.15 Host Sigil extensions
118. `host_sigil_unique_slot`
119. `host_sigil_control_relevant`
120. `host_sigil_generates_sigil_income`

## 2.16 Pet extensions
121. `pet_support_specialist`
122. `pet_faceoff_eligible`

## 2.17 Relic extensions
123. `relic_persistent`
124. `relic_row_slot_type`

## 2.18 UX / content support
125. `rules_text`
126. `rules_summary_short`
127. `lore_text`
128. `ui_badge_tags`
129. `search_tags`

## 2.19 Pipeline / export support
130. `art_prompt_ref`
131. `render_template_ref`
132. `asset_package_ref`
133. `front_visual_family`
134. `back_visual_family`
135. `ultra_visual_override`
136. `export_enabled`

---

## 3. Canonical enum vocabularies

## 3.1 `card_family`
- Character
- Boss
- Edict
- HostSigil
- Name
- Pet
- Relic
- Site

## 3.2 `owner_faction`
- BorderstoneGuild
- FloodbornPact
- SkyloomTemple
- UnderwellKeepers
- Fateforge

## 3.3 `rarity`
- Common
- Uncommon
- Rare
- SuperRare
- Legendary
- Ultra

## 3.4 `downed_marker_type`
- None
- Flip
- Rotate
- Token
- Custom

## 3.5 `timing_class`
- Action
- Reaction
- Triggered
- Static
- Replacement
- Interrupt
- Passive

## 3.6 `play_timing` values
- Upkeep
- Draw
- Edicts
- Main
- Battle
- Resolution
- End
- ReactionWindow
- Custom

## 3.7 `score_overlap_rule`
- HigherSingleReward
- Cumulative
- Replace
- Custom

## 3.8 `arbitration_success_options`
- Seize
- Suppress
- Corrupt

## 3.9 `arbitration_tie_rule`
- FaceOffChain
- DefenderWins
- Custom

## 3.10 `support_value_rule`
- None
- HalfRoundedUp
- PrintedValue
- Custom

---

## 4. Default values by broad card type

## 4.1 Global defaults
Use these defaults unless a card requires something else:
- `version_code = "base"`
- `is_reprint = false`
- `scenario_only = false`
- `tutorial_only = false`
- `cost_sinew = 0`
- `cost_sigil = 0`
- `cost_oath = 0`
- `upkeep_oath = 0`
- `heat_cost = 0`
- `guard = 0`
- `first_strike = false`
- `initiative = 0`
- `heat_on_install = 0`
- `heat_spend_allowed = false`
- `supports_injunctions = false`
- `ultra_visual_override = false`
- `export_enabled = true`

## 4.2 Combat-capable defaults
For combat-capable cards:
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

## 4.3 Character defaults
- `card_family = Character`
- `can_attack = true`
- `can_support = true`
- `support_value_rule = HalfRoundedUp`
- `wound_threshold = 2`
- `mark_reward_capture = 1`
- `mark_reward_plain_defeat = 1`
- `score_overlap_rule = HigherSingleReward`

## 4.4 Boss defaults
- `card_family = Boss`
- `can_attack = true`
- `can_support = true`
- `support_value_rule = HalfRoundedUp`
- `boss_trial_required = 3`
- `boss_trial_axes_required = [Stone,Veil,Authority]`
- `boss_trial_repeat_counts = false`
- `boss_capturable_before_trial_complete = false`
- `boss_stance_start = Guarded`
- `boss_stance_progression = [Guarded,Ascendant,Wrathful,Exposed]`
- `boss_mark_reward_capture = 2`

## 4.5 Name defaults
- `card_family = Name`
- `is_name_object = true`
- `name_persistent = true`
- `name_install_heat = 1`
- `name_rewrite_heat_rule = ByCardValue`
- `name_arbitrable = true`
- `heat_on_install = 1`
- `arbitration_bid_enabled = true`
- `arbitration_success_options = [Seize,Suppress,Corrupt]`
- `arbitration_tie_rule = FaceOffChain`

## 4.6 Edict defaults
- `card_family = Edict`
- `is_edict_object = true`
- `edict_one_shot = true`
- `edict_persists_after_resolution = false`

## 4.7 Site defaults
- `card_family = Site`
- `site_raid_enabled = true`
- `raid_reward_marks = 2`
- `site_control_relevant = true`

## 4.8 Host Sigil defaults
- `card_family = HostSigil`
- `host_sigil_unique_slot = true`
- `host_sigil_control_relevant = true`

## 4.9 Pet defaults
- `card_family = Pet`
- `pet_faceoff_eligible = true`
- `can_support = true`

## 4.10 Relic defaults
- `card_family = Relic`
- `relic_persistent = true`

---

## 5. Requiredness shortcuts

## 5.1 Always required
These must never be blank:
- `card_id`
- `card_slug`
- `card_name`
- `set_code`
- `card_number`
- `card_family`
- `owner_faction`
- `rarity`
- `is_collectible`
- `is_standard_legal`
- `is_unique`
- `is_legendary`
- `deck_copy_limit`
- `rules_text`
- `rules_summary_short`
- `ui_badge_tags`
- `search_tags`
- `export_enabled`

## 5.2 Required for combat-capable rows
- `stone`
- `veil`
- `authority`
- `vitality`
- `wound_threshold`
- `can_attack`
- `can_support`

## 5.3 Required by family
Use the family-specific minimums from Gameplay Schema v1 exactly.

---

## 6. Authoring conventions

## 6.1 Arrays
Store multi-value arrays consistently.
Recommended authoring syntax in sheet cells:
- comma-separated with no spaces unless exporter normalizes

Example:
- `Stone,Veil,Authority`
- `Seize,Suppress,Corrupt`

## 6.2 Booleans
Use only:
- `true`
- `false`

## 6.3 Empty values
Use blank cells only where the schema explicitly allows null.
Do not use:
- n/a
- none
- --
- TBD
inside canonical rows.

## 6.4 Rules text discipline
`rules_text` must explain the card, but not carry unique critical legality that should live in structured fields.

---

## 7. Starter example rows

## 7.1 Example Character row
- `card_id`: `KK-C-0001`
- `card_slug`: `lamassu-gate-guardian`
- `card_name`: `Lamassu, Gate-Guardian`
- `set_code`: `KK1`
- `card_number`: `1`
- `card_family`: `Character`
- `owner_faction`: `BorderstoneGuild`
- `rarity`: `SuperRare`
- `is_collectible`: `true`
- `is_standard_legal`: `true`
- `is_unique`: `true`
- `is_legendary`: `false`
- `deck_copy_limit`: `1`
- `cost_sinew`: `0`
- `cost_sigil`: `2`
- `cost_oath`: `2`
- `stone`: `3`
- `veil`: `1`
- `authority`: `2`
- `vitality`: `2`
- `wound_threshold`: `2`
- `can_attack`: `true`
- `can_support`: `true`
- `support_value_rule`: `HalfRoundedUp`
- `mark_reward_capture`: `1`
- `mark_reward_plain_defeat`: `1`
- `score_overlap_rule`: `HigherSingleReward`

## 7.2 Example Boss row
- same structure as Character plus:
- `card_family`: `Boss`
- `upkeep_oath`: `2`
- `boss_trial_required`: `3`
- `boss_trial_axes_required`: `Stone,Veil,Authority`
- `boss_trial_repeat_counts`: `false`
- `boss_capturable_before_trial_complete`: `false`
- `boss_stance_start`: `Guarded`
- `boss_stance_progression`: `Guarded,Ascendant,Wrathful,Exposed`
- `boss_mark_reward_capture`: `2`

## 7.3 Example Name row
- `card_family`: `Name`
- `is_name_object`: `true`
- `name_scope`: `Field`
- `name_persistent`: `true`
- `name_install_heat`: `1`
- `name_rewrite_heat_rule`: `ByCardValue`
- `name_arbitrable`: `true`
- `heat_on_install`: `1`
- `arbitration_bid_enabled`: `true`
- `arbitration_success_options`: `Seize,Suppress,Corrupt`
- `arbitration_tie_rule`: `FaceOffChain`

---

## 8. Validation sheet tabs recommended

Use these tabs alongside the master:
- `gameplay_master_v1`
- `enum_lists`
- `family_rules`
- `rarity_translation`
- `faction_backfill`
- `rules_text_extraction`
- `validation_errors`
- `export_map`

---

## 9. Hard exclusions

These must not appear as gameplay-authority columns in the canonical master:
- `wind`
- `eye`
- `weight`

These may exist only in archived legacy snapshots, never in the canonical master.

---

## 10. Immediate use

This template should be used to create the first real canonical sheet for Kudurru Kings:
- `gameplay_master_v1`

Once that sheet exists, migration from legacy data can begin mechanically and validation can be run against the acceptance suite.

