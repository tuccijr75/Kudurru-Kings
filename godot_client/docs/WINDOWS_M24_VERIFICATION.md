# M24 — verified three/four-seat loopback candidate

Executable source: `e7084277619e4bf999615d3bc3b6b681ecc5cbfe`. Branch: `build/m24-four-seat-candidate-20261020`. Tested tree: `b6229a7f9df84cdcb1883705dc50558cf31cc8ff`. Evidence-only successors do not alter executable source. Native isolated worktree `E:\KudurruKings\m19-native-sparse` is clean at the M24 build commit; original `E:\KudurruKings\repo` remains clean and unchanged at M18 `caf153d`.

## Measured acceptance

| Platform | Commands | Godot suites | Assertions | Python cases | Failures / detected console errors |
|---|---:|---:|---:|---:|---|
| Linux x64, official Godot 4.7.2 | 67 | 40 | 7,379 | 50 | 0 / 0 |
| ManicsPC Windows x64, Godot 4.7.2 | 67 | 40 | 7,379 | 50 | 0 / 0 |

The portable full inventory ran with `--branch build/m24-four-seat-candidate-20261020`. Its inherited marker remains `KUDURRU_M19_FULL_GATE_PASS commands=67`. No test or timeout was skipped/relaxed. Four-seat suite 165/0, owner reconnect 47/0, deck lobby 52/0, TCP battle 65/0, storage 339/0, command integrity 170/0. Imports, critical parse checks, six scene/main smokes and whitespace checks passed.

New coverage includes both three and four independently authenticated TCP clients, every player's source-legal 36-card deck/own-only hand, all-owner opening choices, seven phases per seat, round wrap after the final seat, actual final-seat defending ownership, rejection of third-party control, unchanged uninvolved cards/resources, final-seat recovery while defense is pending, selected-pair Festival Truce via real UI/printed payment, and deterministic save/replay/card conservation. Labelled edge fixtures cover income/control ties and Heat relief without pretending those Heat values came from live gameplay. All deployed combatants and saved scenarios use logged real card actions.

Linux complete command log SHA256: `dc382f6636b5d0ad2b33769f77fb9736cb7386f9667a6bb4d629b759ba44a38e` (`m24_final_gate_commands.log`). Windows log SHA256: `eaf0d11af1b7dd1e18b8b0714ebc2815d3634853d34228a4ccd28b34dff8b14b` (`E:\KudurruKings\m24_native_gate_commands.log`). Native import/gate/export/launch logs and `m24_windows_evidence.json` remain under `E:\KudurruKings`. Repository evidence: `data/m24_verification.json`.

## Artifact and extracted launch

`E:\KudurruKings\Builds\KudurruKings_M24_WindowsCandidate_e708427.zip`

ZIP: 38,592,343 bytes. SHA256: `c9bd46c9a0318febaf36c5856e4c053a6a3fea696ee039081f067b8d2d7637ff`.

| File | Bytes | SHA256 |
|---|---:|---|
| KudurruKings.exe | 109,127,680 | `d4358a68ee7b941707bdd9182faee1fa94ad08d8de2b9a11f1bba0a08442c8b2` |
| KudurruKings.pck | 4,984,664 | `38867438e6c29957a33ad8b31bb89468b4ecf9e497afebd1e19a793cacde2a4a` |

Actual native staging launch, ZIP CRC, extraction path checks, pinned manifest commit/branch and EXE/PCK size/hash checks passed. The newly extracted EXE separately launched headlessly with a clean console. Path: `E:\KudurruKings\Builds\M24_e708427_IndependentExtractedSmoke\KudurruKings_M24_WindowsCandidate_e708427\KudurruKings.exe`. Launch log SHA256: `99a1f5c05f8b42a98c1353a644c0527b7fbdebfb7a944acd272ccf7d46cc34a6`.

The PE32+ certificate-table offset and size are zero: no embedded Authenticode signature. Signing credentials and system security settings were not changed. Human visual/gameplay acceptance and independent external distribution certification remain unverified.

To exercise the candidate, open the local network screen, select 3 or 4 seats beside HOST DECK LOBBY, then host in the first game window. Other windows use JOIN HOST. Every owner locks their saved candidate-ready deck or starter and chooses KEEP/MULLIGAN. The listener remains loopback-only on the same PC. This does not support internet joining.

## Changed files and scope

- `scripts/match_integrator.gd`: validated 2–4-seat setup, all-owner ready checks, full turn/round cycle, generalized income/control and combat player records, actual defender ownership and candidate AI targets.
- `scripts/match_storage.gd`: 2–4 owner validation, matching deck/faction lists, replay and conservation for every seat; old two-seat defaults retained.
- `scripts/match_deck_lobby.gd` and `scripts/localhost_match_server.gd`: configured lobby count, all-owner locks, same authenticated source-game pathway, bounded pending connections and owner recovery.
- `scripts/local_match_client_ui.gd`: host seat selector, all-seat standings/targets, private hands, explicit Truce pair, final-seat defense/reconnect and End-income forecast.
- `scripts/match_command.gd`, `scripts/match_edicts.gd`: validated chosen player IDs and exact source 191's pair-specific Truce/Heat behavior. No new card is activated.
- `tests/test_four_seat_match.gd` and UID: 165 reducer/source/replay/real TCP/UI assertions.
- `tools/run_m19_quality_gate.ps1`, `tools/export_m24_windows.ps1`: complete regression inventory and branch-guarded Windows candidate.
- `tools/audit_full_game.py`, `tools/audit_m5_readiness.py`, and their three derived JSON ledgers: correct outdated two-seat/no-recovery prose; certification gates stay closed.
- `docs/M24_FOUR_SEAT_CANDIDATE.md`, `docs/CANON_CONFLICT_LEDGER_M19.md`, this report and `data/m24_verification.json`: source contracts, canon question and measured evidence.

## Certification and canon gaps

Source contracts verified; implemented, unit tested and integrated TCP tested. Visual verification and release certification remain false. All 754 source cards remain production uncertified. The 121-template / 23-system ledger remains 6 candidate PASS / 11 IN_PROGRESS / 6 BLOCKED. No private EOE references were published.

The inherited Warfield Ascendancy objective and its objective-control tie convention remain uncertified. Shipping 13.1's tied positive-count leader question was subsequently resolved by explicit user approval on 2026-10-21: none gains conditional Sinew; normal fallback remains unchanged. The tested executable already implements that rule (C10, APPROVED_CANON_DECISIONS.md). Configured seat order remains explicit setup order, never combat Initiative. No team, faction bonus or tournament seating rule was invented.

Stagger, Bind/Capture adjudication, full source effects/legacy terms, Boss Trials/upkeep, full jurisdiction/Names/Sites/raids, certified scenario goals/simultaneous scoring, WAN/TLS/accounts/persistent recovery, collection progression, certified artwork, balance/playtests and signed distribution remain open. Solo retains the existing human/AI candidate path. Three/four-seat loopback capability is not full Standard or secure remote multiplayer certification. Production CLOSED.
