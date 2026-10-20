# Kudurru Kings M5 — Real combat, arbitration and Resolution sandbox

**Status:** Source-owned development milestone, not a complete Standard match.
**Branch:** `build/m5-combat-core-20261020`
**Engine:** Godot 4.7.2 / GDScript
**Authority:** Echoes of Eridu Bible v3.1 + original Canon/Crosswalk for lore, Kudurru Kings Shipping Rules and canonical gameplay schema for mechanics.

## What was actually implemented

The real-card combat sandbox resolves Battle checks using card-authoritative Stone / Veil / Authority values and existing 423 exact adjacent-ally rule descriptors. One legal same-field supporter may provide HalfRoundedUp of its tested axis (structured master field `support_value_rule`), and support relieves one Audit Heat (`heat_on_support=-1`). Source-defined axis matching is Stone=Sinew, Veil=Sigil, Authority=Oath; each side may spend 0–2, with exact affordability validation and no negative balances.

Face-off searches the top valid combat record in each deck (Character, Boss, Pet), ignores card text, compares the original axis and continues through ties. Revealed cards shuffle back using a deterministic local seed after resolution. **If both decks exhaust all valid Face-off combat cards during a tie, the resolver fails closed**; original rules do not specify a winner.

Successful attacks deal one Wound. A real Character becomes Downed when its structured wound threshold is reached (2 in the existing Character cards). Downed and Defeated units remain in their slots. An eligible Bound+Downed target may have capture declined during Resolution, becoming Defeated. Ordinary Character plain defeat awards 1 Mark; Boss plain defeat does not automatically award a Character Mark. Marks reach victory threshold at 10. Defeated cards restore to their original owner's hand if space, otherwise owner's deck, **after two complete intervening rounds**.

The sandbox validates the Boss prerequisite of distinct Stone, Veil, Authority Trials. However, assigning earned Trials, calculating stance consequences, executing Boss aura/retaliation, and deciding success/failure of a capture attempt are not yet implemented. Bind is available ONLY through a source-labelled test setup injection; it is not represented as an approved universal action.

A separate sandbox arbitration system implements two sealed Oath bids against a real persistent Name, reveal only after both commitments, deduction of winning/losing bids, tie Face-off, and **Seize** with 1 Mark and temporary match-control change. Original collection ownership is unchanged. **Suppress** and **Corrupt** fail closed pending exact source-derived transition rules. A public projection strips sealed bid values.

The main Godot board now includes **TEST REAL COMBAT**, a separate interactive laboratory scene that supports actual card stats, attack, supporter/spend controls, manually readied next test, Resolution, test Bind, capture attempt block, optional decline and defeated restoration. The existing **VIEW 754 REAL CARDS** catalog remains available.

The original legacy phase controller also now credits conditional resource income **when End resolves** instead of erroneously crediting it when Resolution ends. Existing M1/M3 tests were revised to assert correct timing.

## Source integrity

- The original 754-row gameplay master remains unchanged in this milestone; the approved M2 cost baseline remains the only adjusted gameplay data.
- Real-card registry now carries structured wound threshold, supporter value rule and supporter Heat relief for auditability.
- The 12 explicitly source-pinned sandbox effects remain unchanged.
- 423 exact Character adjacency descriptors remain in use.
- No new effect text, faction identity or pure-faction advantage was invented.
- No user collections, progression rewards or real purchases are enabled.

## Why the game is not yet complete

`data/m5_release_blockers.json` is the executable/readable certification list. It reports 19 outstanding categories including 742 other card effects, 664 printed Guard/First Strike vs structured-field disagreements, every target rule reference and trigger window currently empty, unimplemented scenario/objective gameplay, field/Line/Geas traversal, Boss aura/retaliation, arbitration Suppress/Corrupt, raids, collection-copy rewards, multiplayer, AI and UI certification.

The above are not waived, and **production_playable_count remains 0**. Production match completeness must not be claimed from sandbox-only combat tests.

## Verification

Run `godot_client/tools/run_m5_quality_gate.ps1` from PowerShell on ManicsPC. The script recompiles the source catalogs and executes Python, headless Godot suites, both real-card/gameboard scenes and the M5 UI smoke. It scans Godot stderr for compilation errors because exit code alone can be misleading.

## Next engineering gates (canon-first)

1. Agree on a provenance-preserving structured representation of printed Guard, First Strike and Initiative for 664 affected cards, retaining their original mechanics and appropriate EOE/crosswalk precedence.
2. Finish valid Field instances, 2 active Field limit, slot/adjacency/traversal/Line/Geas effects and full supporter/target restrictions.
3. Implement Boss attacks, Guard/First Strike sequencing, aura/retaliation, earned distinct-axis Trials, and legal Bind sources.
4. Specify capture-attempt deterministic outcome/precedence through a canon-approved authoritative source; do not award permanent collection copies until success and idempotency are proven.
5. Implement scenarios/objectives, Edict/Name/Site/Pet/Relic/Host Sigil text with original legality/timing and precise trigger metadata, then deterministic end-to-end matches.
6. Complete raids, all three arbitration options, economy/persistence safeguards, player-versus-AI, networking/security, art/export pipeline and Windows visual QA.
7. Run replay, 10-Mark victory, 36-card conservation, seeded long-match, cross-faction fairness and performance release gates before publication.
