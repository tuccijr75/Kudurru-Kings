# M22 — source-validated network deck lobby

Base: M21 evidence head `4c20a5bace9b40bc537f2bdad4515270e63cfdb7`, descending from verified M18 `caf153d`. Branch: `build/m22-network-deck-lobby-20261020`. Production CLOSED.

## Actual integrated behavior

The network client previously always started the host's two fixed starter decks. The new HOST DECK LOBBY button starts a pre-deal, two-seat loopback lobby. Each authenticated player selects a saved deck from the existing deck builder or the existing starter. The host requires exactly 36 string source IDs and reuses the canonical deck registry with effect readiness required: deck composition, copy limits, faction locks, source hashes and unsupported-effect rejection remain binding. Pure and legal mixed decks retain their existing legality; no pure bonus is introduced.

An immutable lobby reducer validates revision and player ownership, locks each deck exactly once, and starts the real integrated match only after both locks. Player identity comes from the authenticated connection, ignoring packet seat fields. Before both locks, projections contain only readiness and lobby revision: no hand, deck IDs, random seed or match action history. The new lobby uses a cryptographically generated 48-bit seed held by the host, within exact JSON integer range. The existing direct starter host path remains available. This does not certify RNG or WAN security.

After the second lock, the existing Match.create/custom-deck pathway deals the selected source lists. The clients proceed through their independent KEEP/MULLIGAN choices and the same seven-phase reducer, combat, opponent decision and Pet reaction pathways. Existing save/replay captures exact initial deck IDs and reconstructs card conservation without adding a new gameplay command. Lobby revisions are separate from match revisions. Invalid, stale, duplicate, unauthenticated and post-deal selection requests cannot reset or mutate the match. Locked decks stay locked if a player disconnects; authenticated reconnect remains unfinished.

## Validation and production limits

Focused regression uses the real reducer plus two real Godot TCP client UIs. It checks malformed IDs/revisions, unsupported Gecko, copy caps, ownership, stale locks, no pre-deal leaks, saved-deck selection, post-deal refusal, legal opening decisions and deterministic replay with 36-card conservation per seat. The full inherited gate inventory now includes this suite (65 commands / 38 Godot suites). Exact final results and native evidence are recorded after execution, not assumed.

No new card is enabled. The canonical 754-card / 121-template / 23-system completion ledger remains conservative: 0 production-certified cards; 6 candidate PASS, 11 IN_PROGRESS, 6 BLOCKED system gates. Boss Trials/Bind/Capture, full jurisdiction/Names/Sites, certified scenario goals, solo-to-four-player remote play, account rewards/collections, certified artwork, balance/playtesting and signed production distribution remain open. No private EOE text is published. See CANON_CONFLICT_LEDGER_M19.md for unresolved decisions and the newly documented Silence dependency.

Native Windows export, extracted launch and human visual acceptance must be distinguished. A Linux pass alone does not verify the Windows candidate. Production remains CLOSED regardless of candidate build success.

Validation history: an expanded fixture initially attempted a second SuperRare Halo Pup. Source copy validation correctly refused it; the test then timed out after assuming a deal had occurred. The uncommitted fixture was corrected to a second Common Dust Mite and given early setup-failure exits. No deck limit or timeout was relaxed. The earlier failed gate log remains separate from final acceptance evidence.

Final Linux acceptance: all 65 commands passed on official Godot 4.7.2, 38 Godot suites / 7,167 assertions / 0 failures, 50 Python cases, no detected console errors. New lobby suite 52/0; inherited network battle 65/0, command integrity 170/0, storage 339/0. Full log SHA256: `e195873172e2cea3007f8b6242d0cede8def5dececa9ae022e71dc9f08a8de46`. Windows export script parsed successfully on ManicsPC; native execution evidence follows separately.
