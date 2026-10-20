# M21 — Halo Pup Displace cancellation in real matches

Base: M20 `8b1a29d26778adb59a5925a0db3c37ce5d2a7a7a`.
Branch: `build/m21-halo-pup-guard-20261020`. Production CLOSED.

## Source and behavior

Original card 241, Halo Pup, prints: “Radiant Guard: Once per round, cancel Displace against Host.” Its normalized rules SHA256 is `9d8b1b4b296c74bcd2ce75bf3c18cb49671e25728cf8cd1cb7e486a6ccd554d1`, already pinned in the integrated match whitelist. Card 186, River Evacuation, is the current integrated Displace producer. Halo Pup was already deployable, but that producer ignored its effect.

The shared `match_pets.gd` reaction now cancels the first valid Displace against its actual Host each round. This follows the printed imperative; it adds no optional payment or player-selected reaction. Each physical attachment records its consumed round, with the next round becoming available by comparison. The reaction requires the attachment and Host to have the same controller. Source drift fails the effect closed. Validation and payment still belong to the existing authoritative reducer: illegal or unaffordable casts cannot consume the guard, while a legal canceled spell still spends the caster's card and printed cost. A second target without protection moves normally.

The action commits once, journals canceled and completed displacement separately, and both client presentations show Radiant Guard READY/SPENT THIS ROUND. The TCP server uses the same reducer without a new client-controlled counter command. Current match cleanup already returns detached attachments to their owner's discard when a defeated Host auto-restores. Future Displace providers must use the shared reaction; this batch does not implement absent Line/Geas effects, other Pets or future attachment transfer rules.

## Acceptance evidence

Official Godot `4.7.2.stable.official.ed1daf0bf` on Linux, exact M21 branch: all 64 commands in the portable full gate passed. 37 Godot suites / 7,115 assertions, zero failures; 50 Python test cases; imports, critical parse checks and six scene/main smokes passed. Console scan and `git diff --check` passed. Focused outcomes: River reducer 56/0, River UI 20/0, real TCP battle 65/0, defender priority 43/0, command integrity 170/0, storage 339/0.

The new arranged-deck fixture is source legal and creates its board entirely through logged KEEP, phase and DEPLOY actions. The protected hostile cast is independently packed/replayed, proving card conservation and deterministic counter reconstruction. The TCP test uses two actual authenticated client UIs and an authoritative host. It verifies owner/caster separation, synchronized positions/counters, source reaction journal, unchanged private-hand visibility, and refusal to forge the active seat or reset the guard. Separate labeled unit fixtures cover two-target ordering and next-round eligibility.

Log SHA256: `41205dea398128fd542be3a458960e304c37b4424a0501aad7f44b14f7226ef0`. The reused gate prints `KUDURRU_M19_FULL_GATE_PASS commands=64`; it was explicitly run with `--branch build/m21-halo-pup-guard-20261020`.

## Shipping audit and remaining work

This repairs an already-present source card interaction; it activates no additional card IDs. All 754 cards remain production uncertified; the existing 23-domain ledger remains 6 candidate PASS / 11 IN_PROGRESS / 6 BLOCKED. The M19 canonical conflict ledger remains applicable, including Stagger semantics, Bind/Capture adjudication, named faction conflicts and scenario certification. No private EOE material, faction bonus, reward policy or new probability was introduced.

Native M19 materialization completed at exact commit `4027d4c`. Its first real Windows gate failed at the omitted tracked cost-panel export, before Godot tests. The three `06_Exports` files have since been restored and the cost panel regenerated with the existing tool; native validation is being retried only after normalized Git blob equivalence and a clean tree. M19/M20/M21 Windows completion or export is not claimed here. M18 remains separate.

The source audit also identified the next implementation defect: Shipping Rules 12.1 requires one card per Draw step; `Match._draw` currently refills to six and is reused for phase draws as well as setup. Correct phase drawing separately from opening-hand/mulligan refill, then exercise hand-limit choices, replay and both network hands. This is an implementation correction, not a request to change canon.
