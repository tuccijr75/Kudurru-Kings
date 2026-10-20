# M19 verification evidence

Baseline `caf153dcf400b0f461de6b3c9a188e84e4b89022`; branch `build/m19-command-integrity-20261020`.

| Layer | Evidence | Status |
|---|---|---|
| Source | Uploaded manifest matches all 11 Markdown files; Shipping Rules SHA matches repo; 754 original records/121 templates | Verified |
| Original M18 Windows | `run_m18_quality_gate.ps1`, exit 0, final M18 pass marker; 37 socket/UI checks | Passed on ManicsPC |
| M19 focused Linux | Command integrity 170/0; defender ownership 43/0; live socket battle 53/0 | Passed |
| M19 full Linux | 37 Godot suites, 6,755 assertions; 50 Python test cases; imports, parse checks, 6 scene/main smokes; stdout/stderr scanned | Passed: KUDURRU_M19_FULL_GATE_PASS commands=64 |
| Portable gate | `python godot_client/tools/run_m19_quality_gate.py --godot <4.7.2 executable> --log <log>`; 64 commands including ledger generation | Passed on Godot 4.7.2 Linux |
| Windows M19 | `run_m19_quality_gate.ps1` | Passed on ManicsPC: 37 suites / 6,755 assertions and 50 Python cases |
| Windows export / ZIP / extracted launch | `export_m19_windows.ps1`, then independent extraction/launch | Passed: export, ZIP hashes/CRC, separate extracted launch at source `4027d4c` |
| Human visual/gameplay certification | No graphical approval in this session | Unverified |
| Production | 0/754 certified; 6 blocked + 11 in-progress system gates | CLOSED |

The updated Python TCP harness was also run independently after adding server-console capture: 1/1 test passed. It preserves the Windows default executable and process-tree termination while accepting `KUDURRU_GODOT` on Linux. Its server stdout/stderr is scanned for Godot errors before success.

Save/replay, physical source-card conservation and malformed/opponent-owned decisions are exercised by existing full-match and new regression suites. Injected battle and hand-limit fixtures are labeled as fixtures; they do not claim organic full Standard play or art verification.

No protected-main update, canon promotion, account reward, WAN exposure or production signing occurred. The next content decision is Stagger semantics/expiry (Edict 192); Boss Bind/capture adjudication also remains an explicit rules dependency.

Subsequent native migration completed on 2026-10-20: see `WINDOWS_M19_M21_VERIFICATION.md` for artifacts, checksums, failed attempts and recovery prerequisites. The M19 candidate is distinct from the later M21 build.
