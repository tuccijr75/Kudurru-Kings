extends SceneTree
const FX = preload("res://scripts/real_effects.gd")
const Adj = preload("res://scripts/adjacency_rule.gd")
var passed := 0
var failed := 0
func _check(value: bool, reason: String) -> void:
	if value: passed += 1
	else:
		failed += 1
		printerr("FAIL: " + reason)
func _initialize() -> void:
	_run()
	print("KUDURRU_ADJACENCY_EFFECTS passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)
func _run() -> void:
	var source: Dictionary = FX.catalog()
	_check(source.get("record_count", 0) == 754, "real catalog available")
	var count := 0
	for card in source["cards"]:
		if not Adj.has_compiled_rule(str(card["card_id"])):
			continue
		count += 1
		var id: String = str(card["card_id"])
		var zero: Dictionary = Adj.combat_test_modifier(id, card["rules_text"], "Stone", 0)
		var one: Dictionary = Adj.combat_test_modifier(id, card["rules_text"], "Veil", 1)
		var many: Dictionary = Adj.combat_test_modifier(id, card["rules_text"], "Authority", 5)
		_check(zero.get("ok") and zero["modifier"] == 0, "zero adjacency " + id)
		_check(one.get("ok") and one["modifier"] == 1, "adjacent ally " + id)
		_check(many.get("ok") and many["modifier"] == 1, "no stacking " + id)
		_check(not one["production_combat_certified"], "no premature combat release " + id)
	_check(count == 423, "423 exact source abilities")
	var known: Dictionary = {}
	for card in source["cards"]:
		if Adj.has_compiled_rule(str(card["card_id"])):
			known = card
			break
	_check(not known.is_empty(), "at least one known adjacency rule")
	if known.is_empty(): return
	var changed: String = str(known["rules_text"]) + " "
	_check(Adj.combat_test_modifier(str(known["card_id"]), changed, "Stone", 2)["error"] == "PRINTED_ABILITY_SOURCE_DRIFT", "edited source rejected")
	_check(Adj.combat_test_modifier(str(known["card_id"]), known["rules_text"], "Wind", 2)["error"] == "INVALID_COMBAT_AXIS", "deprecated Wind axis rejected")
	_check(Adj.combat_test_modifier(str(known["card_id"]), known["rules_text"], "Stone", -1)["error"] == "INVALID_SPATIAL_EVIDENCE", "negative adjacency rejected")
	_check(Adj.combat_test_modifier("16", FX.find_card(source, "16")["rules_text"], "Stone", 2)["error"] == "NO_EXACT_PRINTED_ADJACENCY_ABILITY", "other legacy Boss effects blocked")
