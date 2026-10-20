# Kudurru Kings — M8 Local Gameplay Completion Report

**Scope:** Deliver the strongest locally playable two-seat build while preserving
every authoritative gameplay and EOE canon rule that is not yet implemented.
**Branch:** `build/m8-local-game-completion-20261020`
**Engine:** Godot 4.7.2 / deterministic GDScript, Windows-first
**Status:** PLAYABLE LOCAL CANDIDATE, NOT FULL STANDARD OR COMMERCIAL RELEASE

## Integrated improvements over M7

1. Five selectable launch factions for either seat; all 25 two-seat combinations
   build legitimate 36-card source-backed candidate decks and pass source validation.
2. Versioned local Save and Continue with **source-master SHA-256 pinning**, action
   ledger, complete deterministic replay verification, checksum validation and
   owner-safe card-conservation checks. A forged result is rejected even when
   a payload's checksum was recomputed.
3. 26 real Character cards per candidate deck, 2 real Sites, 4 real support cards,
   and 4 source-hashed Edicts. All counts and copy/rarity requirements pass the
   canonical 36-card validator. Real IDs are preserved; no test cards are invented.
4. Four additional Edicts operate during the actual Edicts phase with validated
   source text, target legality, exact cost payments, discard transitions, and
   revision/event history:
   - **181 Sun-Script Overload** — one Wound to every legally targetable Warfield unit,
     including friendly units; applies Downed thresholds correctly.
   - **188 Mercy Docket** — clear Silence and one Wound from a wounded/silenced
     friendly Character, with explicit target selection.
   - **191 Festival Truce** — two-seat mutual Engagement ban, each Heat -1
     (minimum zero), expires at caster's next Upkeep.
   - **193 Convoy Priority** — ready exhausted friendly unit, cannot support
     in the present round; subsequent round releases restriction.
5. Mirror Archive's once-per-turn top-card inspection, Bitumen Furnace Stone
   bonus, Bitumen Harness and Dust Mite supported source effects remain active.
6. 20 seeded end-to-end match completions and five independently replayed
   completed matches pass without uncontrolled loops or card losses.
7. The main Godot UI now permits Save/Continue, faction choices and legal
   Edict plays. These changes are validated by headless interaction tests.

## What this build does NOT certify

- Only a **two-seat local AI opponent candidate** is exposed; there is no
  2–4 seat network-hosted, encrypted, anti-cheat or ranked Standard match.
- No full 754-card production deckbuilder or 754 effect executor. The current
  exact source inventory has 423 adjacent-ally Character snippets, 10
  individual isolated M4 sandbox effects, 4 integrated M8 Edicts, 3 other
  local partial source interactions and 314 cards with unsupported or
  unresolved effects. **None of 754 cards are production certified.**
- Full Boss aura/retaliation, Three Trial and legal Bind/capture result,
  collection reward/grant/revocation protections, Lines/Geasa, Sites/raids,
  complete Guard and First Strike combat timing and source effect replacement
  effects have NOT passed the shipping gate.
- The M7 **Warfield Ascendancy** objective remains a development scenario
  and must not be represented as final KK Standard canon.
- No graphical Windows binary export: Godot 4.7.2 Windows export templates
  are not installed. The optional local portable package includes an existing
  Godot runtime plus game source and is marked as **developer preview**.

## How to run on ManicsPC

Open:
`E:\KudurruKings\repo\godot_client\project.godot`

Select **PLAY REAL-CARD MATCH (PREVIEW)** on the main board. Set both
factions, start a new game, then use the hand, phase controls, target selection,
and Save/Continue buttons. The saved match is stored locally under Godot's
`user://kudurru/solo_slot.json` path. File corruption or changes to the card
master cause a safe load failure rather than a silently rewritten match.

The complete release-tracking record is:
`data/full_game_completion_audit.json` (22 domains, five passed,
six in progress, eleven blocked).

## Non-negotiable full-game exit gate

Implement all 121 effect templates using structured source-validated rule
operations, resolving the legacy Wind/Eye/supply/recoil source mismatches
without silently changing original EOE lore. Certify all real card effects,
legal targeting and stacking, full Scenario/Field/Line/Geas control, Boss
Trials/Bind/Capture/raids, 1–4 seat scenarios, solo AI and multiplayer network
privacy, collection/Ultra progression, 10-Mark simultaneous-window resolution,
rendered art, accessibility and packaged build. Then ship only if the
production audit reports zero blocked/in-progress domains and cross-platform
end-to-end QA passes.

**M8 is a substantial playable product increment, not fulfillment of
the full final game.** This distinction is intentional and test-enforced.
