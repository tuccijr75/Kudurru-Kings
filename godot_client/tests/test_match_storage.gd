extends SceneTree
const Match = preload("res://scripts/match_integrator.gd")
const Store = preload("res://scripts/match_storage.gd")
const TEST_SLOT := "user://kudurru/tests/m8_integration.json"
var passed: int = 0
var failed: int = 0

func check(ok: bool,label: String) -> void:
	if ok: passed+=1
	else:
		failed+=1
		printerr("FAIL: "+label)

func _initialize() -> void:
	_run()
	print("KUDURRU_M8_SAVE_REPLAY passed=%d failed=%d" % [passed,failed])
	quit(0 if failed==0 else 1)

func _run() -> void:
	var made: Dictionary = Match.create(19001)
	check(made.get("ok",false),"candidate match setup")
	if not made.get("ok",false): return
	var state: Dictionary = made["state"]
	check(state["action_log"].is_empty(),"fresh log empty")
	var p: Dictionary = Store.pack(state)
	check(p.get("ok",false),"fresh match can pack")
	if not p.get("ok",false): return
	check(Store.unpack(p["serialized"])["ok"],"fresh match can unpack")
	for seat in range(2):
		var response: Dictionary = Match.apply(state,{
			"type":"KEEP","seat":seat,"revision":state["revision"]})
		check(response.get("ok",false),"pregame keep")
		state=response["state"]
	for i in range(3):
		var response: Dictionary = Match.apply(state,{
			"type":"ADVANCE","seat":state["seat"],"revision":state["revision"]})
		check(response.get("ok",false),"legal seven-phase progression")
		state=response["state"]
	var deploying: Dictionary = Match.next_action(state,0)
	check(deploying.get("type")=="DEPLOY","legal source card deployment available")
	var outcome: Dictionary = Match.apply(state,deploying)
	check(outcome.get("ok",false),"real deployment stored")
	state=outcome["state"]
	check(state["revision"]==state["action_log"].size(),"one action per committed revision")
	check(Store.replay(state)["ok"],"exact deterministic source replay")
	p=Store.pack(state)
	check(p["ok"],"nonempty match packs")
	var recovered: Dictionary = Store.unpack(p["serialized"])
	check(recovered["ok"],"save payload round trips with replay validation")
	if recovered["ok"]:
		check(recovered["state"]["revision"]==state["revision"],"revision restored")
		check(recovered["state"]["units"].size()==state["units"].size(),"real deployed unit preserved")
		check(recovered["state"]["players"][0]["hand"].size()==state["players"][0]["hand"].size(),"hand count conserved")
	var target: Dictionary = Store.save(state,TEST_SLOT)
	check(target.get("ok",false),"atomic slot write")
	var loaded: Dictionary = Store.load(TEST_SLOT)
	check(loaded.get("ok",false),"load from physical user save")
	if loaded.get("ok",false): check(Store.replay(loaded["state"])["ok"],"loaded game independently replays")
	target=Store.save(state,TEST_SLOT)
	check(target.get("ok",false),"existing slot backup and replace")
	check(FileAccess.file_exists(TEST_SLOT+".bak"),"previous save backup created")
	var tampered: Dictionary = JSON.parse_string(p["serialized"])
	tampered["payload_sha256"]="00000000"
	check(Store.unpack(JSON.stringify(tampered))["error"]=="SAVE_CHECKSUM_MISMATCH","hash mismatch rejected")
	tampered=JSON.parse_string(p["serialized"])
	tampered["catalog_sha256"]="00000000"
	check(Store.unpack(JSON.stringify(tampered))["error"]=="CANONICAL_CARD_DATA_CHANGED","stale canon source refused")
	tampered=JSON.parse_string(p["serialized"])
	var malicious: Dictionary = JSON.parse_string(tampered["payload"])
	malicious["players"][0]["marks"]=30
	tampered["payload"]=JSON.stringify(malicious)
	tampered["payload_sha256"]=str(tampered["payload"]).sha256_text()
	check(Store.unpack(JSON.stringify(tampered))["error"]=="REPLAY_STATE_DIVERGENCE","re-signed forged state rejected through event replay")
	var wrong_mode: Dictionary=state.duplicate(true)
	wrong_mode["release_certified"]=true
	check(Store.pack(wrong_mode)["error"]=="RELEASE_OR_REWARD_TAMPER","cannot promote preview to production via save")
	var wrong_log: Dictionary=state.duplicate(true)
	wrong_log["action_log"].pop_back()
	check(Store.pack(wrong_log)["error"]=="MISSING_OR_OVERSIZED_ACTION_LOG","missing action history refused")
	check(Store.load("user://outside/slot.json")["error"]=="OUTSIDE_ALLOWED_SAVE_FOLDER","path sandbox enforced")
	var after: Dictionary = state.duplicate(true)
	var action: Dictionary = {"type":"ADVANCE","seat":0,"revision":after["revision"]}
	var continued: Dictionary = Match.apply(after,action)
	check(continued.get("ok",false),"saved match can continue turn progression")
	if continued.get("ok",false):
		check(Store.replay(continued["state"])["ok"],"determinism preserved after additional action")
	_malformed_saves(state)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SLOT))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SLOT+".bak"))

