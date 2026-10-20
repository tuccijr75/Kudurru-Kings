extends SceneTree
const Combat = preload("res://scripts/real_combat_core.gd")
const FX = preload("res://scripts/real_effects.gd")
var passed: int = 0
var failed: int = 0

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		printerr("FAIL: " + label)

func match_state(with_ally: bool = false) -> Dictionary:
	var units: Array = [
		Combat.unit("A", "421", 0, 0),
		Combat.unit("B", "273", 1, 0),
	]
	if with_ally: units.append(Combat.unit("ALLY", "407", 0, 1))
	return Combat.create([["180", "255"], ["181", "16"]], units, 20261020)["state"]

func action(s: Dictionary, extras: Dictionary = {}) -> Dictionary:
	var a: Dictionary = {"revision": s["revision"], "attacker": "A",
		"defender": "B", "axis": "Stone"}
	for k in extras: a[k] = extras[k]
	return Combat.attack(s, a)

func _initialize() -> void:
	run_tests()
	print("KUDURRU_M5_REAL_COMBAT passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)

func run_tests() -> void:
	check(Combat.create([[]], []).get("error") == "BAD_MATCH_SETUP", "no 1-seat match")
	check(Combat.create([[], [], [], [], []], []).get("error") == "BAD_MATCH_SETUP", "max 4 seats")
	check(Combat.create([["0000"], ["16"]], []).get("error") == "UNKNOWN_FACE_OFF_CARD", "only known real card ids")
	var source: Dictionary = FX.catalog()
	check(Combat.card("421")["stone"] == 6.0, "source stat stone 6")
	check(Combat.card("273")["wound_threshold"] == "2", "source threshold 2")
	var s: Dictionary = match_state()
	var before: String = JSON.stringify(s)
	check(Combat.attack(s, {"revision": 99, "attacker": "A", "defender": "B", "axis": "Stone"})["error"] == "STALE_REVISION", "stale action rejected")
	check(action(s, {"axis": "Wind"})["error"] == "INVALID_AXIS", "deprecated axis illegal")
	check(action(s, {"defender": "A"})["error"] == "INVALID_ATTACK_TARGET", "cannot attack self")
	check(action(s, {"attacker_spend": 3})["error"] == "COMBAT_SPEND_0_TO_2", "max two spends")
	check(action(s, {"attacker_spend": -1})["error"] == "COMBAT_SPEND_0_TO_2", "no negative spends")
	check(action(s, {"attacker_spend": 2, "axis": "Veil"})["error"] == "INSUFFICIENT_MATCHING_RESOURCE", "Sigil bounded")
	check(JSON.stringify(s) == before, "all rejected actions source-immutable")
	var hit: Dictionary = action(s)
	check(hit["ok"], "real source-based Stone combat resolves")
	if not hit["ok"]: return
	check(hit["event"]["wounds_applied"] == 1, "default successful attack inflicts 1 wound")
	check(hit["event"]["winner_seat"] == 0, "stone6 beats stone0")
	check(hit["state"]["units"][1]["wounds"] == 1, "wound stored on real defender")
	check(not hit["state"]["units"][1]["downed"], "first hit remains Wounded")
	check(hit["state"]["units"][0]["exhausted"], "attacker exhausted")
	check(action(hit["state"])["error"] == "ILLEGAL_COMBATANTS", "cannot attack twice without ready")
	check(hit["state"]["players"][0]["marks"] == 0, "no Mark for unbound Downed")
	var repeat: Dictionary = hit["state"].duplicate(true)
	repeat["units"][0]["exhausted"] = false # Simulated later ready transition
	var second: Dictionary = action(repeat)
	check(second["ok"], "later ready attacker can attack again")
	check(second["state"]["units"][1]["wounds"] == 2, "two wound counter")
	check(second["state"]["units"][1]["downed"], "threshold two causes Downed")
	check(second["state"]["units"].size() == 2, "Downed keeps field slot")
	check(action(second["state"])["error"] == "ILLEGAL_COMBATANTS", "Downed cannot be attacked as ready unit")
	var band: Dictionary = Combat.mark_downed_bound(second["state"], "B", "NO_SOURCE")
	check(band["error"] == "NO_CERTIFIED_BIND_SOURCE", "no universal invented Bind")
	band = Combat.mark_downed_bound(second["state"], "B", "TEST_SETUP_ONLY")
	check(band["ok"], "explicit lab setup produces Bound")
	check(band["state"]["units"][1]["downed"] and band["state"]["units"][1]["bound"], "Bound preserves Downed state")
	check(second["state"]["units"][1]["bound"] == false, "Bind input immutable")
	var res: Dictionary = band["state"].duplicate(true)
	res["phase"] = "Resolution"
	check(Combat.capture_attempt(res, 0, "B")["error"] == "CAPTURE_SUCCESS_RULE_NOT_SPECIFIED", "no invented capture probability")
	check(Combat.decline_capture(band["state"], 0, "B")["error"] == "NOT_RESOLUTION", "Resolution required")
	var declined: Dictionary = Combat.decline_capture(res, 0, "B")
	check(declined["ok"], "eligible player may decline capture")
	check(declined["state"]["units"][1]["defeated"], "declined target becomes Defeated")
	check(not declined["state"]["units"][1]["bound"], "Bound flag cleared")
	check(declined["state"]["players"][0]["marks"] == 1, "plain Character defeat awards one Mark")
	check(declined["state"]["units"].size() == 2, "Defeated still occupies slot")
	check(Combat.decline_capture(declined["state"], 0, "B")["error"] == "CAPTURE_NOT_ELIGIBLE", "no double score")
	var restore1: Dictionary = Combat.restore_defeated(declined["state"])
	check(restore1["state"]["round"] == 2, "first subsequent round")
	check(restore1["state"]["units"].size() == 2, "not yet two full rounds")
	var restore2: Dictionary = Combat.restore_defeated(restore1["state"])
	check(restore2["state"]["round"] == 3, "second full subsequent round starts")
	check(restore2["state"]["units"].size() == 2, "two full rounds must elapse before restoration")
	var restore3: Dictionary = Combat.restore_defeated(restore2["state"])
	check(restore3["state"]["round"] == 4, "third round transition")
	check(restore3["state"]["units"].size() == 1, "restored after two complete intervening rounds")
	check(restore3["state"]["players"][1]["hand"].has("273"), "returns to owner's hand if space")
	var full: Dictionary = declined["state"].duplicate(true)
	full["players"][1]["hand"] = ["180","180","180","180","180","180"]
	full = Combat.restore_defeated(full)["state"]
	full = Combat.restore_defeated(full)["state"]
	full = Combat.restore_defeated(full)["state"]
	check(full["players"][1]["deck"].has("273"), "full hand restores to owner's deck")
	var unsupported: Dictionary = match_state()
	unsupported["units"][0] = Combat.unit("A", "255", 0, 0)
	check(action(unsupported)["error"] == "COMBAT_EFFECT_UNCERTIFIED", "Adamu legacy abilities not guessed")
	var ally: Dictionary = match_state(true)
	var support_result: Dictionary = action(ally, {"attacker_supporter": "ALLY", "attacker_spend": 2})
	check(support_result["ok"], "one adjacent real-card supporter and two matching spends")
	if support_result["ok"]:
		check(support_result["event"]["totals"][0] == 12, "6 Stone +1 adjacency +3 half support +2 spend")
		check(support_result["state"]["players"][0]["sinew"] == 0, "two Sinew paid exactly")
		check(support_result["state"]["units"][2]["exhausted"], "supporter exhausts")
		check(support_result["state"]["players"][0]["heat"] == 0, "supporter Heat cannot go negative")
	check(action(ally, {"attacker_supporter":"B"})["error"] == "SUPPORTER_NOT_ALLIED", "enemy cannot support attacker")
	check(action(ally, {"attacker_supporter":"DOES_NOT_EXIST"})["error"] == "SUPPORTER_UNKNOWN", "unknown supporter blocked")
	var face: Dictionary = Combat.faceoff(s, 0, 1, "Stone")
	check(face["ok"], "Face-off resolves top valid real combat cards")
	check(face["winner"] == 0, "Adamu top Stone10 beats Void Augur Stone8")
	check(face["chain"].size() == 1, "single comparison resolves no resource spend")
	check(face["deck_a"].size() == 2 and face["deck_b"].size() == 2, "revealed cards shuffled back")
	var tie_state: Dictionary = Combat.create([["273"], ["273"]],
		[Combat.unit("A", "273", 0, 0), Combat.unit("B", "273", 1, 0)])["state"]
	check(Combat.faceoff(tie_state, 0, 1, "Stone")["error"] == "FACE_OFF_UNRESOLVED_BOTH_EMPTY", "identical Face-off cannot invent winner")
	check(action(tie_state)["error"] == "FACE_OFF_UNRESOLVED_BOTH_EMPTY", "unresolved Face-off makes no mutation")
	check(Combat.faceoff(Combat.create([["180"], ["255"]], [])["state"], 0, 1, "Stone")["winner"] == 1, "no valid combat card loses Face-off")
	check(JSON.stringify(tie_state["events"]) == "[]", "unresolved tie emits no scoring event")
	# Separate lifecycle contract: Bosses require all three *distinct* Trials.
	var boss_unit: Dictionary = Combat.unit("BOSS", "16", 1, 0)
	boss_unit["downed"] = true
	boss_unit["bound"] = true
	var boss_state: Dictionary = Combat.create([["255"],["16"]], [boss_unit])["state"]
	boss_state["phase"] = "Resolution"
	check(Combat.decline_capture(boss_state, 0, "BOSS")["error"] == "BOSS_TRIALS_INCOMPLETE", "untried Boss cannot be captured or declined through capturable path")
	boss_state["units"][0]["trials_won"] = ["Stone","Stone","Veil"]
	check(Combat.capture_attempt(boss_state, 0, "BOSS")["error"] == "BOSS_TRIALS_INCOMPLETE", "repeat axis does not complete three Trials")
	boss_state["units"][0]["trials_won"] = ["Stone","Veil","Authority"]
	check(Combat.capture_attempt(boss_state, 0, "BOSS")["error"] == "CAPTURE_SUCCESS_RULE_NOT_SPECIFIED", "Trial-complete Boss attempt still needs certified success adjudicator")
	var boss_defeat: Dictionary = Combat.decline_capture(boss_state, 0, "BOSS")
	check(boss_defeat["ok"], "Trial-complete Boss capture may be declined")
	check(boss_defeat["state"]["players"][0]["marks"] == 0, "Boss plain defeat never receives automatic Character Mark")
	var win_state: Dictionary = res.duplicate(true)
	win_state["players"][0]["marks"] = 9
	var winner: Dictionary = Combat.decline_capture(win_state, 0, "B")
	check(winner["state"]["players"][0]["marks"] == 10, "ten Marks threshold reached")
	check(winner["state"]["winner"] == 0, "victory assigned only at threshold")
	var illegal: Dictionary = match_state()
	illegal["active_seat"] = 1
	check(action(illegal)["error"] == "NOT_ACTIVE_SEAT_ATTACKER", "inactive player cannot attack")
	var duplicate: Dictionary = Combat.create([["255"],["16"]], [
		Combat.unit("A", "421", 0, 0),
		Combat.unit("B", "407", 0, 0)])
	check(duplicate["error"] == "OCCUPIED_SLOT", "same-seat same-field duplicate slot blocked")
	var duplicate_uid: Dictionary = Combat.create([["255"],["16"]], [
		Combat.unit("A", "421", 0, 0),
		Combat.unit("A", "273", 1, 0)])
	check(duplicate_uid["error"] == "INVALID_UNIT_ID_OR_FAMILY", "immutable duplicate runtime UID rejected")
