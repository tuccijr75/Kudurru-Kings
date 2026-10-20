extends SceneTree
var passed: int = 0
var failed: int = 0

func check(ok: bool, name: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		printerr("FAIL: " + name)

func _initialize() -> void:
	call_deferred("execute")

func execute() -> void:
	var scene: PackedScene = load("res://scenes/real_combat_lab.tscn")
	check(scene != null and scene.can_instantiate(), "M5 scene loads")
	var screen: Control = scene.instantiate()
	root.add_child(screen)
	check(screen.state["mode"] == "REAL_COMBAT_LAB", "sandbox mode only")
	check(screen.state["units"].size() == 3, "real 2-seat combat sample")
	check(screen._u("ATTACKER")["card_id"] == "421", "real attacker loaded")
	check(screen._u("DEFENDER")["card_id"] == "273", "real defender loaded")
	check(not screen.buttons["attack"].disabled, "attack UI enabled in Battle")
	screen._attack()
	check(screen._u("DEFENDER")["wounds"] == 1, "first UI attack causes one wound")
	check(screen._u("ATTACKER")["exhausted"], "UI attack exhausts attacker")
	screen._ready_fixture()
	check(not screen._u("ATTACKER")["exhausted"], "test setup can ready attacker")
	screen._attack()
	check(screen._u("DEFENDER")["wounds"] == 2, "second UI hit wounds twice")
	check(screen._u("DEFENDER")["downed"], "Downed flag displayed")
	check(screen.buttons["bind"].disabled == false, "Bind test evidence available")
	screen._bind()
	check(screen._u("DEFENDER")["bound"], "test-only bind marks downed")
	screen._resolution()
	check(screen.state["phase"] == "Resolution", "Resolution is not a Capture phase")
	screen._attempt_capture()
	check(screen.message.text.contains("CAPTURE_SUCCESS_RULE_NOT_SPECIFIED"), "no fabricated capture success")
	screen._decline()
	check(screen._u("DEFENDER")["defeated"], "decline transitions to Defeated")
	check(screen.state["players"][0]["marks"] == 1, "plain defeat scoring once")
	screen._round()
	screen._round()
	check(not screen._u("DEFENDER").is_empty(), "two full rounds still occupies slot")
	screen._round()
	check(screen._u("DEFENDER").is_empty(), "restores to owner after full round cycle")
	check(screen.state["players"][1]["hand"].has("273"), "owner card returns, no theft")
	screen.free()
	print("KUDURRU_M5_COMBAT_UI passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)
