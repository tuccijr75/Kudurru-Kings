# M23 candidate verification

Exact executable source: `0b60992b2e518008b57e872c58f5743a4d3ce0b9`. Branch: `build/m23-authenticated-reconnect-20261020`. Tested Git tree: `aa30940e6ea06d3ad98d7f2d60a1bca47683e08c`. Later evidence-only commits do not change executable source. M22 source `4ea2a54` and its verified candidate remain available. Original `E:\KudurruKings\repo` remains clean at M18 `caf153d`; the isolated native worktree `E:\KudurruKings\m19-native-sparse` is clean at the M23 build commit.

## Accepted checks

| Platform | Commands | Godot suites | Assertions | Python cases | Failures / detected console errors |
|---|---:|---:|---:|---:|---|
| Linux x64, official Godot 4.7.2 | 66 | 39 | 7,214 | 50 | 0 / 0 |
| ManicsPC Windows x64, Godot 4.7.2 | 66 | 39 | 7,214 | 50 | 0 / 0 |

Full gate: `python godot_client/tools/run_m19_quality_gate.py --branch build/m23-authenticated-reconnect-20261020 --godot <verified Godot 4.7.2 executable> --log <command log>`. The inherited marker is `KUDURRU_M19_FULL_GATE_PASS commands=66`; no tests were skipped or timeouts relaxed. Reconnect TCP suite: 47/0; deck lobby: 52/0; TCP battle: 65/0; command integrity: 170/0; storage/replay: 339/0. Imports, critical parse checks, six scene/main smokes and Git whitespace checks passed.

Linux complete command log SHA256: `b2bb885490c3b36906b10a572cb8e0650c6a18c104c896935a8c2321cb649abb` (`m23_final_gate_commands.log`). Windows complete command log SHA256: `91ba635bf2da7967864a8e5e3dc44d7cafec6ff8f528ab3b1a3bcdc0c7568dc8` (`E:\KudurruKings\m23_native_gate_commands.log`). Native import/gate/export and extracted-launch logs remain under `E:\KudurruKings`. Machine-readable evidence: `data/m23_verification.json` and `E:\KudurruKings\m23_windows_evidence.json`.

Eleven attached source documents were rechecked against their supplied SHA256/byte manifest without alteration. The separately supplied `01_PROJECT_CUSTOM_INSTRUCTIONS.txt` was read in full. No private reference contents were copied into this repository.

## Actual Windows artifact

`E:\KudurruKings\Builds\KudurruKings_M23_WindowsCandidate_0b60992.zip`

ZIP: 38,576,806 bytes. SHA256: `3671022f963fed9e6cba6fc0aa57216c3e89b577cce1c91b00fb088b8a2c8e0a`.

| File | Bytes | SHA256 |
|---|---:|---|
| KudurruKings.exe | 109,127,680 | `d4358a68ee7b941707bdd9182faee1fa94ad08d8de2b9a11f1bba0a08442c8b2` |
| KudurruKings.pck | 4,932,624 | `c48e5dbfb0fdc1d37b9414c56e25fef12b73b82c7bb747a0253c2000a27ff73f` |

Native staging launch, ZIP CRC, safe extraction paths, exact manifest commit/branch and EXE/PCK size/hash checks passed. A new extraction then launched the actual EXE headlessly with no detected console errors. Executable: `E:\KudurruKings\Builds\M23_0b60992_IndependentExtractedSmoke\KudurruKings_M23_WindowsCandidate_0b60992\KudurruKings.exe`. Launch log SHA256: `99a1f5c05f8b42a98c1353a644c0527b7fbdebfb7a944acd272ccf7d46cc34a6`.

The EXE's PE32+ certificate-table offset and size are zero: no embedded Authenticode signature. Signing credentials and system security settings were not changed. Human visual/gameplay acceptance and independent external distribution certification remain unverified. These checks establish a development candidate, not a complete or signed product.

## Feature evidence and files changed

- `scripts/localhost_match_server.gd`: explicit JOIN/RESUME, host-owned recovery identity, rotating active connection credentials, active-owner takeover refusal, bounded unidentified connections, no pre-authentication projections/broadcasts.
- `scripts/local_match_client_ui.gd`: RECONNECT MY SEAT, credentials retained only in the surviving window's memory, fresh authoritative projection and disabled gameplay until authentication completes.
- `tests/test_authenticated_reconnect.gd` and UID: 47 actual TCP/UI assertions including lost recovery reply, locked-deck recovery, pending defender consent, private-hand boundaries and deterministic replay/card conservation. Boundary validation is exercised through real transport; no separate isolated unit-suite claim is made.
- `tests/test_localhost_multiplayer.py`: sends the required explicit JOIN handshake. `tests/test_local_match_client_ui.gd`: updates the reservation/recovery explanation.
- `tools/run_m19_quality_gate.ps1` and `tools/export_m23_windows.ps1`: full inventory and guarded native packaging.
- `docs/M23_AUTHENTICATED_RECONNECT.md`, `docs/CANON_CONFLICT_LEDGER_M19.md`, this report and `data/m23_verification.json`: contracts, remaining gaps and measured acceptance.

## Shipping and continuation

Source contracts verified; implemented and integrated TCP-tested. Visual verification and release certification remain false. No additional card IDs or mechanics are enabled. All 754 source cards remain production uncertified; the existing 121-template / 23-system audit remains 6 candidate PASS / 11 IN_PROGRESS / 6 BLOCKED. Stagger and Bind/Capture decisions, full effects/Boss Trials/jurisdiction/Names/Sites, certified scenario goals, true solo-to-four-seat remote play, authoritative collection progression, certified art, balance/playtests and signed production distribution remain open.

Recovery requires the same host and the surviving client window's in-memory recovery key. It does not survive closing that window or restarting the host. It is loopback-only; WAN/TLS/account authentication, persistent recovery and 3–4-seat runtime are not certified. The next multiplayer dependency is the reducer's hard two-seat model and its ownership/turn-order/projection contracts; expand that in an isolated batch before advertising four-player network play. Canon conflict decisions remain in the approval queue rather than inferred from historical text. Production CLOSED.
