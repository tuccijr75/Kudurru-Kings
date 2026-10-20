extends SceneTree
const Match=preload("res://scripts/match_integrator.gd")
const Combat=preload("res://scripts/real_combat_core.gd")
const Edicts=preload("res://scripts/match_edicts.gd")
const Storage=preload("res://scripts/match_storage.gd")
var passed:int=0
var failed:int=0
func check(condition:bool,label:String)->void:
	if condition:passed+=1
	else:
		failed+=1
		printerr("FAIL: "+label)
func fixture()->Dictionary:
	var s:Dictionary=Match.create(4727)["state"]
	s["setup_complete"]=true
	for player in s["players"]:player["setup_ready"]=true
	s["phase"]=2
	s["players"][0]["sigil"]=3
	var p:Dictionary=s["players"][0]
	var present:bool=false
	for c in p["hand"]:
		if c["card_id"]=="186":present=true
	if not present:
		for i in range(p["deck"].size()):
			if p["deck"][i]["card_id"]=="186":
				p["hand"].append(p["deck"].pop_at(i))
				break
	s["units"]=[
		Combat.unit("ALLY","421",0,0,"Warfield"),
		Combat.unit("FOE","422",1,0,"Warfield"),
		Combat.unit("OTHER","423",1,1,"Sanctuary")]
	return s
func cast(s:Dictionary,ids:Array,dest:String)->Dictionary:
	return Match.apply(s,{"type":"CAST","seat":0,"revision":s["revision"],
		"card_id":"186","target_uids":ids,"destination_field":dest})
func _initialize()->void:
	run()
	print("KUDURRU_M16_RIVER_EVACUATION passed=%d failed=%d" % [passed,failed])
	quit(0 if failed==0 else 1)
