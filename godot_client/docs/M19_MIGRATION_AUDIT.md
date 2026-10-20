# M19 migration audit and command integrity

Baseline: `build/m18-live-network-battle-20261020`, `caf153dcf400b0f461de6b3c9a188e84e4b89022`.
Development branch: `build/m19-command-integrity-20261020`. Production CLOSED.

## Access and provenance

GitHub connector confirmed repository read/push permissions and the baseline commit. ManicsPC initially confirmed the exact branch/SHA, clean working tree and installed Godot path. No AGENTS.md was found in that checkout. The Windows M18 gate completed with exit 0 and KUDURRU_M18_TWO_CLIENT_REAL_BATTLE_QUALITY_GATE_PASS (340.26 seconds); all original tests and scene smokes passed. Remote calls temporarily timed out before its result was retrieved. No remote source patch was executed. Preparatory script writes outside the repository timed out; later checks confirmed both files exist. They were never executed.

Work continued in an isolated clone of the same Git commit using official Godot 4.7.2 Linux (`4.7.2.stable.official.ed1daf0bf`). Windows export/extracted launch and interactive visual verification remain unverified for M19. The M18 ZIP is prior handoff evidence, not a newly certified artifact.

All eleven uploaded Markdown files matched their supplied manifest SHA256 values. Repository Shipping Rules exactly match the uploaded authority SHA256 `7420d543e18cf2ef05b2442aaef752018b011fffe38420252a214aa7e76653ee`. Private EOE references remain outside Git. The GitHub issue search returned no issues; the durable ledger is source-controlled rather than a claim that GitHub issues were created.

Git text normalization removes embedded CRLFs from the master CSV. Reconstructing embedded cell newlines as CRLF with LF row separators reproduces the exact baseline raw master hash `1830d6080c70838b656c84163ebbfba2177898200c6106c9778530625d009059`; no card values or tracked source content were changed. Run generators against that verified representation. This portability issue must be solved before calling generic Linux checkout provenance automatic.

## Source and completion evidence

`data/full_game_completion_audit.json` inventories all 754 records / 121 templates and 23 domains: 6 PASS, 11 IN_PROGRESS, 6 BLOCKED. These PASS labels describe candidate capabilities, not production certification. All 754 cards remain production uncertified. Ten of fifteen Edicts are live candidate effects. `data/final_completion_ledger.json` has one row per original card plus system closure criteria; regenerate with `tools/build_completion_ledger.py`.

The production contract still contains historical M7/M8 headers, and the M18 gate has stale M7 prose. Current M18 source/docs govern executable behavior; Shipping Rules and latest explicit approvals govern legality. No historical draft mechanics were activated.

## Implemented slice

The host previously converted fractional JSON revisions with `int()` before validating them. The attacker reducer similarly truncated payments, and hand/target selectors and replay identities also accepted lossy casts. M19 validates finite, exactly integral, JSON-safe numbers before conversion and rejects malformed string/target-array fields before mutating state. The same contract is used by live reduction, transport and save replay. Existing phase, ownership, resource bounds and stale-action gates remain authoritative. Existing client refusal UI displays specific rejection codes; actual socket/UI tests exercise it.

Whole JSON numbers remain compatible. Legitimate legacy zero-spend defense remains legal. Combat still requires separately owned declaration and defense actions; no opponent payment authority is added. No new card is activated.

`tests/test_command_integrity.gd` covers malformed types, fractions, nonfinite/oversized numbers, immutable rejection, replay identity, real card hand-limit selection/conservation and refusal UI. `test_network_combat_e2e.gd` adds real TCP revision/payment abuse followed by the existing valid two-player combat. The Python socket harness accepts `KUDURRU_GODOT` and uses platform-appropriate process termination.

## Verification and next step

Focused Linux checks passed: command integrity 170/0, defender priority 43/0, actual socket battle 53/0. The first equivalent M19 Linux full run passed 63 commands, 37 Godot suites / 6,755 assertions and 50 Python test cases; zero script/console failures. The subsequent checked-in portable gate adds ledger generation (64 commands). See M19_VERIFICATION.md for final recorded outcomes.

Use `tools/run_m19_quality_gate.ps1` on the authorized Windows development checkout, or `python godot_client/tools/run_m19_quality_gate.py --godot /absolute/path/to/Godot --log /absolute/path/to/log` on Linux; `tools/export_m19_windows.ps1` requires a clean committed branch. Linux results and console scans are recorded in the companion verification report after completion. Windows certification remains a separate gate.

Next dependency-safe content work requires resolving the source gaps in `CANON_CONFLICT_LEDGER_M19.md`; do not make Dust Court Recess playable by treating Stagger as a cosmetic flag. Full Boss, jurisdiction, Arbitration, multiplayer, rewards, art and distribution remain open.

## Native migration closure, 2026-10-20

The isolated worktree was recovered at exact M19 `4027d4c`; full Windows gate, native export, ZIP integrity/hash verification and a separate extracted launch subsequently passed. M18 remains clean at `caf153d`. M21 was then tested/exported separately at `59a539e`, including M20 save validation and M21 Halo Pup. See `WINDOWS_M19_M21_VERIFICATION.md`; earlier pending statements describe the initial audit stage. Production remains CLOSED.
