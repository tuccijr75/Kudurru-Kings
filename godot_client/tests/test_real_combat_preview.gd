extends SceneTree
const FX = preload("res://scripts/real_effects.gd")
const Adj = preload("res://scripts/adjacency_rule.gd")
const Preview = preload("res://scripts/real_combat_preview.gd")
var passed := 0
var failed := 0
func _check(ok: bool, reason: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		printerr("FAIL: " + reason)
func _initialize() -> void:
	_run()
	print("KUDURRU_REAL_COMBAT_PREVIEW passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)
func _run() -> void:
	var source: Dictionary = FX.catalog()
	var ids: Array = []
	for card in source["cards"]:
		if Adj.has_compiled_rule(str(card["card_id"])):
			ids.append(str(card["card_id"]))
	_check(ids.size() == 423, "423 eligible printed-only adjacency cards")
	var attacker: Dictionary = FX.find_card(source, ids[0])
	var defender: Dictionary = FX.find_card(source, ids[1])
	var result: Dictionary = Preview.preview(ids[0], ids[1], "Stone", 0, 0)
	_check(result["ok"], "real card comparison available")
	_check(result["attacker_total"] == int(attacker["stone"]), "printed source Stone stat preserved")
	_check(result["defender_total"] == int(defender["stone"]), "defender Stone stat preserved")
	_check(not result["full_combat_certified"], "not a false full-game pass")
	_check(result["not_applied"].has("guard"), "conflicted Guard not applied")
	var boosted: Dictionary = Preview.preview(ids[0], ids[1], "Stone", 1, 0)
	_check(boosted["attacker_total"] == int(attacker["stone"]) + 1, "actual +1 adjacency on attack")
	_check(boosted["defender_total"] == int(defender["stone"]), "defender unaffected")
	var response: Dictionary = Preview.preview(ids[0], ids[1], "Veil", 0, 1)
	_check(response["defender_total"] == int(defender["veil"]) + 1, "defender adjacency applies in Veil")
	var same: Dictionary = Preview.preview(ids[0], ids[0], "Authority", 0, 0)
	_check(same["preliminary_comparison"] == "FACE_OFF_REQUIRED", "equal totals are not invented victories")
	_check(Preview.preview(ids[0], "16", "Stone", 0, 0)["error"] == "CHARACTER_ONLY_PREVIEW", "Boss effects not faked")
	_check(Preview.preview(ids[0], ids[1], "Wind", 0, 0)["error"] == "INVALID_AXIS", "deprecated axis blocked")
	_check(Preview.preview(ids[0], ids[1], "Stone", -1, 0)["error"] == "INVALID_ADJACENCY", "bad context blocked")
	var sandbox: Dictionary = FX.sandbox()["state"]
	sandbox["phase"] = "Main"
	var deployed: Dictionary = FX.cast(sandbox, {"seat":0,"revision":0,"card_id":"216","args":{}})
	_check(deployed["ok"], "actual Bitumen Furnace played into sandbox")
	var original: String = JSON.stringify(deployed["state"])
	var bonus: Dictionary = Preview.preview(ids[0], ids[1], "Stone", 0, 0, deployed["state"])
	_check(bonus["site_bonus"] == 1, "source Site rule adds 1 attacking Stone")
	_check(bonus["attacker_total"] == int(attacker["stone"]) + 1, "Site rule integrated with real Character stat")
	_check(JSON.stringify(deployed["state"]) == original, "preview changes no permanent state")
	_check(Preview.preview(ids[0], ids[1], "Stone", 0, 0, {"mode":"LIVE"})["error"] == "INVALID_SANDBOX_CONTEXT", "no preview in production")
