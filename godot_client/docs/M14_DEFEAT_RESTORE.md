# Kudurru Kings M14 ? Two Full-Round Defeated Return

Branch: build/m14-defeat-lifecycle-20261020.
Engine: Godot 4.7.2, source reducer owned. Shipping Rules v1
Section 17.6 is the authority. Not a commercial release.

## Source-backed lifecycle correction

Defeated cards remain on the Battlefield, occupy their slots, and do
not participate in control. They are not auto-returned when Downed.
A Defeated card timestamped round R cannot return during the two
full intervening rounds R+1 and R+2. The unit returns at the start
of round R+3, when both sides have completed those two rounds.

At that boundary the original owner receives the exact source card
into the Hand if it contains fewer than six cards; otherwise into
the Deck, with deterministic source-stable shuffle. This uses the
unit's original owner property, NOT its latest controller, and never
grants a collectible. Battlefield occupancy and source identity
remain until the restore moment. Successful returns and original
owner details are journaled in the existing turn PHASE event; no
unlogged side effects or source-card duplication occurs.

The original rules do not specify how attached supports are disposed
when their restored host physically leaves the Field. M14 makes an
explicit, reversible preview assumption: associated Pet/Relic cards
are detached to the support controller's match discard. This is
documented as provisional, NOT new source canon or final production
certification. These source identities and attached-card conservation
are checked before any transition is committed.

The live match now displays DOWNED as FLIPPED / DOWNED, and labels
Defeated units with their expected restoration round. This is a
text/readability implementation, NOT finished card-back rendering.

## Verification and limitations

Test: tests/test_defeat_restore.gd, 31 checks covering return timing,
original owner, preserved card identity, match card conservation,
Hand-vs-Deck path, owned support return, unaffected younger
Defeated units, duplicate prevention, invalid ownership, and
source-state immutability. It explicitly uses test-only Defeated
fixtures because the integrated real-match Bind/Trials/Capture or
other Defeat source is not implemented yet. Consequently this gate
proves the restoration subroutine and round-transition wiring,
but does NOT certify end-to-end defeat/capture gameplay.

All prior M1-M13 tests, UI, source deckbuilding, local opponent,
source-backed Edicts, save replay, localhost server, collection
ledger, combat lab and source audits remain in the full M14 gate:
tools/run_m14_quality_gate.ps1.

Full Standard remains blocked: 754 cards and all normalized effects,
Boss Auras/Trials/Bind/Capture, four-seat WAN, cards/economy,
original artwork, visual certification and signed distribution.
EOE original Crosswalk/Bible remains canon authority.