func run()->void:
	check(Edicts.verified("186"),"River Evacuation exact printed source hash")
	check(Match.EDICTS.has("186"),"source verified Edict placed in real candidate")
	var s:Dictionary=fixture()
	var initial:String=JSON.stringify(s)
	check(not cast(s,[],"Sanctuary")["ok"],"zero selected units refused")
	check(cast(s,["ALLY","FOE","OTHER"],"Sanctuary")["error"]=="DISPLACE_ONE_OR_TWO_UNITS","three targets refused")
	check(cast(s,["ALLY","ALLY"],"Sanctuary")["error"]=="INVALID_OR_DUPLICATE_DISPLACEMENT_TARGET","same UID twice refused")
	check(cast(s,["ALLY","NONE"],"Sanctuary")["error"]=="INVALID_OR_DUPLICATE_DISPLACEMENT_TARGET","unknown target refused")
	check(cast(s,["ALLY","OTHER"],"Sanctuary")["error"]=="SAME_ORIGIN_FIELD_REQUIRED","different source Fields refused")
	check(cast(s,["ALLY"],"Warfield")["error"]=="DISPLACEMENT_MUST_CHANGE_FIELD","no-op field refused")
	check(cast(s,["ALLY"],"Wilds")["error"]=="DESTINATION_ACTIVE_FIELD_REQUIRED","unloaded field refused")
	var defeated:Dictionary=s.duplicate(true)
	defeated["units"][0]["defeated"]=true
	check(cast(defeated,["ALLY"],"Sanctuary")["error"]=="DEFEATED_UNIT_CANNOT_BE_TARGETED","defeated target prohibited by rules")
	check(JSON.stringify(s)==initial,"invalid casts do not modify caller state")
	var result:Dictionary=cast(s,["ALLY","FOE"],"Sanctuary")
	check(result["ok"],"two real enemy and ally units displaced by Edict")
	if not result["ok"]:return
	var out:Dictionary=result["state"]
	check(out["units"][0]["field"]=="Sanctuary","ally moved to Sanctuary")
	check(out["units"][1]["field"]=="Sanctuary","enemy moved to Sanctuary")
	check(out["units"][2]["field"]=="Sanctuary","other existing Sanctuary unit not displaced")
	check(int(out["units"][1]["slot"])!=int(out["units"][2]["slot"]),"enemy destination slot uniqueness")
	check(out["players"][0]["sigil"]==2,"actual original 1 Sigil cost paid")
	check(out["players"][0]["discard"][-1]["card_id"]=="186","source Edict spent once")
	check(out["events"][-1]["type"]=="EDICT","real reducer logged action")
	check(out["events"][-1]["resolved"]["displaced"].size()==2,"source 1-2 target identities journaled")
	check(out["events"][-1]["resolved"]["line_geas_resolution"]=="NOT_IMPLEMENTED_IN_CANDIDATE",
		"jurisdiction gaps not fabricated")
	check(JSON.stringify(s)==initial,"valid cast changes duplicate only")
	var other:Dictionary=fixture()
	other["units"][0]["downed"]=true
	result=cast(other,["ALLY"],"Sanctuary")
	check(result["ok"] and result["state"]["units"][0]["downed"],"Downed unit remains targetable and Downed after movement")
	check(int(result["state"]["units"][0]["slot"])==0,"valid destination slot starts at zero")
	var from_sanctuary:Dictionary=fixture()
	result=cast(from_sanctuary,["OTHER"],"Warfield")
	check(result["ok"] and result["state"]["units"][2]["field"]=="Warfield","can move from Sanctuary back to Warfield")
	check(result["state"]["units"][2]["slot"]==1,"destination collision resolved deterministically")
	var empty:Dictionary=fixture()
	empty["units"].clear()
	check(cast(empty,["ALLY"],"Sanctuary")["error"]=="INVALID_OR_DUPLICATE_DISPLACEMENT_TARGET","empty board target rejected")
	var no_money:Dictionary=fixture()
	no_money["players"][0]["sigil"]=0
	check(not cast(no_money,["ALLY"],"Sanctuary")["ok"],"cannot cast without printed Sigil cost")
	var bad_phase:Dictionary=fixture()
	bad_phase["phase"]=3
	check(cast(bad_phase,["ALLY"],"Sanctuary")["error"]=="EDICTS_WINDOW_REQUIRED","not playable during Main")
	_halo_guard()
	# Real action-log save replay is exercised via full-match seeded tests.
	# Fixture supplies units without logged deployment and cannot be saved.
	check(out["revision"]==1 and out["action_log"].size()==1,"atomic revision and source action")

# A source-legal arranged deck gives a reproducible regression, not an injected
# board: every deploy and phase is logged and independently replayable.
static func halo_fixture() -> Dictionary:
	var seed_value:int=9921
	var initial:Dictionary=Match.create(seed_value)
	var decks:Array=initial["state"]["initial_deck_ids"].duplicate(true)
	var cheap:String=""
	for card in initial["state"]["players"][0]["hand"]+initial["state"]["players"][0]["deck"]:
		if card["card_family"]=="Character" and int(card["cost_sinew"])==1 and int(card["cost_sigil"])==0 and int(card["cost_oath"])==0:
			cheap=str(card["card_id"]);break
	assert(not cheap.is_empty())
	for seat in range(2):
		var wanted:Array=[cheap,"241","186"] if seat==0 else ["186"]
		var remaining:Array=decks[seat].duplicate()
		var ordered:Array=[]
		ordered.resize(36)
		var positions:Array=Match._shuffle(range(36),seed_value+seat*7919)
		for i in range(wanted.size()):
			assert(remaining.has(wanted[i]))
			remaining.erase(wanted[i])
			ordered[positions[35-i]]=wanted[i]
		for i in range(36):
			if ordered[i]==null:ordered[i]=remaining.pop_front()
		decks[seat]=ordered
	var created:Dictionary=Match.create(seed_value,"BorderstoneGuild","UnderwellKeepers",decks)
	assert(created["ok"])
	var state:Dictionary=created["state"]
	var actions:Array=[{"type":"KEEP","seat":0},{"type":"KEEP","seat":1}]
	for i in range(3):actions.append({"type":"ADVANCE","seat":0})
	actions.append({"type":"DEPLOY","seat":0,"card_id":cheap,"field":"Warfield"})
	actions.append({"type":"DEPLOY","seat":0,"card_id":"241","host_uid":"REAL_1"})
	for i in range(4):actions.append({"type":"ADVANCE","seat":0})
	for i in range(2):actions.append({"type":"ADVANCE","seat":1})
	for action in actions:
		action["revision"]=state["revision"]
		var response:Dictionary=Match.apply(state,action)
		assert(response["ok"],str(response))
		state=response["state"]
	return state

