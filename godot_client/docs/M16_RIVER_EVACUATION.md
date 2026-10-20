# Kudurru Kings M16 ? Source-Verified River Evacuation

Branch: build/m16-field-displacement-20261020.
Native Godot 4.7.2; candidate gameplay only. Not production Standard.

## Added to actual live matches

Edict 186, River Evacuation, is now verified by immutable source-card
identity and complete SHA-256 printed text. During Edicts its player
selects one or two UNIQUE battlefield units originating in the
same active Field. The destination is the other active Field,
either Warfield or Sanctuary in the present 2-field scenario.
The reducer rejects zero/three targets, repeated or nonexistent
UIDs, non-active fields, a no-op source=destination transfer,
mixed source Fields, defeated untargetable cards and stale actions.
Downed but not Defeated cards remain targetable. Both friendly
and enemy units are legal. Per-controller destination slots
are assigned deterministically without collision, the 1-Sigil
deployment cost is paid, and the source Edict moves to the
caster's discard. The action log journals moved identities,
source and target fields and destination slots. All mutation
is performed on a reducer copy, not the requester's source state.

The native solo scene permits choosing a first target plus one
optional second target. The local-network scene accepts a single
selected target; its host executes exactly the same rule.
The deterministic candidate AI can perform a legal one-target
displacement when the card is in hand.

This fills a specific printed effect, NOT the full
Fields / Lines / Geasa / jurisdiction system. The card text
does not define crossing Geas consequences; those remain
unimplemented. The reducer logs the explicit
line_geas_resolution=NOT_IMPLEMENTED_IN_CANDIDATE status
and never forges a penalty. Crossing effects remain release blockers.

M16 adds 10/15 source-verified live Edict candidates from the
754-card master. There are still only two active Fields
(Sanctuary and Warfield). Full Standard is not certified and
all unimplemented effects are visibly excluded from matches.

## Reproducibility

tests/test_river_evacuation.gd: 30 checks on source provenance,
one/two chosen targets, source family/timing/payment, occupied
slot repair, actual state changes and rejections.
tests/test_river_ui.gd: 8 actual game UI integration checks.
Previous full M1-M15 gates are required unchanged by
tools/run_m16_quality_gate.ps1, including socket loopback
privacy, actual two-window network joining, real source decks,
combat ordering, standard card metadata, opponent decision
windows, Defeated original-owner restore and save/replay.
Windows x64 native export uses tools/export_m16_windows.ps1.

## Next shipping gates

Complete remaining five Edicts; printed Names/HostSigils;
Boss-specific combat/upkeep and trial effects; legally sourced
Bind/capture success; all Site raids and Lines/Geasa; authoritative
2?4 WAN multiplayer; signed account collection progression,
owned-card checks and anti-fraud; complete 754-card artwork
provenance and visual review; Windows signed installer.
The full game's production audit remains fail-closed.
