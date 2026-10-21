# M25 rules lane — dependency review

Baseline: `45999124d5d6a19d539efe8c7c66734ea4dec290`. This review does not amend rules or enable new cards. Production CLOSED.

## Verified implementation

`real_combat_core.gd` now shares a fail-closed prerequisite gate between isolated laboratory capture attempt and decline. Both paths validate the active, in-range actor, real source Character/Boss, Downed+Bound and not Defeated/already captured, and exactly three distinct legal Boss Trial records. Malformed Trial strings and extra/duplicate records return errors without a script exception. The input state stays unchanged on refusal. The unresolved success adjudicator still returns `CAPTURE_SUCCESS_RULE_NOT_SPECIFIED`; no rewards are enabled. This is laboratory hardening, not a new live match capture subsystem.

Focused regression: `test_real_combat_core.gd`: 86 passed / 0 failed (+15 assertions), Godot 4.7.2 Linux. Full integrated and native acceptance must be run after swarm integration; this document does not claim those results.

## Source facts and remaining contract gaps

Shipping Rules 18.3: “Capture is only legal during the Resolution step/substep after a valid Bind check.” Shipping 18.4/18.5 make declined or failed capture Defeated. Shipping 20.3/20.4 require three unique Trials on Stone/Veil/Authority. Shipping 2.2 requires completing the entire simultaneous scoring window before deciding winners.

The current 164 Boss master rows all contain `upkeep_oath=1`, `boss_trial_required=3.0`, `boss_trial_axes_required=Stone,Veil,Authority`, `boss_trial_repeat_counts=False`, `boss_capturable_before_trial_complete=False`, `boss_stance_start=Guarded`, and progression `Guarded,Ascendant,Wrathful,Exposed`. These inherited structural defaults do not prove 164 full source effects are implemented. All rows have aura/retaliation flags False even though Shipping 20.8 requires those systems; individual printed text still needs reconciliation. Do not infer that every Boss has no aura/retaliation from these default flags.

### Decision packet: C02 Bind and capture

- **Authoritative boundary:** Shipping 17.5 says a normal unit may only be Bound once Downed unless an explicit override exists. Shipping 18.3 requires a “valid Bind check,” but does not define the check's declaration, cost, contested total or failure procedure. Capture failure is recognized but no universal success adjudicator is defined.
- **Historical candidate, not approval:** Final Gameplay Doctrine v1.1, section “D. Bind,” says the target must be Downed and the conflict resolved on Oath (old axis term), or target is in Sanctuary, or an effect explicitly permits otherwise; successful Bind replaces a new Wound. Promoting this to current Authority-axis law would be a material canon choice. Existing `AUTHORITY_FACE_OFF_CANDIDATE` is an isolated engineering proposal, not evidence that this choice was approved.
- **Recommended path for user review:** approve one complete Bind/Capture contract before live integration. Specify separately (1) legal declaration window/actor/target, (2) what contest or explicit effect establishes Bound, (3) whether a Bound eligible target is automatically capturable on choice or requires a further contest, and (4) failure/decline cleanup and reward event. Prefer a deterministic source-aligned contract with no added probabilities. No new cost or automatic success is selected by this review.
- **Implementation effect:** reducer, owner decision UI, authoritative command validation, source-pinned replay, conservation, full-window scoring, trusted collection receipt issuance and failure tests all depend on that contract. Until approved, `reward_enabled=false` stays enforced.

### Boss lifecycle contracts needing reconciliation

Shipping 20.2 states “Bosses require Oath upkeep by default.” The master supplies the payment amount (1); it does not establish what happens when payment is impossible or declined. Do not invent damage, exhaustion, return or free upkeep.

Shipping specifies the distinct axes and stance ladder but not a complete challenge declaration/cost/eligibility/timing procedure or exact stance transitions. Historical Boss Appendix offers 0/1/2/3 unique Trials → Guarded/Ascendant/Wrathful/Exposed; persistence through controller change and reset on reentry; those remain secondary candidates pending reconciliation. A normal successful attack must not silently earn a Trial without a validated challenge rule.

## Existing isolated scoring limitation

`real_combat_core.gd::decline_capture` still assigns a single winner immediately when its one laboratory event reaches ten. That existing laboratory path is not a certified implementation of Shipping 2.2 simultaneous-window arbitration. It must not be imported as the full match scoring reducer. Live full-window scoring should aggregate all authoritative window events, apply the higher single reward for defeat/capture overlap (Shipping 19.3), then determine all threshold candidates. No speculative window policy is activated here.

## Integration boundary

No edits to `match_integrator.gd`, network, UI, canonical master, private EOE material, milestone gates, or approval overlays. No commits/pushes, public release, deployment or signing performed by this lane.