func _reject_state(state: Dictionary, label: String) -> void:
	var before := JSON.stringify(state)
	check(not Store.replay(state).get("ok",false),label+" replay rejects")
	check(not Store.pack(state).get("ok",false),label+" pack rejects")
	var wrapper: Dictionary = JSON.parse_string(Store.pack(Match.create(19001)["state"])["serialized"])
	wrapper["payload"]=JSON.stringify(state)
	wrapper["payload_sha256"]=wrapper["payload"].sha256_text()
	check(not Store.unpack(JSON.stringify(wrapper)).get("ok",false),label+" resealed JSON rejects")
	check(JSON.stringify(state)==before,label+" input preserved")

func _malformed_saves(state: Dictionary) -> void:
	for key in ["players","action_log","events","initial_deck_ids","units","sites","attachments"]:
		for bad in [null,42,"bad",{}]:
			var broken := state.duplicate(true)
			broken[key]=bad
			_reject_state(broken,"malformed "+key+" "+str(bad))
	for key in ["seed","phase","revision","round","seat","winner"]:
		for bad in [0.5,true,"0",9007199254740992]:
			var broken := state.duplicate(true)
			broken[key]=bad
			_reject_state(broken,"nonintegral "+key+" "+str(bad))
	for key in ["release_certified","reward_enabled"]:
		for bad in [0,1,null,"false"]:
			var invalid := state.duplicate(true)
			invalid[key]=bad
			_reject_state(invalid,"invalid flag "+key)
	for value in [INF,-INF,NAN]:
		var invalid := state.duplicate(true)
		invalid["seed"]=value
		check(not Store.replay(invalid).get("ok",false),"nonfinite seed refused before conversion")
	for key in ["sinew","sigil","oath","marks","heat","seat","faction"]:
		var broken := state.duplicate(true)
		broken["players"][0][key]=0.5
		_reject_state(broken,"player "+key)
	var broken := state.duplicate(true)
	broken["players"][0]=null
	_reject_state(broken,"null player")
	for zone in ["units","sites","attachments"]:
		broken=state.duplicate(true)
		broken[zone]=[null]
		_reject_state(broken,"null zone entry "+zone)
		broken=state.duplicate(true)
		broken[zone]=[{"owner":0.5,"controller":0.5}]
		_reject_state(broken,"fractional zone owner "+zone)
	broken=state.duplicate(true)
	broken["initial_deck_ids"]=[[null],[]]
	_reject_state(broken,"malformed initial card ID")
	for path in ["user://kudurru/../../outside.json","user://kudurru/../outside.json"]:
		check(Store.load(path).get("error")=="OUTSIDE_ALLOWED_SAVE_FOLDER","traversal load rejected")
		check(Store.save(state,path).get("error")=="OUTSIDE_ALLOWED_SAVE_FOLDER","traversal write rejected")
	check(Store.replay(state).get("ok",false),"valid state still replays after malformed inputs")
