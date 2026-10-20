# Windows migration and M21 candidate verification — 2026-10-20

Production CLOSED. This is a two-seat loopback development candidate, not finished 754-card Standard or signed production distribution.

## Source and working trees

- Original ManicsPC `E:\KudurruKings\repo`: branch `build/m18-live-network-battle-20261020`, commit `caf153dcf400b0f461de6b3c9a188e84e4b89022`, clean and unchanged.
- Isolated native worktree `E:\KudurruKings\m19-native-sparse`: validated M19 at `4027d4ce60cab62d1dd91371c15ace04b99f20d7`, then switched to M21 branch `build/m21-halo-pup-guard-20261020` at `59a539eeea9a7cfb8a2ba3586c94ff4a35dc47a3`. Both candidates were built from clean trees; the folder name does not identify the current branch.
- M21 includes the committed M20 save refusal/path containment fixes and M21 Halo Pup cancellation with both client presentations. No Draw change was retained: Shipping Rules 12.1 requires refill to six.
- This later evidence update changes reports/metadata only. The ZIP manifests correctly retain their actual build commits above.

## Tests and console checks

| Candidate/platform | Full gate | Godot suites/assertions | Python cases | Result |
|---|---|---|---|---|
| M19 Linux | 64 commands | 37 / 6,755 | 50 | PASS, prior recorded evidence |
| M19 Windows | Original M19 PowerShell gate | 37 / 6,755 | 50 | PASS, final M19 marker |
| M21 Linux | 64 commands, explicit M21 branch | 37 / 7,115 | 50 | PASS |
| M21 Windows | Same 64-command portable inventory, explicit M21 branch | 37 / 7,115 | 50 | PASS |

Official Godot 4.7.2 was used on both platforms. Import/parse checks, scene/main smokes, deterministic full-match replay, physical-card conservation, resource bounds and malformed/opponent-controlled decisions are included. M21 focused outcomes: River reducer 56/0; local displacement UI 20/0; actual two-client TCP battle 65/0; defender priority 43/0; storage 339/0; command integrity 170/0. Combined command stdout/stderr was scanned, including cases where process exit status is zero.

Native M21 invocation:

```powershell
python godot_client/tools/run_m19_quality_gate.py --branch build/m21-halo-pup-guard-20261020 --godot E:\Godot\Godot_v4.7.2-stable_win64_console.exe --log E:\KudurruKings\m21_native_gate_commands.log
```

Gate-log SHA256:

- M19 Windows: `be5c436ca0b8ed953fe8cb798e2d7e6b5aa1799eb93d685a2ace4e7dfb0d9b03`.
- M21 Windows command output: `c61bdf41f95efaf68cb40e174053334aab7a83d433d1dd248bac141d623ac38f`.
- M21 Linux: `41205dea398128fd542be3a458960e304c37b4424a0501aad7f44b14f7226ef0`.

## Artifacts and independent extraction

| ZIP under `E:\KudurruKings\Builds` | Bytes | SHA256 |
|---|---:|---|
| `KudurruKings_M19_WindowsCandidate_4027d4c.zip` | 38,539,809 | `7ab246d7cea6b0edeb2fc619d0f9d3dd8f7170074dfc2f1a630e6a34caae8238` |
| `KudurruKings_M21_WindowsCandidate_59a539e.zip` | 38,552,463 | `4db5b975f4a5e92d03967355ba0ed76ce7377a8ef2589a2916bcbe28b6ce759e` |

Both exports passed their staged native headless launch. Each ZIP then passed CRC/path-containment checks, was extracted into a fresh independent directory, had its EXE/PCK size/hash checked against BUILD_MANIFEST.json, and successfully launched the extracted EXE in a separate process with console scanning. Neither launch relies on the installed editor or loose source directory.

M21 extraction directory: `E:\KudurruKings\Builds\M21_59a539e_IndependentExtractedSmoke`. Its nested candidate directory contains the EXE/PCK pair. Native console evidence remains at `E:\KudurruKings\m21_extracted_launch.log`; independent verification output at `m21_independent_extraction.log`.

| M21 file | Bytes | SHA256 |
|---|---:|---|
| `KudurruKings.exe` | 109,127,680 | `d4358a68ee7b941707bdd9182faee1fa94ad08d8de2b9a11f1bba0a08442c8b2` |
| `KudurruKings.pck` | 4,852,200 | `dd28f0834b4ed796b740e0f31ec2f75bd237c449530214397a47e4ce44923e1f` |

Signing remains open. The PowerShell Authenticode cmdlet could not load its security module. Independent PE32+ inspection found certificate-table offset/size both zero, proving no embedded Authenticode signature is present. No signed-distribution or trust-chain certification is claimed.

## Failed attempts and reproducible preparation

Native results were not inferred from Linux results. Actual native blockers encountered and retained as failed evidence:

1. Missing promisor objects and stale owned locks blocked the initial full clone. Required Git objects were copied from the verified cloud repository, checked against exact Git object SHA1 and source-transfer SHA256, and materialized in an isolated sparse worktree. The original M18 checkout was not switched or patched.
2. Sparse paths initially omitted `06_Exports`; the first real gate failed its cost-panel check. The three original tracked export CSVs were restored. Windows Git newline conversion also required regenerating the cost panel with its existing `--write` tool. Normalized Git blob identity was checked and only stat/index metadata was refreshed; no cost, identity or printed rule value changed.
3. The first uninitialized Godot worktree failed the Python TCP test's 10-second readiness window. No game suites passed in that attempt. A separate editor import completed in 18 seconds without console errors; the unchanged readiness timeout and full inventory then passed. No test timeout was relaxed or test skipped.
4. Switching to M21 reconverted the cost-panel file; its preparation was repeated before the successful M21 gate. Failed logs are distinct from final passing logs.

Canonical master bytes retain SHA256 `1830d6080c70838b656c84163ebbfba2177898200c6106c9778530625d009059`, using the verified original Windows master representation. Fresh checkouts still require that provenance preparation; generic cross-platform raw-byte normalization is not claimed automatic.

## Remaining gates

All 754 cards remain production uncertified. The 23-domain ledger remains 6 candidate PASS / 11 IN_PROGRESS / 6 BLOCKED. Full Boss Trials and legal Bind/Capture, all card effects, full jurisdiction/Names/Arbitration/Sites, scenario certification, 1–4 secure WAN play, authoritative collections, artwork rights/mapping, balance, accessibility, human visual/playtest acceptance and signed production distribution remain open. Private EOE documents stay outside public Git. The Stagger definition/expiry and other canonical decisions remain unresolved in the conflict ledger. No protected merge, public release, reward grant or WAN exposure occurred.
