# Kudurru Kings M9 — production systems verification and release boundaries

Branch: `build/m9-production-systems-20261020`.
Engine: Godot 4.7.2. Keep the original EOE Bible v3.1, EOE Crosswalk,
Kudurru Kings Shipping Rules, and user-approved adjustments authoritative.

## Delivered and exercised in M9

**Production-format Windows build:** Official Godot 4.7.2 export templates
downloaded from the official 4.7.2 release; SHA-256 verified as
`f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011`.
The Windows Desktop release preset produces a native x64 EXE plus separately
packed PCK; binary headless launch passes. This demonstrates technical export,
NOT release readiness of underlying content.

**Collection ledger:** `server/collection_ledger.py` uses sqlite transactions,
signed source-versioned capture receipts (HMAC server key from deployment),
atomic ownership grants and event-idempotency; a captured card's original
owner inventory is unchanged. A Boss receipt requires exactly the distinct
Stone, Veil, Authority Trial axes. Ultra eligibility requires all of a high
account progression threshold, Apex Sigils, and card-specific fragments;
threshold values are NOT guessed and unlocks stay disabled without a signed
approved server policy. Tests include concurrent duplicate capture attempts
and modified client receipts. The trusted match service still has to prove
legal capture before it may issue a receipt.

**Field/Line/Geas:** `jurisdiction_core.gd` enforces exactly two different
active canonical Fields and uses source-hashed card mechanics for Salt Covenant
(205), Threshold Stair (222), and Kudurru Nail (232) to adjudicate legal
crossing/payments/statuses in a deterministic lab. It does not silently
convert deprecated Wind/Eye, derive other Lines, or claim full jurisdiction
gameplay; most Field rules still lack a structured event implementation.

**Multiplayer transport:** `localhost_match_server.gd` and its scene run
an actual TCP server restricted to 127.0.0.1 with independent private
session tokens and server-authoritative Godot reducer actions. Two real
client sockets have completed handshakes and turns; filtered projections do
not reveal opponent hands, secret deck ordering, seed or raw history. Tests
reject wrong tokens, stale revision and out-of-turn actions. This is NOT
internet-safe: there is NO TLS, account authentication, reconnect, match
discovery, four-seat transport, or distributed anti-cheat. Never expose
this preview port to an external interface.

**Boss/capture:** `candidate_capture.gd` validates Downed+Bound+Resolution,
active actor and three distinct Boss Trials; it tests an explicitly
**unapproved** Authority Face-off adjudication proposal with correct
Character/Boss Mark values and no double rewards. Failure transitions
to Defeated; collection grant is pending trusted external authority and
the original owner remains unchanged. Default canon capture adjudication
must not be changed silently; Boss auras, stances, true Bind sources and
retaliation are not complete.

**Original card art preflight:** The user-supplied 20-PNG layered card pack
has valid decodable PNGs. Seventeen share a 1357x2009 canvas, while the
other three use different canvas dimensions, requiring layer positioning
decisions before final render certification. This is a TEMPLATE/LAYER source,
NOT 754 original character illustrations or final per-card renders.
User-supplied board and logo images are available separately but not
integrated into production-certified authored card artwork. Do not publish
unapproved private original EOE assets in the public GitHub repository.

## Absolute shipping requirements remaining

- All 754 distinct source card effects and 121 normalized effect templates
  implemented, target-legal, tested and reconciled from original source.
  Existing catalogue certifies ZERO production cards, not 754.
- Full Boss combat with upkeep/aura/retaliation, sourced Bind and legal
  three-axis Trials, a canon-approved deterministic capture resolution,
  official verified collection-copy event issuance.
- All Fields/Lines/Geasa/crossings, two-Field pressure, Sites/raids,
  arbitration Suppress/Corrupt, full scenario and 10-Mark simultaneous
  completion, legality/balance throughout all five factions and 1–4 seats.
- TLS/server identity, WAN/reconnect 2–4-player networking, privacy/anti-cheat,
  persistent progression including the exact approved Ultra thresholds,
  complete official artwork, readability/accessibility and signing/installer.
- Visual interactive Windows workstation UI QA and final canonical
  source review before publishing. An exported EXE is not the same as a
  commercially ready game.

The authoritative machine tracker is `data/full_game_completion_audit.json`.
Its M9 state is 5 PASS / 11 IN_PROGRESS / 6 BLOCKED.
Release gate `full_standard_releasable=false` remains mandatory until all
requirements pass. Production `main` is unchanged.
