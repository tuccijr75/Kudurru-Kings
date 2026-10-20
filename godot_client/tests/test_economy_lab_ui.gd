extends SceneTree
## Headless scene-interaction smoke: tests wiring, not rendered pixel quality.
var passed := 0
var failed := 0

func _check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		printerr("FAIL: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/economy_lab.tscn")
	_check(scene != null and scene.can_instantiate(), "lab scene instantiates")
	if scene == null or not scene.can_instantiate():
		quit(1)
		return
	var view: Control = scene.instantiate()
	root.add_child(view)
	_check(view.state.get("mode") == "DEV_ECONOMY_ONLY", "scene starts in restricted lab mode")
	_check(not view.state["setup_complete"], "scene starts with pregame setup")
	_check(view.card_buttons.size() == 6, "six selectable hand UI slots")
	_check(view.advance_button.disabled, "advance gated until setup complete")
	for i in range(4):
		view._dispatch("KEEP")
		_check(view.state["setup_ready"][i], "keep button action handles each seat")
	_check(view.state["setup_complete"], "all seats finish setup")
	_check(not view.advance_button.disabled, "advance enabled when setup complete")
	for i in range(3):
		view._dispatch("ADVANCE")
	_check(view.state["phase"] == 3, "reaches Main via UI")
	var p: Dictionary = view.state["players"][0]
	var available: Dictionary = {}
	for card in p["hand"]:
		if (card["card_family"] == "Character" or card["card_family"] == "Site") and (
			int(card["cost_sinew"]) <= int(p["sinew"]) and
			int(card["cost_sigil"]) <= int(p["sigil"]) and
			int(card["cost_oath"]) <= int(p["oath"])):
			available = card
			break
	_check(not available.is_empty(), "opening hand has a test-legal deployment")
	if not available.is_empty():
		var size_before: int = p["field"].size()
		view._dispatch("DEPLOY", {"card_id": available["card_id"]})
		_check(view.state["players"][0]["field"].size() == size_before + 1, "UI deploy updates field")
		_check(view.state["players"][0]["hand"].size() == 5, "UI deploy updates hand")
	view.free()
	print("KUDURRU_M3_UI_SMOKE passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)
