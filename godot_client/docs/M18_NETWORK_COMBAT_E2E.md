# Kudurru Kings M18 ? Authenticated Two-Window Combat End-to-End

Source branch: build/m18-live-network-battle-20261020.
Engine: Godot 4.7.2, portable Windows x64 development candidate.
Full Shipping Rules v1 / 754-card Standard release gate remains CLOSED.

## Player-visible improvements

The real solo and two-seat local-network match interfaces display the
pending combat declaration, both unit identifiers, chosen Stone/Veil/
Authority axis, and the attacker's already declared 0?2 resource
commitment. Only the defending player sees DEFEND YOUR UNIT and
selects its own 0?2 matching resource commitment and legal supporter.
The attacker sees WAIT FOR DEFENDER rather than being allowed to
resolve the opposing player's choice. Both displays clear when the
server confirms combat resolution. The interface does not leak
hidden hands or unannounced deck order.

## Actual network acceptance

tests/test_network_combat_e2e.gd spins up two actual StreamPeerTCP
clients and a live, unmodified server transport, then uses one
source-owned physical Character from each valid 36-card roster.
Those cards are removed from their initial hand/deck zone so
their physical source instances remain conserved on the Field.
The battle state is a test-only injected fixture: it does not
pretend to have been reached through a production deck/board setup.

37 acceptance checks verify (a) two distinct authenticated seats,
(b) real public battlefield sync, (c) no opponent-hand exposure,
(d) one-packet legacy combat rejected, (e) attacker-injected defender
resource spend rejected, (f) attacker spend specified in real UI,
(g) defender-only response prompt and frozen normal action flow,
(h) attempted impersonation of defending seat rejected,
(i) defender cannot advance before resolving, (j) actual second UI
selecting own resource amount, (k) host confirms separate monotonic
attacker-declaration and defender-choice revisions, (l) both clients
receive exactly the same combat and resource changes, (m) replayed
defensive responses cannot charge twice, and (n) private card
projections remain closed throughout the battle. No tokens or
private deck contents are written to public event output.

Existing tests/test_combat_choice_ui.gd now also checks the solo
defender hint; that fixture totals 16 UI checks. Every M1-M17
regression, source-card integrity check, deterministic seeded match
replay, Python localhost transport check, exported-scene parse smoke,
and new socket test is mandatory in tools/run_m18_quality_gate.ps1.

## Production boundary

The server remains explicitly loopback-only (127.0.0.1:31147),
two-seat, memory-resident, no secure reconnect, no public WAN/TLS,
accounts, collection authority, anti-fraud economics, or 3?4 seats.
It is not fit to expose to external networks. The scenario continues
to be a noncanonical local candidate; only 10/15 Edicts work in live
matches, most other printed source effects, Bosses, Bind/Capture,
full Lines/Geasa, raid scoring and production artwork remain blocked.
This work is a validated networking and UX step, NOT a claim that
the game has all promised shipping functionality.
