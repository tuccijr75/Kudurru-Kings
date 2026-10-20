extends SceneTree
const Match = preload("res://scripts/match_integrator.gd")
const Source = preload("res://scripts/real_effects.gd")
var checks := 0
var fail := 0
func test(ok: bool, label: String) -> void:
	if ok: checks += 1
	else:
		fail += 1
		printerr("FAIL: " + label)
func act(s: Dictionary, kind: String, args: Dictionary = {}) -> Dictionary:
	var a: Dictionary = {"seat":s["seat"],"revision":s["revision"],"type":kind}
	for k in args: a[k] = args[k]
	return Match.apply(s,a)
func _initialize() -> void:
	run()
	print("KUDURRU_M7_INTEGRATED_MATCH passed=%d failed=%d" % [checks,fail])
	quit(0 if fail==0 else 1)
func run() -> void:
	var start: Dictionary = Match.create(20261020)
	test(start["ok"], "real match candidate setup")
	if not start["ok"]: return
	var state: Dictionary = start["state"]
	test(state["scenario"] == Match.SCENARIO, "explicit objective candidate")
	test(not state["release_certified"] and not state["reward_enabled"], "no fake production certification")
	for seat in range(2):
		test(state["players"][seat]["hand"].size() == 6, "opening six seat "+str(seat))
		test(state["players"][seat]["deck"].size() == 30, "remaining thirty")
		test(state["players"][seat]["sinew"] == 2, "starting Sinew 2")
		test(state["players"][seat]["sigil"] == 1, "starting Sigil 1")
		var ids: Array = Match._deck(state["players"][seat]["faction"])
		test(ids.size() == 36, "36 real card candidate deck")
		test(ids.all(func(c):return str(c["card_id"]).is_valid_int()), "no synthetic ids")
	var before: String = JSON.stringify(state)
	test(act(state,"ADVANCE")["error"]=="PREGAME_DECISION_REQUIRED", "no advance before setup decisions")
	test(JSON.stringify(state) == before, "rejected action immutable")
	for i in range(2):
		var result: Dictionary = Match.apply(state,{"seat":i,"revision":state["revision"],"type":"KEEP"})
		test(result["ok"],"legal pregame keep")
		state = result["state"]
	test(state["setup_complete"],"both players begin play")
	var repeat: Dictionary = act(state,"KEEP")
	test(repeat["error"] != "", "setup retry rejected")
	for i in range(3):
		var result: Dictionary = act(state,"ADVANCE")
		test(result["ok"],"advance to Main")
		state = result["state"]
	test(state["phase"] == 3,"seven phases retained")
	var deployed: int = 0
	var guard := 0
	while guard < 8:
		guard += 1
		var decision: Dictionary = Match.next_action(state,0)
		if decision.get("type") != "DEPLOY": break
		var result: Dictionary = Match.apply(state,decision)
		test(result["ok"],"deploy real source card")
		if not result["ok"]: break
		deployed += 1
		state = result["state"]
	test(deployed>0,"opened by at least one affordable real card")
	test(state["units"].size()>0,"actual units deployed on field")
	test(Match._control(state)==0,"uncontested Warfield is controlled")
	var to_resolution := 0
	while state["phase"] != 5 and to_resolution < 7:
		state = act(state,"ADVANCE")["state"]
		to_resolution += 1
	test(state["phase"] == 5,"Resolution reached")
	var old_marks: int = state["players"][0]["marks"]
	state = act(state,"ADVANCE")["state"]
	test(state["players"][0]["marks"] == old_marks+1,"Scenario rewards 1 Mark at Resolution")
	test(state["phase"] == 6,"End after Resolution")
	var seat0: int = state["seat"]
	state = act(state,"ADVANCE")["state"]
	test(state["seat"] != seat0 and state["phase"] == 0,"End closes to opponent")
	var remaining: int = 0
	var finished: bool = false
	for seed in range(1,21):
		var ms: Dictionary = Match.create(seed)["state"]
		for seat in range(2):
			ms = Match.apply(ms,{"seat":seat,"revision":ms["revision"],"type":"KEEP"})["state"]
		var steps: int = 0
		while int(ms["winner"]) < 0 and steps < 300:
			var acting: int = int(ms["seat"])
			if not ms.get("priority_queue",[]).is_empty():
				acting=int(ms["priority_queue"][0]["seat"])
			if not ms.get("pending_attack",{}).is_empty():
				acting=int(ms["pending_attack"]["defender_seat"])
			var action: Dictionary = Match.next_action(ms,acting)
			var outcome: Dictionary = Match.apply(ms,action)
			if not outcome["ok"]:
				printerr("M7 SIM FAIL seed=",seed," step=",steps," action=",action," result=",outcome)
				fail += 1
				break
			ms = outcome["state"]
			steps += 1
		test(int(ms["winner"]) >= 0,"seed "+str(seed)+" finishes to 10 Marks")
		test(steps < 300,"seed "+str(seed)+" no infinite ms")
		test(ms["players"][int(ms["winner"])]["marks"] >= 10 if int(ms["winner"])>=0 else false,"legitimate victory threshold")
		test(ms["units"].size()<=72,"no unit explosion")
		for p in ms["players"]:
			var total: int = p["hand"].size() + p["deck"].size() + p["discard"].size()
			for u in ms["units"]:
				if u["owner"]==p["seat"]: total+=1
			for site in ms["sites"]:
				if site["controller"]==p["seat"]: total+=1
			for attachment in ms["attachments"]:
				if attachment["controller"]==p["seat"]: total+=1
			test(total==36,"36-card conservation seed "+str(seed)+" seat "+str(p["seat"]))
