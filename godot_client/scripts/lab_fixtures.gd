extends RefCounted
## Explicitly synthetic DEV_* economic-test cards; NEVER real Kudurru cards.
## Production cards remain locked in the 754-record catalog.
const Deck = preload("res://scripts/deck_validator.gd")
const PREFIX := "DEV_ECON_"

static func _make_card(faction: String, family: String, index: int) -> Dictionary:
	var cost := {"sinew": 0, "sigil": 0, "oath": 0}
	match family:
		"Character":
			cost["sinew"] = 1 + int(index % 5 == 0)
		"Site":
			cost["sigil"] = 1
		"Pet":
			cost["sinew"] = 1
		"Relic":
			cost["sigil"] = 1
		"Edict":
			cost["sigil"] = 1
		"Boss":
			cost["sinew"] = 4
			cost["oath"] = 1
		_:
			assert(false, "Only fixture families explicitly handled")
	var key: String = "%s%s_%s_%02d" % [PREFIX, faction, family, index]
	return {
		"card_id": key, "card_name": key,
		"owner_faction": faction, "card_family": family,
		"rarity": "Common", "is_standard_legal": true,
		"scenario_only": false, "requires_faction_lock": false,
		"deck_copy_limit": 2, "playable": true,
		"dev_fixture_only": true, "rules_effects_certified": false,
		"cost_sinew": cost["sinew"],
		"cost_sigil": cost["sigil"],
		"cost_oath": cost["oath"], "upkeep_oath": 0
	}

static func deck(faction: String) -> Array:
	if not Deck.FACTIONS.has(faction):
		return []
	var cards: Array = []
	var quantities := {
		"Character": 22, "Site": 4, "Pet": 4,
		"Relic": 2, "Edict": 3, "Boss": 1
	}
	for family in ["Character", "Site", "Pet", "Relic", "Edict", "Boss"]:
		for i in range(quantities[family]):
			cards.append(_make_card(faction, family, i))
	return cards

static func is_authentic(card: Dictionary) -> bool:
	if not bool(card.get("dev_fixture_only", false)):
		return false
	var faction: String = str(card.get("owner_faction", ""))
	var family: String = str(card.get("card_family", ""))
	var id: String = str(card.get("card_id", ""))
	if not id.begins_with(PREFIX):
		return false
	# Check all values against internally generated data, not a caller's playable flag.
	for known in deck(faction):
		if known["card_id"] == id:
			return known == card
	return false
