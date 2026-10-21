# M25 jurisdiction and arbitration audit

Baseline: `45999124d5d6a19d539efe8c7c66734ea4dec290`. Production CLOSED.

## Implemented change

The existing `jurisdiction_core.gd` reducer now validates persisted state before creating Lines, adding Salt Covenant, or reducing a crossing. It verifies supported source IDs against current catalog text and exact pinned hashes, stored hashes, unique Line identities, active endpoints, Threshold Stair's Threshold boundary, controller bounds and state container/revision types. A forged persisted object can no longer bypass source validation merely by being inserted into the `lines` or `laws` array.

Crossing commands reject boolean, string, fractional and negative resource amounts and malformed seats/revisions rather than silently coercing them. Integral floating-point values remain accepted for JSON transport. All rejected and accepted operations leave their input state unchanged. Existing toll/status outputs remain unchanged for valid source-backed lab inputs.

This hardens an existing isolated reducer. It does not add a live traversal command, activate Stagger, establish trusted player resource balances, or certify full jurisdiction. The lab's `player` balance must come from authoritative state when it is integrated; it must never be forwarded from an untrusted client.

## Verified implementation boundaries

| Domain | Existing executable coverage | Remaining production work |
|---|---|---|
| Fields | Integrated candidate has fixed Sanctuary/Warfield positions; isolated jurisdiction accepts two distinct canonical tags | Dynamic source-backed Field establishment/replacement and complete position/ownership rules |
| Lines/Geasa | Isolated source-pinned 205 Salt Covenant, 222 Threshold Stair, 232 Kudurru Nail crossings | Live movement, controller-owned payment choices, trigger queue, statuses and full card interactions |
| Sites/raids | Candidate deploys supported Sites and applies their existing effects | Full raid legality/action/outcome integration and verified two-Mark scoring |
| Names | Persistent real-effect sandbox objects; Name installation Heat exists there | Complete match-law area, upkeep/overwrite/expiry and all fifteen source Name effects |
| Arbitration | Isolated sealed Oath bids, public readiness, source Face-off and Seize | Live owner-authenticated decisions, full outcome windows, Suppress/Corrupt, and optional Injunction expansion |

## Material decisions and source gaps

- Shipping 17 names Staggered but supplies no effect or expiry. Source 222/232 lab outputs are status flags only; they cannot establish shipping Stagger behavior. Existing C01 remains unresolved.
- Shipping 21 establishes two active Fields and Lines/Geasa, but does not itself define full movement geometry or which actions cross each Line. Source cards must supply applicable establishment/traversal rules; no universal movement rule is invented.
- Existing lab partial payments allocate Oath to Salt Covenant before Threshold Stair. Shipping 21 and the three pinned cards do not independently establish that simultaneous toll-choice order. Before live integration, specify controller-owned allocation or an approved ordering rule. The current isolated result is not promoted to canon.
- Shipping 22 says successful Site raids score two Marks, but it does not define a universal raid initiation/success procedure. Integrate exact source `raid_condition` rules before awarding any raid Marks.
- Shipping 24.4 names Seize/Suppress/Corrupt but does not define Suppress/Corrupt effect duration and full state changes. Existing reducer correctly rejects those unknown outcomes. Shipping 24.3 beats historical defender-favored bid ties; no conflict remains there.
- Shipping 26 includes an Arbitration win without seizure worth one Mark. Existing isolated Seize-only resolution does not implement that outcome; full success-option semantics must precede score certification.
- Existing tied-bid Face-off chooses Authority in the lab. Shipping 24.3 requires Face-off, while Shipping 15 says the same contested axis; universal Arbitration axis selection needs source reconciliation before live activation.

## Focused acceptance

Run `Godot_v4.7.2-stable_linux.x86_64 --headless --path godot_client --script res://tests/test_jurisdiction_core.gd`.

The expanded suite tests valid source crossings, both toll outcomes, deterministic replay, resource conservation, immutable inputs, forged hashes/IDs/controllers/endpoints, duplicate persisted identities and malformed state/command values. Full-project and Windows certification remain the integration owner's responsibility.