func _halo_guard() -> void:
	var s:Dictionary=halo_fixture()
	check(Storage.replay(s).get("ok",false),"organic Halo Pup fixture independently replays")
	var before:String=JSON.stringify(s)
	var action:Dictionary={"type":"CAST","seat":1,"revision":s["revision"],"card_id":"186","target_uids":["REAL_1"],"destination_field":"Sanctuary"}
	var invalid:Dictionary=action.duplicate(true)
	invalid["destination_field"]="Wilds"
	check(not Match.apply(s,invalid)["ok"],"invalid displacement refused before guard consumes")
	check(JSON.stringify(s)==before,"invalid attempt preserves guard and resources")
	var out:Dictionary=Match.apply(s,action)
	check(out["ok"],"real hostile River Evacuation resolves")
	if not out["ok"]:return
	var next:Dictionary=out["state"]
	check(next["units"][0]["field"]=="Warfield","Halo Pup cancels Host displacement")
	check(next["attachments"][0]["guard_used_round"]==next["round"],"physical Pet's once per round guard spent")
	check(out["event"]["resolved"]["displaced"].is_empty(),"canceled Host not falsely journaled as moved")
	check(out["event"]["resolved"]["canceled_displacements"][0]["source_id"]=="241","exact source reaction journaled")
	check(next["players"][1]["sigil"]==s["players"][1]["sigil"]-1,"caster pays despite automatic cancellation")
	check(next["players"][0]==s["players"][0],"Pet owner resources and cards untouched")
	check(JSON.stringify(s)==before,"valid reaction only mutates reducer copy")
	check(Storage.pack(next).get("ok",false),"guard consumption has complete deterministic replay")
	var again:Dictionary=Edicts.resolve(next,1,"186",action)
	check(again["ok"] and again["state"]["units"][0]["field"]=="Sanctuary","spent guard does not cancel second same round displacement")
	var later:Dictionary=next.duplicate(true)
	later["round"]+=1
	again=Edicts.resolve(later,1,"186",action)
	check(again["state"]["units"][0]["field"]=="Warfield","new round guard available automatically")
	var wrong_owner:Dictionary=s.duplicate(true)
	wrong_owner["attachments"][0]["controller"]=1
	again=Edicts.resolve(wrong_owner,1,"186",action)
	check(again["state"]["units"][0]["field"]=="Sanctuary","opponent controlled Pet cannot protect host")
	var unrelated:Dictionary=s.duplicate(true)
	unrelated["attachments"][0]["host_uid"]="OTHER"
	again=Edicts.resolve(unrelated,1,"186",action)
	check(again["state"]["units"][0]["field"]=="Sanctuary","guard protects only its actual Host")

	for protected_uid in ["ALLY","FOE"]:
		var mixed:Dictionary=fixture()
		var owner:int=0 if protected_uid=="ALLY" else 1
		mixed["attachments"]=[{"card_id":"241","controller":owner,"host_uid":protected_uid}]
		var reacted:Dictionary=cast(mixed,["ALLY","FOE"],"Sanctuary")
		check(reacted["ok"],"mixed two-target cast remains legal")
		check(reacted["event"]["resolved"]["displaced"].size()==1,"only unprotected target moves")
		check(reacted["event"]["resolved"]["canceled_displacements"].size()==1,"one source reaction per protected Host")
		check(reacted["state"]["units"][owner]["field"]=="Warfield","correct protected host stays put regardless of cast target order")
		check(reacted["state"]["units"][1-owner]["field"]=="Sanctuary","other selected host still displaced")
