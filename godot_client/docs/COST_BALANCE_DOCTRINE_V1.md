# Kudurru Kings — Deployment Cost and Upkeep Doctrine v1

**Approved design instruction:** balance all 754 inherited cards for playable dynamics. Applied only on isolated development branch `build/cost-balance-v1-20261020`. Production `main` unchanged. This is the approved **economy-of-actions cost baseline**, not a claim that every legacy card effect is correct, executable, or competitively proven.

## 1. Authority and preserved contracts

- EOE Crosswalk determines **faction affiliation**, EOE Bible v3.1 determines shared world facts; this patch changes neither.
- Kudurru Kings Shipping Rules v1 determines the **three gameplay resources**: Sinew, Sigil, Oath.
- Starting pool: 2 Sinew / 1 Sigil / 1 Oath.
- End income is conditional: +1 Sinew for most ready combat units; +1 Sigil for Site/Host Sigil control; +1 Oath for Scenario/Objective control; if none, fallback +1 Sinew. No unconditional resource regeneration has been added.
- Bosses require Oath upkeep. Names install +1 Audit Heat independently of deployment costs.
- The Standard 36-card deck constraints, rarity ladder, Marks, seven phases and optional capture within Resolution remain unchanged.
- Rarity never directly changes Marks. No pure-faction bonus has been invented.

## 2. Diagnosis

- All **754 original card records** had zero in all three *deployment* cost columns.
- **326 records** originally had upkeep greater than one, including extremely large Boss upkeep.
- Old character and Boss upkeep scales made cards unsustainable with only +1 conditional Oath each End.
- `rules_text` in migrated legacy cards also contains unsupported terms such as **supply**, **Wind**, and **Eye**. These terms are not silently converted into extra resource types.
- Four faction mismatches and two duplicate slugs remain separately documented. Balancing does not mutate faction or identity columns.

## 3. Model v1 (deterministic, per-card, reversible)

All costs are whole numbers and are computed from **card family, printed Stone/Veil/Authority stats and relevant printed effect text**. No randomness, cosmetic classification, or external reputation affects cost.

### Characters
Let `P = Stone + Veil + Authority`.

`Sinew = 1 + [P >= 5] + [P >= 11] + [P >= 18]`

`Sigil = 1` only if `Veil >= 5`, `Veil >= Stone`, and `P >= 10`.

`Oath = 1` only if `Authority >= 7`, `Authority >= max(Stone, Veil)`, and `P >= 13`.

Normal Character upkeep = **0**. These are deployable entities, not automatically monthly-taxed Bosses. Legacy effect-text conditional payments require separate rules migration.

### Bosses
`Sinew = 3 + [P >= 17] + [P >= 26]`

`Sigil = 1` if `Veil >= 9`.

`Oath = 1` for non-Ultra Bosses regardless of printed power. **Oath upkeep = 1** each applicable Upkeep.

**Rationale:** every normal Boss requires preparation (at least three Sinew), but a player without objective control is not permanently excluded from deployment by an Oath-two prerequisite. A player who holds the objective can maintain one Boss with +1 Oath per End; two simultaneous Bosses still create meaningful upkeep pressure.

### Two Ultra apex identities
- **Adamu** (Character): Sinew 4, Sigil 2, Oath 2; upkeep 0.
- **Anu the Exarch of Heaven** (Boss): Sinew 5, Sigil 2, Oath 2; upkeep 1.

Ultra rarity access remains separately gated by the approved progression economy, so high card costs are not the sole prestige lock.

### Support / laws / Sites
- **Pet:** low-cost Sinew or Sigil specialist, minimum total cost 1; upkeep 0.
- **Site:** generally 1 Sigil; Legendary sites require 2 Sigil, and Sites with higher-tier direct tactical copying/countering/raids may also require 1 Sinew. Sites are resource engines and must not be universally free.
- **Edict:** 1 Sigil by default, 2 for Super Rare or Legendary; powerful global or Legendary effects may additionally cost 1 Oath. One-shot: upkeep 0.
- **Name:** 1 Sigil baseline, 2 from Rare upward; Legendary additionally costs 1 Oath and has 1 Oath upkeep. Other Names upkeep 0. Installation still adds Audit Heat as defined by Shipping Rules.
- **Relic:** 1 Sigil baseline, 2 for Super Rare/Legendary; combat-stat affecting higher rarities may also cost 1 Sinew. Upkeep 0.
- **Host Sigil:** generally 1–2 Sigil and 0–1 Oath. A literal explicit invocation cost controls **without double charging**. `Lamassu, Gate-Guardian` prints Invoke Oath 2 + Sigil 2, so this is exactly the activation cost. Time-limited Host Sigil invocations receive no undocumented recurring Oath upkeep.

