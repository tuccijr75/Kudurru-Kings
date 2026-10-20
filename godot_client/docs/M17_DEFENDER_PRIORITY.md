# Kudurru Kings M17 ? Defender-Owned Combat Priority

Branch: build/m17-defender-owned-combat-20261020.
Engine: Godot 4.7.2 native GDScript, active two-seat candidate only.
Shipping Rules v1 Sections 14 and 15 are authoritative.

## Why this change is necessary

The M16 candidate allowed one ATTACK action to include both
attacker_spend and defender_spend. In a remotely submitted packet,
the attacker could thereby spend an opposing player's Sinew, Sigil,
or Oath without that player's approval. This violates the published
two-sided combat spend and supporter rules, even in local multiplayer.

The old ATTACK opcode is now rejected by the active match reducer
as DEFENDER_OWNED_COMBAT_REQUIRED. No legacy network input can
bypass the new response window.

## Real encounter interaction

1. During Battle, the active player issues DECLARE_ATTACK, specifying
   actual owned attacker and opposing defender UIDs, a legal axis,
   attacker_spend between 0 and 2 and optionally one owned, ready,
   axis-eligible supporter.
2. The reducer checks the declaration through the existing source-backed
   combat core without consuming any player resources. It journals
   COMBAT_DECLARED and creates pending_attack with the exact defender
   seat. Any source-supplied defender_spend or defender_supporter
   in a declaration is rejected as forbidden client control.
3. No normal action, further attack, End advance or Edict can proceed
   until the defender responds. The opponent player, not the caster,
   issues CHOOSE_DEFENSE choosing 0, 1 or 2 matching resources and
   optionally one own, legal supporter.
4. The existing combat core resolves source stat axis, printed
   adjacent-ally modifier, supporter half-rounded-up,
   Heat relief, actual matching resource payment, first legal
   tie Face-off and wounds, with both choices in the action log
   at independent monotonic revisions.
5. The solo AI can choose a deterministic zero-spend defense; the
   human can explicitly choose up to two resources. The two-window
   TCP client exposes the defender button only to the targeted seat,
   with attacker and defender support pickers independently.
   Server seat identity remains authoritative on every action.
6. Local saves replay both actions deterministically and preserve
   canonical card identity, card count and original source hashes.

The defender spend validator accepts only integer-valued JSON
numbers (including 0.0) in range 0-2. Fractional values, NaN, Inf,
negative amounts, amounts greater than two, and nonnumeric data
are rejected. Responder must be the actual defending seat.

## Compatibility and release boundary

Earlier local saves that never contained legacy ATTACK events can
still be replayed after normalizing the empty pending_attack field.
Old saves with immediate ATTACK events are explicitly rejected with
LEGACY_ATTACK_SAVE_UNSUPPORTED_DEFENDER_CHOICE_MISSING; the old
events cannot be silently converted into a defender-owned consent
without manufacturing actions. The original M16 Windows candidate
is preserved to load those earlier saves.

This is an actual gameplay security and interaction upgrade,
NOT a certified release. Boss aura/retaliation, full Trial adjudication,
capture-success canon, complete Lines/Geasa, 754 effect completion,
server-side account inventory, internet-safe 3-4 seat multiplayer,
signed Windows distribution and certified art remain blocked.

Tests: test_defender_priority.gd (43 direct reducer, security and
support-choice checks), test_combat_choice_ui.gd (15 actual user interface
and AI response checks), and every M1-M16 regression in
tools/run_m17_quality_gate.ps1, including source-controlled
full-match replay and two-client network privacy.
