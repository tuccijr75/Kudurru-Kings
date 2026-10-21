# M23 — recover an owner seat after loopback disconnect

Base: M22 evidence head `63e3460ad65417cfcb39bd63e76e7357329c4ff6`; M22 tested executable source `4ea2a54`; original M18 `caf153d` remains preserved. Branch: `build/m23-authenticated-reconnect-20261020`. Production CLOSED.

## Behavior and contracts

Previously, a disconnected player permanently lost access to the still-running host: seats remained reserved to prevent private-hand takeover, but no owner recovery existed. The real network client now offers RECONNECT MY SEAT. Recovery works in the same surviving game window against the same surviving host, including a locked deck lobby and a pending defender decision. It preserves the exact reducer state, source deck IDs, game revision, resource balances, pending choices and action history. No anonymous replacement seat or automatic defender decision is introduced.

The existing `127.0.0.1:31147` listener now requires an explicit JOIN or RESUME as its first message. Unidentified connections receive no private projection or session credentials and are excluded from game broadcasts. The listener allows at most six total connections (two player seats plus bounded pending handshakes); unidentified connections expire after five seconds. Malformed/wrong resume credentials and attempts to take an active owner's seat are refused. Anonymous JOIN never inherits a previously claimed seat. Packet seat fields cannot select an owner; the host maps the recovery credential to its reserved seat.

Each owner has a cryptographically generated 256-bit recovery key held only in the host and client window's memory. Every successful connection receives a separate fresh 256-bit active token. An old active token cannot perform recovery. The recovery key stays stable for that host session so losing a recovery WELCOME does not lock out the legitimate window. It cannot displace an already-connected owner. Credentials are never saved in match state, replay, deck files, public projections or product text. They are returned only in that connection's WELCOME. No account credentials, registry changes or persisted secrets are needed.

Until a fresh WELCOME arrives, the recovering UI blocks gameplay submission. Successful recovery shows the host's current private projection for that same seat and restores the appropriate decision controls. The defender still chooses their own spend/supporter. Transport recovery does not manufacture a gameplay event or a new revision. Closing the host loses the in-memory session; closing the client loses its recovery key. Host restart, new-window/account recovery, TLS/WAN authentication, spectators, 3–4 seats and persistent service recovery remain open.

## Regression and acceptance

The added suite uses two actual TCP UI clients, source-legal arranged decks and only logged real setup/deploy/phase actions for its battle fixture. It recovers a locked lobby, refuses malformed/forged/anonymous/duplicate-active access, verifies no pre-authentication broadcasts, exercises the handshake deadline, recovers the actual pending defender consent window, executes that player's defense through the UI, verifies replay/card conservation, and simulates a lost recovery reply followed by another legitimate recovery. Both active and recovery credentials remain absent from reducer history and public projections.

The Python real-socket test now sends JOIN explicitly. Older development clients expecting an unsolicited WELCOME must use the matching M23 client/host pair. The inherited full gate inventory now includes the reconnect suite (66 commands / 39 Godot suites); native results and build hashes are recorded only after actual execution.

## Canon and shipping audit

No new card effects, deprecated mechanics, scenario rules, rewards or probabilities are enabled. The existing 754-card, 121-template, 23-system ledger remains 0 production-certified cards / 6 candidate PASS / 11 IN_PROGRESS / 6 BLOCKED gates. Canon conflicts C01–C09 and the M22 Silence dependency remain applicable. Private EOE references remain outside public GitHub. Loopback recovery is not certification of secure remote multiplayer or independently signed production distribution.

Final Linux acceptance: official Godot 4.7.2, all 66 commands, 39 Godot suites / 7,214 assertions / 0 failures, 50 Python cases and no detected console errors. Reconnect suite 47/0, deck lobby 52/0, TCP battle 65/0, storage 339/0, command integrity 170/0. Complete command log SHA256: `b2bb885490c3b36906b10a572cb8e0650c6a18c104c896935a8c2321cb649abb`. Windows evidence follows after actual native execution.

Native Windows acceptance completed at `0b60992b2e518008b57e872c58f5743a4d3ce0b9`: all 66 commands / 39 suites / 7,214 assertions / 50 Python cases passed, followed by native export, ZIP CRC/manifest hashes and a fresh extracted headless launch. M18 remains clean and unchanged. No embedded Authenticode signature; human visual acceptance remains unverified. See WINDOWS_M23_VERIFICATION.md and data/m23_verification.json.