Bounds across all records: Sinew 0–5, Sigil 0–2, Oath 0–2, total deployment >=1, upkeep Oath 0–1.

## 4. Applied results

| Family | Cards | Mean total deployment cost | General upkeep |
|---|---:|---:|---|
| Character | 500 | 1.69 | 0 |
| Boss | 164 | 5.30 | 1 Oath |
| Host Sigil | 15 | 2.40 | 0 |
| Edict | 15 | 1.40 | 0 |
| Name | 15 | 1.67 | 0 except Legendary 1 |
| Site | 15 | 1.20 | 0 |
| Relic | 15 | 1.47 | 0 |
| Pet | 15 | 1.07 | 0 |

- All 754 deployed-card costs changed from the zero baseline.
- 397 `upkeep_oath` values normalized.
- 754/754 card identities, factions, rarity, abilities, and other non-cost fields preserved by the apply validator.
- Original four cost/upkeep columns are snapshotted with the source hash in `godot_client/data/cost_balance_v1_baseline.json`; original master also exists in parent Git history.

## 5. Economic checks, not full-game certification

- **12,000** illustrative mixed economic openings: first-hand and optional-mulligan affordability **100%**, mean **4.754** individually affordable cards among six. This does not mean resources allow playing all four in one turn.
- **20,000** faction-pure deck economic trials: 4,000 per faction, each 36-card sample with 21 Characters, 3 Sites, 4 Pets/Relics, 3 Edicts, 2 Names, 2 Bosses, 1 Host Sigil. Across factions, an affordable card on both sampled first and second turns was available in **99.45%–99.90%** of trials. Effects/combat/other players were not simulated. Faction assignments remain migrated/provisional where not EOE verified.
- Python integrity tests: **15/15 PASS**, including a non-cost-field comparison against the original source commit. Godot headless regression: **46/46 PASS**. Dedicated five-faction affordability simulation also passes.
- Source cost generator ran twice with unchanged report SHA256, establishing idempotence.
- Separate cost-panel export has 754 records.

**These are accessibility tests, not proof of fairness across matchups, optimal win rates, or turn-length balance.** The actual 10-Mark match resolver, deterministic combat, playable card effects, scenario system and game AI have not been implemented yet.

## 6. Export integrity and no-shipping boundary

The two legacy presentation exports in `06_Exports` each contain **397 upkeep discrepancies** against the new gameplay master. They also contain older presentation content and potentially divergent rules text. Do not ship or silently patch only their `upkeep_oath` column.

The new `06_Exports/Kudurru_Kings_Cost_Panel_Export_v1.csv` is the **derived cost authority for future render templates**. Its rows are card-ID matched to the master, and `gameplay_certified=false` for every card. The older exports must be fully regenerated once the effect model and render layouts are repaired.

## 7. Runbook

Run from repository root:

```powershell
python godot_client/tools/balance_costs.py --apply
python godot_client/tools/export_cost_panel.py
python godot_client/tools/simulate_faction_costs.py
python godot_client/tools/audit_legacy_exports.py
python godot_client/tools/build_catalog.py
python godot_client/tests/test_cost_balance.py
& 'E:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'E:\KudurruKings\repo\godot_client' --script res://tests/test_runner.gd
```

`balance_costs.py` refuses manual non-model costs. To revise balance, update the model, create reviewed exceptions with provenance, test, and issue a versioned doctrine rather than mutating individual rows by hand.

## 8. Next release gate

Complete EOE faction reconciliation, migrate legacy card-effect terms, implement legal-resource-payment gameplay, regenerate presentation exports, and run seeded full-match tactical simulations before claiming any card set competitively balanced or playable in a released mode.
