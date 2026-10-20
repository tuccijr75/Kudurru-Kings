# Kudurru Kings M15 ? Two Real Local Multiplayer Windows

Branch: build/m15-network-client-preview-20261020.
Engine: Godot 4.7.2, single canonical source reducer at the host.
This is strictly a developer preview, NOT safe to expose to the Internet.

## Functionality

Two actual game windows can share a match over 127.0.0.1:31147.
Window 1 opens LOCAL TWO-SEAT MULTIPLAYER (PREVIEW) on the board,
then HOST + JOIN (WINDOW 1). This creates a Godot authoritative host
in the same process and joins the first independently authenticated
client as Seat 0. Open the EXE in another game window, select the
same multiplayer screen, then JOIN HOST (WINDOW 2). It joins Seat 1.

Each client sees only its own six-card hand, the other seat's hand
count, resources, Marks, public units/sites/attachments and a bounded
window of public events. The host never exposes the seed, deck
ordering or action log. Each client holds a random 256-bit
ephemeral token, unique to that player. The server (not either
client) validates revised actions, resources, ownership, phase
timing, cards and targeting. All results are broadcast as separate
per-seat projections.

The UI implements independent opening KEEP/MULLIGAN, turn advance,
source-supported Edicts and mandatory responding-player decisions,
Night Market and End hand discards, supported cards/Sites/Pets/Relics,
real unit combat axis selection and private Mirror Archive peek.
The host is still the same M14 real match candidate with nine
integrated source-hashed Edicts and exact source-card identities.

Disconnect does NOT reassign or steal a claimed seat. This is a
fail-closed interim measure, not authenticated reconnect. A third
window is refused. Closing the host terminates the in-memory game.
The official engine Windows release export includes this new UI
scene and launch button.

## Test evidence

tests/test_local_match_client_ui.gd exercises two actual StreamPeerTCP
clients against a real Godot TCPServer in one running process, checks
distinct randomized tokens, independent hands, both opening decisions,
host-approved revision sync, out-of-turn refusal, server seed/history
privacy, third-client refusal and claimed-seat protection after a
disconnect. 31 targeted checks pass.

The existing native Python socket multiplayer E2E and all M1-M14
deck/effects/combat/lifecycle/save/replay/collection/jurisdiction/UI
tests remain required by tools/run_m15_quality_gate.ps1.
Native Windows ZIP reproducibility and extracted-image launch are
separate release checks.

## Security and commercial release boundaries

The host is loopback-bound ONLY, does not use TLS, persistent accounts,
reconnect credentials, anti-cheat account entitlements, authoritative
remote collection awards, internet matchmaking, or 3-4 seats.
It should never be forwarded through a router or publicly exposed.
The game is not finished 754-card Standard; Bosses, captures, field
jurisdiction, many card effects and final art remain incomplete.
The release tracker must remain false until all shipping gates pass.
