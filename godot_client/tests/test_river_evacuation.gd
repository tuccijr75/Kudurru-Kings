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
	# Real action-log save replay is exercised via full-match seeded tests.
	# Fixture supplies units without logged deployment and cannot be saved.
	check(out["revision"]==1 and out["action_log"].size()==1,"atomic revision and source action")
