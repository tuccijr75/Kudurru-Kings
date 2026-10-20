# Kudurru Kings M4 — Real Cards and Source Effects

## Authority and scope
- Original Echoes of Eridu Bible v3.1 and Canon/Crosswalk control EOE lore and faction alignment. No private source material is published.
- Kudurru Kings Shipping Rules v1 controls gameplay. Seven phases, hybrid/pure decks and optional Resolution capture remain unchanged.
- Isolated Git branch: `build/m4-real-cards-20261020`. This is a **real-card development sandbox**, NOT a full Standard match.
- Master CSV is unchanged from the prior approved cost-balance baseline. All 754 cards remain `production_playable=false`.

## Build artifacts
- `data/real_cards_v1.json`: 754 genuine records, original rules text, immutable IDs, costs, stats, EOE display faction and effect statuses.
- `tools/build_real_cards.py`: regenerates the catalog and rejects drift for twelve pinned source texts.
- `scripts/real_effects.gd`: twelve card-specific state effects, timing, target legality, atomic payments, persistent law effects and safe private top-deck information.
- `scenes/real_catalog.tscn` and `scripts/real_catalog_ui.gd`: searchable and paginated 754-card browser plus a separate twelve-effect test bench.
- `tools/compile_character_mechanics.py`: printed-source transcription, contradiction audit, 423 exact adjacent-ally ability descriptors.
- `scripts/adjacency_rule.gd`: checks +1 adjacent ally when authoritative context supplies adjacency evidence; no speculative spatial model.
- `scripts/real_combat_preview.gd`: Stone/Veil/Authority comparisons using genuine Character stats, exact adjacent-ally bonus and active Bitumen Furnace. **Not a complete battle outcome**.

## Twelve source-pinned effects
| ID | Card | Test-resolved action |
|---|---|---|
| 180 | Royal Pardon | Clear friendly Boss/Name Cracks, Heat -2 |
| 184 | Condemnation Seal | Downed unit cannot save/ready this round |
| 185 | Writ of Seizure | Exhaust Site/Relic through owner's next Upkeep |
| 187 | Night Market Clause | Printed End timing: draw 2, discard 1, Heat +1 |
| 189 | Emergency Rationing | Next applicable Oath upkeep -1 |
| 191 | Festival Truce | Stop mutual engagements until caster's next turn; Heat -1 both |
| 193 | Convoy Priority | Ready exhausted ally, cannot support this round |
| 199 | Broken Oath | Name installs with Heat and reacts to failed Oath upkeep |
| 206 | Hearth Amnesty | First Heat gain per player per round reduced by 1 |
| 207 | Glass Mercy | First Silence placed each round becomes Stagger |
| 214 | Mirror Archive | Private top-card peek once per turn |
| 216 | Bitumen Furnace | Friendly attacking Stone test +1 in Warfield |

Effects are **sandbox-verified only**. Production legal decks, account inventory, match rewards, multiplayer and full combat are not enabled. Debug battlefield targets use real IDs but do not count as certified deployable cards.

## Source audit
- 754 records; twelve sandbox effects; 742 other effects unimplemented or unresolved.
- 423 printed Character abilities matched exactly: an adjacent ally grants +1 to Checks. These are **context descriptors**, not 423 full playable cards.
- All 664 Character/Boss cards have conflicting structured Guard/First Strike versus their printed values. The original fields were **not overwritten**. Printed evidence is retained for explicit reconciliation.
- Deprecated concepts in old text (Wind, Eye, supply, recoil, etc.) are NOT silently reinterpreted into current rules.
- Original EOE conflict reconciliation remains authoritative. Mercy Docket's name/family conflict is not silently changed.
- Legacy presentation exports are still blocked pending full regeneration.

## Remaining gates
Implement field/spatial adjacency, Guard/First Strike, combat supporters and spend, wound/downed/Bound handling, Boss Trials, source-specific effects, optional capture and true deterministic 10-Mark match endings. Complete visual workstation QA before treating the implementation as shippable.

Run `godot_client/tools/run_m4_quality_gate.ps1` to rebuild, verify source integrity, and execute the full Godot headless regression suite.
