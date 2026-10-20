# M20 — malformed save refusal and local path containment

Base: M19 `4027d4ce60cab62d1dd91371c15ace04b99f20d7`.
Branch: `build/m20-save-integrity-20261020`. Production CLOSED.

The existing deterministic save/replay path accepted container fields before checking their types and cast several counters before proving they were whole numbers. Malformed saves could raise script errors instead of returning a refusal. A prefix-only save-folder check also accepted `..` traversal out of the intended directory.

`match_storage.gd` now validates player/history/zone containers and entries before accessing them, requires finite JSON-exact whole-number counters and ownership, checks initial deck card IDs and wrapper payload types, and validates the normalized save path before any read/write. Whole JSON numbers remain compatible. Complete reducer replay and final state hashing remain mandatory; a recomputed checksum does not authorize a forged state. This is a local integrity check, not server authentication or collection authority.

The existing match client already keeps its running state when Storage.load returns a refusal. Its integration test now writes a malformed, checksum-recomputed save and proves both the displayed error and unchanged current state. Existing legal save/load/backup/continue tests remain active. Storage regressions cover malformed containers, counters, ownership, flags, deck IDs, nonfinite seeds and traversal, including immutable rejection through replay, pack and resealed JSON unpack.

Run the unchanged 64-command M19 inventory on this isolated branch with:

```sh
python godot_client/tools/run_m19_quality_gate.py --branch build/m20-save-integrity-20261020 --godot /absolute/path/to/Godot --log /absolute/path/to/m20_full_gate.log
```

The optional exact branch argument defaults to M19, preserving existing invocation behavior. It selects the branch under test; it does not certify production readiness.

## Native migration status

M18 remains untouched on ManicsPC. M19's 21 file objects were individually hash verified and recovered. Its disposable sparse checkout at `E:\KudurruKings\m19-native-sparse` is still being materialized; checkout has not yet passed its clean-tree prerequisite. The native continuation script checks the exact M19 commit, branch, canonical master hash and clean tree before the Windows gate, then refuses export on any gate failure or generated source difference. No M19 or M20 Windows pass/export is claimed by this document.

No card effects, Trials, capture adjudication, faction assignments, shared EOE lore, resource costs, rewards or scenario rules changed. The M19 canon conflict ledger remains applicable. All 754 cards remain uncertified; Windows, human playtest, artwork and production signing gates remain open.

## Verification evidence

Official Godot `4.7.2.stable.official.ed1daf0bf` on Linux: all 64 commands passed, comprising 37 Godot suites / 7,065 assertions, 50 Python test cases, import/critical-script checks and six scene/main smokes. Console scan found no SCRIPT ERROR, ERROR:, Parse Error, Traceback or Compilation failed. Storage 339/0; match UI 29/0; command integrity 170/0; defender priority 43/0; actual socket battle 53/0. Existing full-match replay, card conservation and malformed/opponent-controlled decision suites remain green. `git diff --check` passed.

Gate log SHA256: `8c9eb80d1fdbd7fbe9e8a860f99f83f91ed1441a25ff0376b1bdcb32b9ead382`. The reused inventory prints `KUDURRU_M19_FULL_GATE_PASS commands=64`; it was explicitly run against the M20 branch above. This marker does not claim a new milestone's Windows certification.

Windows M19 source materialization last observed at 93/243 files. M19/M20 Windows gates, M20 export, independent extracted launch, visual acceptance and production distribution remain unverified. No protected branch, public release or remote server was changed.
