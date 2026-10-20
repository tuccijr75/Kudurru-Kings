extends SceneTree
var passed := 0
var failed := 0
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		printerr("FAIL: " + label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene: PackedScene = load("res://scenes/real_match.tscn")
	check(scene != null and scene.can_instantiate(), "full real-match scene loads")
	if scene == null or not scene.can_instantiate(): quit(1); return
	var screen: Control = scene.instantiate()
	root.add_child(screen)
	check(screen.state.get("mode") == "M7_REAL_MATCH_CANDIDATE", "source-owned candidate state")
	check(screen.state["players"][0]["hand"].size() == 6, "source hand visible")
	check(screen.downed_target_select != null, "Condemnation targets available as separate legal choice")
	check(screen.state["players"][1]["hand"].size() == 6, "opponent hand hidden in UI")
	check(not screen.state["setup_complete"], "pregame choices before turns")
	screen._next()
	check(screen.state["players"][0]["setup_ready"], "player pregame keep")
	check(not screen.state["setup_complete"], "opponent still undecided")
	screen._next()
	check(screen.state["setup_complete"], "opponent pregame keep")
	check(screen.state["phase"] == 0, "pre-match preserves first Upkeep")
	for i in range(3): screen._next()
	check(screen.state["phase"] == 3, "clicked through Upkeep Draw Edicts into Main")
	var eligible: Dictionary = {}
	for c in screen.state["players"][0]["hand"]:
		if c["card_family"] == "Character" and int(c["cost_sinew"]) <= screen.state["players"][0]["sinew"]:
			eligible = c
			break
	check(not eligible.is_empty(), "real Character affordable in first Main")
	if not eligible.is_empty():
		var before: int = screen.state["units"].size()
		screen._deploy(str(eligible["card_id"]))
		check(screen.state["units"].size() == before+1, "UI deployed actual card")
		check(screen.board_view.text.contains("Warfield".to_upper()), "active field visibly labelled")
	var pre_round: int = screen.state["round"]
	for i in range(4): screen._next()
	check(screen.state["seat"] == 0, "local opponent AI automatically resolves its turn")
	check(screen.state["round"] == pre_round+1, "both turns complete one round")
	check(screen.state["events"].size()>10, "source-owned deterministic action history")
	check(screen.scoreboard.text.contains("Marks"), "10-Mark win progress visible")
	check(screen.state["scenario"].contains("candidate"), "scenario labelled non-canon")
	check(not screen.state["release_certified"], "no misleading Standard certification")
	var saved_revision: int = int(screen.state["revision"])
	var snapshot: String = "user://kudurru/tests/m8_ui_slot.json"
	screen._save_game(snapshot)
	check(screen.status.text.contains("Saved local game"), "UI saves full legal snapshot")
	screen.player_faction_pick.select(4)
	screen.enemy_faction_pick.select(2)
	screen._restart()
	check(screen.state["players"][0]["faction"]=="Fateforge","player may choose a new faction")
	check(screen.state["players"][1]["faction"]=="SkyloomTemple","opponent may choose any faction")
	screen._load_game(snapshot)
	check(int(screen.state["revision"])==saved_revision,"UI reloads saved turn and deck state")
	check(screen.state["players"][0]["faction"]=="BorderstoneGuild","save restores original player faction")
	check(screen.state["players"][1]["faction"]=="UnderwellKeepers","save restores original opponent faction")
	check(screen.player_faction_pick.selected==0 and screen.enemy_faction_pick.selected==3,"UI selectors resynchronize")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(snapshot))
	screen.free()
	print("KUDURRU_M7_MATCH_UI passed=%d failed=%d" % [passed,failed])
	quit(0 if failed==0 else 1)
