extends RefCounted
## Kudurru Kings M6: print-authoritative COMBAT ACTION ORDER ONLY.
## Higher First Strike rating acts before lower; equal ratings compare Initiative.
## Equal rating + Initiative is a simultaneous window. No damage, Guard bonus,
## target protection, retaliation or attack-victory calculation is implied.
const FX = preload("res://scripts/real_effects.gd")

static func order(card_a_id: String, card_b_id: String) -> Dictionary:
	var catalog: Dictionary = FX.catalog()
	if catalog.is_empty():
		return {"ok": false, "error": "CARD_CATALOG_UNAVAILABLE"}
	var a: Dictionary = FX.find_card(catalog, card_a_id)
	var b: Dictionary = FX.find_card(catalog, card_b_id)
	if a.is_empty() or b.is_empty():
		return {"ok": false, "error": "UNKNOWN_REAL_CARD"}
	for card in [a,b]:
		if not ["Character", "Boss"].has(str(card["card_family"])):
			return {"ok": false, "error": "SOURCE_NOT_COMBAT_CAPABLE"}
		if str(card.get("combat_stat_provenance", "")) != "SOURCE_HASHED_PRINTED_V1":
			return {"ok": false, "error": "STAT_SOURCE_NOT_CERTIFIED"}
		var fs: int = int(card.get("first_strike_rating", -1))
		var guard: int = int(card.get("guard", -1))
		var ini: int = int(card.get("initiative", -1))
		if fs < 1 or fs > 7 or guard < 1 or guard > 7 or ini <= 0:
			return {"ok": false, "error": "COMBAT_RATING_INVALID"}
		if not bool(card.get("first_strike", false)):
			return {"ok": false, "error": "FIRST_STRIKE_MISMATCH"}
	var fa: int = int(a["first_strike_rating"])
	var fb: int = int(b["first_strike_rating"])
	var ia: int = int(a["initiative"])
	var ib: int = int(b["initiative"])
	var first: int = -1
	var reason := "SIMULTANEOUS"
	if fa != fb:
		first = 0 if fa > fb else 1
		reason = "FIRST_STRIKE_RATING"
	elif ia != ib:
		first = 0 if ia > ib else 1
		reason = "INITIATIVE"
	return {
		"ok": true, "first_index": first, "reason": reason,
		"first_strike": [fa, fb],
		"initiative": [ia, ib],
		"guard": [int(a["guard"]), int(b["guard"])],
		"combat_results_resolved": false,
		"guard_protection_resolved": false,
		"production_match_certified": false,
	}
