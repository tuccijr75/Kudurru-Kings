# Kudurru Kings — Complete Production Delivery Contract

**Repository:** tuccijr75/Kudurru-Kings
**Current integration branch:** build/m7-playable-match-integrator-20261020
**Game engine:** Godot 4.7.2 / GDScript, source-owned deterministic engine
**Authority:** Original EOE Game Bible v3.1 and original EOE Crosswalk for lore/faction; KK Shipping Rules v1 for standalone gameplay, updated by user-approved decisions
**Release state:** NOT READY. M7 is a runnable local candidate, not a replacement for complete Standard.

## 1. Whole-game source audit (automated)

Run `python godot_client/tools/audit_full_game.py` from repository root. The generator uses all 754 canonical source card rows, original printed text, certified adjacency and actual code capability, and produces:

- `data/full_game_completion_audit.json` — every source card's exact effect status; all 20 production system gates; domain-level release state
- `data/effect_template_groups.json` — all 121 source-normalized effect patterns, with immutable card ID assignments and original mechanic text

**754 real cards, zero production-certified cards.** A coverage status of `M7_CHARACTER_BASIC_SANDBOX` or `M4_SOURCE_EFFECT_SANDBOX` means precisely a tested slice of printed mechanics, NOT a full legal playable card.

The source effect audit identifies:
- 500 Characters with 15 normalized text templates (423 matching the exact adjacent-ally pattern)
- 164 Bosses with 16 normalized template combinations
- 90 support/legal objects with predominantly individual abilities: 15 each of Edict, Name, Site, Pet, Relic, Host Sigil
- **121 normalized templates overall**. Do not translate a normalized pattern into a legal play effect until every deprecated axis, timing, target and source-specific exception is represented in structured data.

This source grouping is the implementation accelerator: write reusable effect operations and instantiate them from data; do not continue one class per card.

## 2. Game architecture and no-shortcut rules

Use a single authoritative match reducer whose actions have the shape `{seat,revision,type,targets,payment}`. Reject invalid mode, stale revision, wrong seat, unpayable resource, unresolved targets, wrong phase, disabled or uncertified effect, missing objective, or non-deterministic callback **before** changing state.

Data:
- 754-card canonical gameplay master, cost and source-faction migration ledger
- typed, source-hashed effect IR per card or clearly source-blocked status
- Standard deck validator (36 cards, copies, factions, rarity and family counts)
- field/board, court/Names, permanent attachments, deck/hand, turn/action event log
- site/Line/Geas and scenario event dispatch with legal target/trigger contracts

Game:
- exact seven phases: Upkeep, Draw, Edicts, Main, Battle, Resolution, End
- Sinew/Sigil/Oath, conditional End income, six-card refill, per-player free mulligan
- 2 active Fields, board/jurisdiction protection and controllable objects
- Stone/Veil/Authority, supporters, resource spends, Guard protection, numeric First Strike, Initiative, Face-off, legal consequences
- Vitality/Wounds/Downed/Bound/Defeated/restore, three distinct Boss Trials, stances/aura/retaliation
- optional Resolution capture, deterministic capture result, owner-safe one-time collection copy, plain defeats/raids/Name scoring, 10 Marks after simultaneous resolution window
- Names/Edicts/Host Sigils, persistent duration and suppress/corrupt/seize arbitration, risk/Heat/Geas
- mandatory scenario and objective control with no timezone/capacity unfairness
- 1-player AI; two through four human/network seats with server-authoritative privacy

Product:
- full searchable deck builder, valid save/load, fair solo AI and reconnectable online games
- readable four-seat board, legal actions only, live trials, Heat, binds, capture/raid eligibility, Field dominance, objective/resource projections
- layered official card renders/legally owned art, full family identity and Ultra visual overrides
- accounts, acquisitions, Ultra prerequisites (Apex Sigils, card fragments, progression), immutable reward ledger, no duplicate grant, original-owner protection
- deterministic replay/debug, logs, security, accessibility, Windows distributable/export with shipping QA

## 3. Immediate M7 candidate: what works

M7 is a completely local, source-backed **two-seat human-versus-deterministic-opponent match candidate**, directly accessible on the main Godot board through **PLAY REAL-CARD MATCH (PREVIEW)**.

It contains a constructed 36-card deck per seat:
- 30 different low-cost Characters from that seat's faction, each with the exact source-pinned shared adjacency ability
- 2 real Sites: Mirror Archive and Bitumen Furnace
- 4 real supports: Bitumen Harness twice, Halo Pup once, Dust Mite once
- all deck counts and copy/rarity limits validated; mixed support is allowed only when no printed lock is violated

Two active Fields: Warfield and Sanctuary. The candidate scenario **Warfield Ascendancy** awards a Mark during Resolution to the unique controller of Warfield. This is a development scenario, NOT approved standalone KK canon; it demonstrates the integrated full 10-Mark loop without giving unauthorized capture rewards.

M7 uses the M5 real-source combat reducer: authoritative Stone/Veil/Authority, source-checked adjacency, one supporter, 0–2 matching resource spends, deterministic Face-off and wounds. Real Stone attachments/sites are checked from actual card IDs. Mirror Archive privately reveals the actual top card once per player-turn without logging that card publicly. AI only uses its own hand and public field state. Exhausted deployment, conditional End income, draw-to-six, no duplicate Site control, host validation, immutable rejected actions, revision tracking and 36-card conservation are tested.

**No player account, network connection, progression or collection reward is touched.** The M7 deck is not a full 754-card Standard release; it contains only the explicit real-card whitelist. Unsupported abilities are blocked.

## 4. Production gates by critical path

The 20 machine-readable gate states in the generated JSON are authoritative for release certification. The following dependencies determine execution order:

**Foundation** — verify every card ID, EOE faction, signed printed text and numeric stat; reconcile all rejected Wind/Eye/supply/legacy text into user-reviewed legal templates without changing EOE canon. Require 754/754 typed source-program checks, no unimplemented critical card.

**Complete deterministic rules engine** — implement all scenario/Field/Line/Geas events, item attachment/triggers, Boss stance/Trials, full Bind/capture, complete Raid/Name/Edict/Host Sigil operations, Guardian/First Strike timing and priority. No false automatic rewards or bonus marks.

**Certified full matches** — seeded local 1–4-player matches with legal decklists, objective resolution, all 754 card rules represented, 10-Mark win determined only after complete simultaneous resolution; no loops, stalls, missing card identity or exploitable infinite income.

**Product and delivery** — full deck builder, UI art/readability, high-quality game AI, 2–4-player authoritative network sessions, safe account/progression storage, privacy/reconnect, cross-device usability and Windows packaging. Do not push into `main` or call it commercial release until all gates pass.

## 5. Execution and versioning

- Treat **this** as the continuous implementation plan; do not ask the developer to approve each mechanical task. Critical contradictions against authoritative EOE canon must still be explicitly flagged and not silently changed.
- No disconnected throwaway systems, runtime monkeypatching, placeholder production rules, or fake card effectiveness.
- Every capability must have source IDs, unit tests, deterministic replay and a negative/abuse test.
- Each branch gets a single complete gated CI command; production only after the full shipping audit reports **zero blocked or in-progress gates**.
- Current development build can be launched in Godot 4.7.2 using `E:\KudurruKings\repo\godot_client\project.godot`.

**Current release conclusion:** The integrated candidate proves source-owned turns and objectives can finish; it does not prove finished 754-card Standard, online play or rewards. Both facts must remain visible in every build/status report.
