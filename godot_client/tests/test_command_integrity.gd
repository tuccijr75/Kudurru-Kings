extends SceneTree
const Match = preload("res://scripts/match_integrator.gd")
const Command = preload("res://scripts/match_command.gd")
const Storage = preload("res://scripts/match_storage.gd")
var passed: int = 0
var failed: int = 0
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		printerr("FAIL: " + label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var base: Dictionary = Match.create(2605)["state"]
	var before: String = JSON.stringify(base)
	var invalid: Array = [null, true, false, "1", [], {}, 1.5, NAN, INF, -INF, 1e30, 9007199254740992]
	for field in ["hand_index", "target_seat", "target_controller", "attacker_spend", "defender_spend"]:
		for bad in invalid:
			var action: Dictionary = {"seat":0, "revision":0, "type":"KEEP"}
			action[field] = bad
			check(not Match.apply(base, action).get("ok", false), "reject " + field + " " + str(bad))
			check(JSON.stringify(base) == before, "rejected input immutable")
	for field in Command.STRINGS:
		var action: Dictionary = {"seat":0, "revision":0, "type":"KEEP"}
		action[field] = []
		check(not Match.apply(base, action).get("ok", false), "reject malformed string " + field)
	for value in invalid: check(not Command.whole(value), "reject lossy envelope number")
	for good in [0, 1, 2, -1, 0.0, 1.0, 2.0]: check(Command.whole(good), "accept exact JSON number")
	for malformed in [1, [1], ["A", null], {"A":true}]:
		check(not Match.apply(base, {"seat":0,"revision":0,"type":"KEEP","target_uids":malformed})["ok"], "reject malformed target list")
	var keep: Dictionary = Match.apply(base, {"seat":0, "revision":0, "type":"KEEP"})
	check(keep["ok"], "legal setup preserved")
	var kept: Dictionary = keep["state"]
	check(not Match.apply(kept, {"seat":0,"revision":0,"type":"KEEP"})["ok"], "stale command rejected")
	check(Storage.replay(kept)["ok"], "valid deterministic replay preserved")
	var tampered: Dictionary = kept.duplicate(true)
	tampered["action_log"][0]["revision"] = 0.9
	check(not Storage.replay(tampered)["ok"], "replay fractional revision cannot be truncated")
	tampered = kept.duplicate(true)
	tampered["action_log"][0]["seat"] = 0.9
	check(not Storage.replay(tampered)["ok"], "replay fractional identity cannot be truncated")
	# Source-backed fixture moves a real deck card to hand; it is not a replay claim.
	var end: Dictionary = base.duplicate(true)
	end["setup_complete"] = true
	end["phase"] = 6
	end["players"][0]["hand"].append(end["players"][0]["deck"].pop_back())
	var unchanged: String = JSON.stringify(end)
	check(not Match.apply(end, {"seat":0,"revision":0,"type":"END_DISCARD","hand_index":0.5})["ok"], "fractional index cannot select a real card")
	check(JSON.stringify(end) == unchanged, "all physical cards unchanged")
	var accepted: Dictionary = Match.apply(end, {"seat":0,"revision":0,"type":"END_DISCARD","hand_index":0})
	check(accepted["ok"] and accepted["state"]["players"][0]["hand"].size() == 6, "integer discard remains playable")
	for p in accepted["state"]["players"]:
		check(p["hand"].size() + p["deck"].size() + p["discard"].size() == 36, "36 source cards conserved")
	var scene: PackedScene = load("res://scenes/local_match_client.tscn")
	var ui: Control = scene.instantiate()
	root.add_child(ui)
	ui._received({"ok":false,"error":"INVALID_INTEGER_ATTACKER_SPEND"})
	check(ui.status.text.contains("SERVER REFUSED") and ui.status.text.contains("INVALID_INTEGER_ATTACKER_SPEND"), "UI displays authoritative rejection")
	ui.free()
	print("KUDURRU_M19_COMMAND_INTEGRITY passed=%d failed=%d" % [passed,failed])
	quit(0 if failed == 0 else 1)
