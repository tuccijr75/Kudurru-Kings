# Kudurru Kings M10 — Full Card Library Deck Builder

**Branch:** build/m10-deck-construction-20261020
**Status:** Source-level deck construction certified; full production Standard NOT certified.
**Engine:** Godot 4.7.2 / GDScript / Windows x64.

## Implemented and tested

A new main-menu option, BUILD A DECK (754 REAL CARDS), shows all canonical
card identities, original printed effect text, rarity, cost, faction, family,
and source-verified effect-readiness status. Search by name/card ID/text;
filter by faction and family; display only currently implemented effects.

Build, edit, save and reload source-legal 36-card decks. Exact composition:
36 cards, minimum 12 Characters / 2 Sites / 4 Pets+Relics, maximum
3 Bosses / 3 Names / 1 Host Sigil, per-name and source copy limits
including Super Rare 1 maximum per unique name, and canonical Ultra
identities 36 and 255. Pure and mixed faction decks are legal. Any active
card-specific faction locks and splash restrictions are enforced; the
current master has no active faction lock and all allowed_splash=true.
Unapproved pure-faction perks are never invented.

Saved source decklists live only under user://kudurru/decks. Deck names
are validated, source SHA pinned, JSON checksum checked and every ID
revalidated from immutable catalog data. This is LOCAL DECK DESIGN;
it does not establish collection ownership, account rights, or
production approval of conflicting EOE faction assignments.

The real local human-versus-AI match scene now accepts selected saved
decks ONLY when all 36 chosen cards have implemented candidate
mechanics. Unsupported cards remain searchable/editable but cannot
enter playable matches. The reducer stores initial_deck_ids in the
match state, and the local save engine replays from those exact IDs,
not a mutable on-disk decklist. Legacy M8/M9 saves without explicit
IDs retain their original default-seeded reconstruction.

## Explicit non-certifications

All 754 source cards are searchable; zero are production-certified.
The current playable subset is narrow: 423 adjacent-ally Character
descriptors, 4 source-hashed Edicts, 2 Sites, 3 support identities.
This does not finish the other 121 effect patterns or all legal effects
in combinations. The EOE Crosswalk remains final faction authority
where original KK migration conflicts exist, and flagged conflicts
cannot be resolved without explicit approval.

Still unresolved: complete Boss/Bind/Trials/Capture legal sources,
full Site raids, Lines and Geasa in live matches, all Names/Edicts and
other printed effects, 2–4 player secure WAN and reconnect, verified
collection rewards/Ultra thresholds, all official artwork, signing,
installer and interactive commercial release QA. Godot Windows export
is technically proven, but it is not a completed game certification.

## Workstation usage

Launch project.godot. Choose BUILD A DECK (754 REAL CARDS), load any
verified faction starter, edit/save the list and return to PLAY
REAL-CARD MATCH (PREVIEW). Select the saved deck before starting.
Design-only decks remain visible with a non-playable warning.

Run tools/run_m10_quality_gate.ps1 to verify full prior M1-M9
regression plus M10 registry, UI and deterministic custom-deck replay.
The complete release audit has 23 system domains: 6 PASS,
11 IN_PROGRESS, 6 BLOCKED. Full Standard remains explicitly false.
