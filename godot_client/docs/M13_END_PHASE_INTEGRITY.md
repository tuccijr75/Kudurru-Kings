# Kudurru Kings M13 ? End Phase Hand Choice and Income Clarity

Branch: build/m13-end-phase-integrity-20261020.
Engine: Godot 4.7.2. Shipping Rules v1 Sections 11, 12 and 13 are the source.
Production Standard remains explicitly NOT certified.

## Implemented

In End, a hand above six now cannot silently discard arbitrary cards.
The acting player must submit as many END_DISCARD actions as necessary,
each identifying an exact owned hand index. The chosen real card moves
to discard, revision and event are logged, and no unrelated card changes
occur. Stale, out-of-phase, non-owner, oversized, negative and replayed
discard actions are rejected. If six or fewer remain, normal End
transition is permitted. The opponent AI chooses a deterministic legal
discard while a human makes that choice manually in the actual UI.

The hand UI now gives every card a stable positional selection callback,
including duplicate source cards. End overflow cards are visibly labeled
DISCARD and Next Phase remains disabled until the player reaches six.
This is separate from Night Market Clause's required discard and
opponent-response choices; those windows keep their separate legality.

The match UI displays an explicit End-income forecast listing three
source-defined conditions: most ready combat units across the current
Fields (Sinew), current Site control (Sigil), and scenario objective
control (Oath). It displays the actual +Sinew/+Sigil/+Oath increments
from the same pure reducer function used when ending the turn. Where
no condition is met the stated fallback is +1 Sinew. The predicted
resource change is not based on fabricated card rule text.

## Verification

tests/test_end_phase_integrity.gd contains 33 targeted checks for
legal End window, source-card conservation, exact position selection,
multi-card overflow, immutability, error handling, action ledger,
opponent choice, and visible UI conditions. All previous M1-M12
source tests, two-client localhost networking, original Edicts,
source deck builder, save/replay, candidate Boss/capture and jurisdiction
regressions remain part of tools/run_m13_quality_gate.ps1.
The official 4.7.2 Windows release export and independent extraction
launch are separate workstation gates.

## Shipping boundaries

The source requires Sigil for control of at least one Site OR Host Sigil.
Only Sites exist in the current integrated match, so the UI labels
the implemented Site condition, not falsely full Host Sigil readiness.
Boss upkeep, full board geometry, sealed capture-success canon,
all printed card effects and all 2-4 seat online game requirements
remain blocked. The precise scenario win logic continues to be
an explicitly noncanonical Warfield Ascendancy local preview.
M13 does not assert production gameplay certification or rewards.
