extends RefCounted
## Source-grounded real Character check, NOT a battle outcome resolver.
## No Guard/First Strike (schema conflict), supporters, stakes, wounds or Face-off.
const FX = preload("res://scripts/real_effects.gd")
const Adjacency = preload("res://scripts/adjacency_rule.gd")

static func preview(attacker_id: String, defender_id: String, axis: String,
		attacker_adjacent: int, defender_adjacent: int, optional_lab_state: Dictionary = {}) -> Dictionary:
	if not ["Stone", "Veil", "Authority"].has(axis):
		return {"ok": false, "error": "INVALID_AXIS"}
	if attacker_adjacent < 0 or defender_adjacent < 0:
		return {"ok": false, "error": "INVALID_ADJACENCY"}
	var source: Dictionary = FX.catalog()
	var attacker: Dictionary = FX.find_card(source, attacker_id)
	var defender: Dictionary = FX.find_card(source, defender_id)
	if attacker.is_empty() or defender.is_empty():
		return {"ok": false, "error": "UNKNOWN_REAL_CARD"}
	if attacker["card_family"] != "Character" or defender["card_family"] != "Character":
		return {"ok": false, "error": "CHARACTER_ONLY_PREVIEW"}
	var amod: Dictionary = Adjacency.combat_test_modifier(
		attacker_id, str(attacker["rules_text"]), axis, attacker_adjacent)
	var dmod: Dictionary = Adjacency.combat_test_modifier(
		defender_id, str(defender["rules_text"]), axis, defender_adjacent)
	if not amod.get("ok", false) or not dmod.get("ok", false):
		return {"ok": false, "error": "UNRESOLVED_PRINTED_ABILITY"}
	var site_bonus: int = 0
	if not optional_lab_state.is_empty():
		if optional_lab_state.get("mode") != "REAL_EFFECT_SANDBOX":
			return {"ok": false, "error": "INVALID_SANDBOX_CONTEXT"}
		site_bonus = FX.stone_attack_modifier(optional_lab_state, 0, "Warfield", axis, true)
	var key: String = axis.to_lower()
	var a: int = int(attacker[key]) + int(amod["modifier"]) + site_bonus
	var b: int = int(defender[key]) + int(dmod["modifier"])
	return {
		"ok": true,
		"attacker_id": attacker_id, "defender_id": defender_id,
		"axis": axis, "attacker_total": a, "defender_total": b,
		"attacker_adjacency_bonus": amod["modifier"],
		"defender_adjacency_bonus": dmod["modifier"],
		"site_bonus": site_bonus,
		"preliminary_comparison": "FACE_OFF_REQUIRED" if a == b else ("ATTACKER_LEADS" if a > b else "DEFENDER_LEADS"),
		"full_combat_certified": false,
		"not_applied": ["supporters", "resource_spend", "guard", "first_strike", "initiative",
			"other_abilities", "consequences", "wounds", "face_off", "boss_trials"],
	}
