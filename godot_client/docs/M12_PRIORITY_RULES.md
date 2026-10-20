# Kudurru Kings M12 ? Real Opponent Choice and Priority

Branch: build/m12-player-priority-20261020.
Engine: Godot 4.7.2. The production Standard release gate remains CLOSED.

M12 adds a server-authoritative response queue for printed Edicts that
require the affected player, rather than the caster, to choose a
consequence. The queue suspends normal phase advancement, preserves
ownership, journals each decision under its own monotonic revision,
and is deterministic under local save/replay. The localhost transport
reveals legal options only to the seat making that response.

**182 Public Reckoning:** all opponents with Heat at least 4 and at
least one legal option must choose one of discard a hand card, exhaust
a ready unit, or lose two Oath. Resource insufficiency or empty zones
remove unavailable options. Opponents with no possible consequence
are not forced into an impossible action.

**190 Censor Audit:** target a player with Heat at least 3; that
player must choose to discard a Name from hand or Silence a friendly,
unsilenced unit. Neither choice is auto-made by the caster. If neither
option can be performed, the target is ineligible.

The deterministic opponent can respond out of turn; a human in that
position sees the response controls, legal hand discards and unit
selection. Host state and source hashes are checked before every
transition. The real source deck remains 36 cards: 21 Characters,
2 Sites, 4 support cards and 9 source-verified Edicts.

Tests: test_priority_choices.gd tests consequence legality, exact
source hashes, Oath/discard/status transitions, ownership, invalid
and out-of-turn choices (48 checks); test_priority_ui.gd tests actual
human-victim controls, automatic opponent responses and hidden option
projection over localhost (20 checks). Run run_m12_quality_gate.ps1
with all existing regression tests and native Windows export checks.

M12 is a PREVIEW, not finished Standard. Full Boss/Trial/Bind/capture,
remaining Edicts, Names, all printed characters/Boss legacy text,
all Field/Line/Geas interactions, collection rewards, WAN 2-4 seats,
artwork and release signing remain incomplete. Never silently map
deprecated supply/recoil/Wind/Eye mechanics; EOE original Bible and
Canon/Crosswalk remain superior to conflicting migrated lore.
