# M24 — integrated three/four-seat loopback candidate

Base: M23 evidence head `aeba3414d3f3015b70ef984639b20c03cc28ff74`; M23 executable `0b60992`. Original M18 `caf153d` is preserved. Branch: `build/m24-four-seat-candidate-20261020`. Production CLOSED.

## Source contract and integrated changes

Shipping Rules 1 supports 1–4 players; 10 determines player order at setup; 27.3 reserves Initiative for combat sequencing. This extends the existing candidate from two to three/four ordered seats. The configured array supplies seat order, and the loopback host assigns seats in connection/JOIN order as before. It adds no Initiative-based global order, team rules, faction bonus or certified tournament seating algorithm. Solo presentation still uses the existing human/AI path; the new network lobbies offer 2, 3 or 4 seats.

Match.create validates the requested faction/deck count and creates a source-legal 36-card list for each seat. Setup waits for every owner to KEEP or use their one free mulligan. All seven phases stay intact; End advances to the next configured seat and increments round only after the final seat. Existing two-seat defaults, names, state schema and action behavior remain compatible. Replay validates all configured owners, balances, source lists and 36-card conservation, rejecting malformed extra-seat data rather than silently defaulting it.

The existing 2–4-combatant-capable combat core now receives all seat records from the integrated reducer. A declaration identifies the actual defending controller, who alone chooses spend/supporter. Copies back preserve uninvolved players' resources/cards. Public Reckoning already queues each qualifying opponent; the candidate AI and private Mirror/Censor targets now select real seat IDs instead of `1-seat` arithmetic. The loopback lobby, authenticated JOIN/RESUME and owner recovery work for the added seats. Pending connections remain bounded (configured seats plus four, at most eight).

Festival Truce (source 191) explicitly prints: choose two players, bar their mutual Engagements until the caster's next turn, lower both Heat by one. Three/four-seat casts now require two distinct valid player IDs. The command contract validates whole integers before conversion. Reducer, pair-specific engagement checks, AI and client selectors use the same chosen pair. Only that pair receives Heat relief; unselected players remain free to engage. Two-seat legacy casts still resolve the only possible pair. No additional card IDs are activated.

The network client shows all public seat standings, own hand only, player target/pair selectors, all public units, defender consent and an End-income forecast. Saved decks, source costs, faction locks and optional Resolution capture remain unchanged. The existing Warfield Ascendancy candidate objective and its objective-control tie convention remain uncertified. The subsequent 2026-10-21 C10 approval resolves the ready-unit income tie: no conditional Sinew for tied leaders, normal fallback unchanged. See APPROVED_CANON_DECISIONS.md.

## Acceptance and boundaries

The new suite builds all multi-seat combatants through logged setup/deploy/phase actions from source-legal arranged decks. It checks 3/4-seat setup, full seven-phase rounds, final-seat defense, third-party refusal, unaffected bystanders, replay/JSON round trip and malformed owners. Actual three/four-client TCP tests cover deck locks, own-only hand projections, all-seat UI standings, printed-cost chosen-pair Truce through the real UI, authoritative revisions and final-seat reconnect during a pending defense. Separately labelled public-state unit fixtures check income/control ties and Heat choices; they are not claimed as organically reachable Heat gameplay.

Expanded fixtures initially assumed freshly deployed units were ready. The existing reducer correctly enters them exhausted. The fixtures were corrected to ready them through their real next Upkeep; no deployment rule was changed. Final full Linux/native counts and export checksums are recorded after actual execution.

The inherited full gate inventory includes this suite (67 commands / 40 Godot suites). No full Standard, WAN/TLS/accounts, persistent host recovery, certified scenarios, art, balance, UI visual acceptance, signed distribution or complete 754-card certification is implied. All production gates remain fail-closed. Private EOE references remain outside public GitHub.

Final Linux acceptance: official Godot 4.7.2; all 67 commands / 40 Godot suites / 7,379 assertions / 0 failures / 50 Python cases; no detected console errors. New four-seat suite 165/0, reconnect 47/0, deck lobby 52/0, TCP battle 65/0, storage 339/0. Full log SHA256: `dc382f6636b5d0ad2b33769f77fb9736cb7386f9667a6bb4d629b759ba44a38e`. Windows evidence follows separately after actual execution.

Native acceptance completed at `e7084277619e4bf999615d3bc3b6b681ecc5cbfe`: Windows 67 commands / 40 suites / 7,379 assertions / 50 Python cases passed, followed by actual export, CRC/manifest hashes and a fresh extracted headless launch. Original M18 remains clean. No embedded Authenticode signature; human visual acceptance remains unverified. See WINDOWS_M24_VERIFICATION.md and data/m24_verification.json.
