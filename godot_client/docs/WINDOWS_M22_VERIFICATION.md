# M22 candidate verification

Exact executable source: `4ea2a5496aaf93e640d237a592189888bf09a864`. Branch: `build/m22-network-deck-lobby-20261020`. Tested Git tree: `60d6b15a9c18b6d34c8849caab24b837ff3f53e9`. Later verification-only commits do not change executable source. Original `E:\KudurruKings\repo` remains clean at verified M18 `caf153d`. The native isolated worktree is `E:\KudurruKings\m19-native-sparse` (historical folder name), clean at the M22 build commit.

## Accepted checks

| Platform | Commands | Godot suites | Assertions | Python cases | Failures / detected console errors |
|---|---:|---:|---:|---:|---|
| Linux x64, official Godot 4.7.2 | 65 | 38 | 7,167 | 50 | 0 / 0 |
| ManicsPC Windows x64, Godot 4.7.2 | 65 | 38 | 7,167 | 50 | 0 / 0 |

The portable full inventory was invoked with `--branch build/m22-network-deck-lobby-20261020`. The inherited marker remains `KUDURRU_M19_FULL_GATE_PASS commands=65`; no gate was skipped or timeout relaxed. New actual TCP/deck-lobby suite: 52/0. Inherited TCP battle: 65/0. Storage/replay: 339/0. Command integrity: 170/0. Imports, critical parse checks, all six scene/main smokes and Git whitespace checks passed.

Linux full log SHA256: `e195873172e2cea3007f8b6242d0cede8def5dececa9ae022e71dc9f08a8de46`. Windows full command log SHA256: `0e614f063c96c1552ffc22c1ce78598ed24b09ca41d1b1e3911351febe0c2965`. Native logs: `E:\KudurruKings\m22_native_gate.log`, `m22_native_gate_commands.log`, `m22_native_export.log`, `m22_extracted_launch.log`. Machine-readable acceptance is `data/m22_verification.json` and `E:\KudurruKings\m22_windows_evidence.json`.

## Verified Windows artifact

`E:\KudurruKings\Builds\KudurruKings_M22_WindowsCandidate_4ea2a54.zip`

ZIP: 38,564,109 bytes. SHA256: `560de2f84bb843315b4c4dc11138a007157e792cf42c7f2c0e839d842776ea88`.

| File | Bytes | SHA256 |
|---|---:|---|
| KudurruKings.exe | 109,127,680 | `d4358a68ee7b941707bdd9182faee1fa94ad08d8de2b9a11f1bba0a08442c8b2` |
| KudurruKings.pck | 4,892,808 | `f84de706827045ea3aee0b83d754b09af2131c6c49730eeb61420b8037d32fbf` |

The exporter passed native headless staging launch and ZIP CRC validation. A separately created extraction passed safe-path checks, manifest source-commit/branch checks, EXE/PCK size and hash verification, then an actual extracted EXE headless launch with a clean console. Extracted executable: `E:\KudurruKings\Builds\M22_4ea2a54_IndependentExtractedSmoke\KudurruKings_M22_WindowsCandidate_4ea2a54\KudurruKings.exe`. Extracted launch log SHA256: `99a1f5c05f8b42a98c1353a644c0527b7fbdebfb7a944acd272ccf7d46cc34a6`.

The EXE's PE32+ certificate-table offset/size are zero: no embedded Authenticode signature. No signing credential or system security policy was changed. Human visual/gameplay acceptance, independent external certification, signing and full distribution gates remain open.

## Files changed

- `scripts/match_deck_lobby.gd` and UID: immutable owner deck locks and public readiness projection.
- `scripts/localhost_match_server.gd`: authenticated selection, authoritative source-deck validation, hidden pre-deal state and one-time match construction.
- `scripts/local_match_client_ui.gd`: saved/starter picker, lock confirmation and existing real match continuation.
- `tests/test_network_deck_lobby.gd` and UID: 52 reducer/UI/real TCP/replay assertions, legal card substitutions, malformed/forged/stale/duplicate/post-deal rejection.
- `tools/run_m19_quality_gate.ps1`: adds the new suite to the inherited portable inventory.
- `tools/export_m22_windows.ps1`: branch-guarded native candidate packaging and staging launch.
- `docs/M22_NETWORK_DECK_LOBBY.md`, `docs/CANON_CONFLICT_LEDGER_M19.md`, this report and `data/m22_verification.json`: scope, dependency finding and measured evidence.

## Shipping remains closed

No new card IDs are enabled. All 754 source cards remain production uncertified. Existing 121-template / 23-system ledger remains 6 candidate PASS / 11 IN_PROGRESS / 6 BLOCKED. Full Boss Trials/optional capture, jurisdiction/raids, Names/Arbitration/Sites, certified scenario goals, solo-to-four-seat remote play, collection progression, certified art, UI/playtests/balance and signed production distribution remain unfinished. This batch is an integrated two-seat loopback deck-selection improvement, not WAN multiplayer certification. Private EOE references stay outside public GitHub.

Stagger and Bind/Capture still require material canon decisions. Lantern Gecko remains disabled because the current legal live match cannot reach its Silence producer's Heat threshold. Historical mechanics were not activated. Source-derived deck legality, seven phases, optional Resolution capture, combat axes/resources and defender-owned decisions remain intact.
