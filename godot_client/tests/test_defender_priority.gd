extends SceneTree
const Match=preload("res://scripts/match_integrator.gd")
const Core=preload("res://scripts/real_combat_core.gd")
const Storage=preload("res://scripts/match_storage.gd")
var passed:int=0
var failed:int=0
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:
		failed+=1
		printerr("FAIL: "+label)
func fixture()->Dictionary:
	var s:Dictionary=Match.create(2605)["state"]
	s["setup_complete"]=true
	for p in s["players"]:
		p["setup_ready"]=true
		p["sinew"]=5
	s["phase"]=4
	s["units"]=[
		Core.unit("ACTOR","421",0,0,"Warfield"),
		Core.unit("DEFENDER","421",1,0,"Warfield"),
		Core.unit("ALLY-SUPPORT","423",0,1,"Warfield"),
		Core.unit("FOE-SUPPORT","423",1,1,"Warfield")]
	return s
func request(s:Dictionary,seat:int,kind:String,args:Dictionary={})->Dictionary:
	var cmd:Dictionary={"type":kind,"seat":seat,"revision":int(s["revision"])}
	for key in args:cmd[key]=args[key]
	return Match.apply(s,cmd)
func declaration()->Dictionary:
	return {"attacker":"ACTOR","defender":"DEFENDER","axis":"Stone","attacker_spend":0}
func _initialize()->void:
	run()
	print("KUDURRU_M17_DEFENDER_PRIORITY passed=%d failed=%d" % [passed,failed])
	quit(0 if failed==0 else 1)
func run()->void:
	var s:Dictionary=fixture()
	var old:String=JSON.stringify(s)
	var plain:Dictionary=request(s,0,"ATTACK",{
		"attacker":"ACTOR","defender":"DEFENDER","axis":"Stone","defender_spend":2})
	check(plain["error"]=="DEFENDER_OWNED_COMBAT_REQUIRED","legacy direct attack cannot steal opponent spend")
	var spoof:Dictionary=declaration()
	spoof["defender_spend"]=2
	check(request(s,0,"DECLARE_ATTACK",spoof)["error"]=="DEFENDER_RESOURCE_CONTROL_FORBIDDEN","attacker cannot choose defender resource spend")
	spoof=declaration()
	spoof["defender_supporter"]="FOE-SUPPORT"
	check(request(s,0,"DECLARE_ATTACK",spoof)["error"]=="DEFENDER_RESOURCE_CONTROL_FORBIDDEN","attacker cannot choose defender supporter")
	check(request(s,0,"CHOOSE_DEFENSE")["error"]=="NO_PENDING_ATTACK","cannot defend nonexistent engagement")
	check(JSON.stringify(s)==old,"invalid commands preserve source state")
	var step:Dictionary=request(s,0,"DECLARE_ATTACK",declaration())
	check(step["ok"],"attacker can legally declare combat: "+str(step))
	if not step["ok"]:return
	var pending:Dictionary=step["state"]
	check(not pending["pending_attack"].is_empty(),"declared attack awaits defender choice")
	check(int(pending["pending_attack"]["defender_seat"])==1,"only defender owns response")
	check(int(pending["players"][1]["sinew"])==5,"no premature defender resource spend")
	check(int(pending["players"][0]["sinew"])==5,"no premature attacker resource spend")
	check(pending["units"][0]["exhausted"]==false,"attack has not resolved yet")
	check(pending["revision"]==s["revision"]+1,"declaration separately logged")
	check(request(pending,0,"ADVANCE")["error"]=="DEFENDER_RESPONSE_REQUIRED","cannot advance while defending")
	check(request(pending,0,"CHOOSE_DEFENSE")["error"]=="NOT_DEFENDER_RESPONSE_OWNER","attacker cannot answer opponent decision")
	check(request(pending,1,"DECLARE_ATTACK",declaration())["error"]=="DEFENDER_RESPONSE_REQUIRED","cannot declare nested attack")
	check(request(pending,1,"CHOOSE_DEFENSE",{"defender_spend":3})["error"]=="DEFENSE_SPEND_0_TO_2","max defender two resource spend")
	check(request(pending,1,"CHOOSE_DEFENSE",{"defender_spend":-1})["error"]=="DEFENSE_SPEND_0_TO_2","negative defender spend rejected")
	check(request(pending,1,"CHOOSE_DEFENSE",{"defender_spend":1.5})["error"]=="DEFENSE_RESOURCE_TYPE_INVALID","floating spending rejected")
	check(request(pending,1,"CHOOSE_DEFENSE",{"defender_supporter":42})["error"]=="DEFENSE_SUPPORTER_TYPE_INVALID","invalid supporter type rejected")
	check(JSON.stringify(pending)==JSON.stringify(step["state"]),"invalid defense does not mutate caller")
	var result:Dictionary=request(pending,1,"CHOOSE_DEFENSE",{"defender_spend":2})
	check(result["ok"],"defender can authorize own two Sinew")
	if not result["ok"]:return
	var final:Dictionary=result["state"]
	check(final["pending_attack"].is_empty(),"combat response window closed")
	check(int(final["players"][1]["sinew"])==3,"defender own two Sinew deducted")
	check(int(final["players"][0]["sinew"])==5,"attacker resources unchanged by defender decision")
	check(final["units"][0]["exhausted"],"attack actually resolved after response")
	check(final["revision"]==s["revision"]+2,"separate attack and defense revisions")
	check(final["events"][-2]["type"]=="COMBAT_DECLARED","declaration in public journal")
	check(final["events"][-1]["type"]=="COMBAT","final resolution journaled")
	check(final["action_log"][-2]["type"]=="DECLARE_ATTACK","replay commits real attacker action")
	check(final["action_log"][-1]["type"]=="CHOOSE_DEFENSE","replay commits real defender action")
	check(final["action_log"][-1]["seat"]==1,"journal proves responding seat owns spend")
	check(request(final,1,"CHOOSE_DEFENSE")["error"]=="NO_PENDING_ATTACK","cannot double-spend after defense")
	check(Match.next_action(pending,1)["type"]=="CHOOSE_DEFENSE","defender AI can answer out of turn")
	check(Match.next_action(pending,0).is_empty(),"attacker AI cannot answer for target")
	check(JSON.stringify(s)==old,"valid combat does not mutate original caller")
	var spoof_support:Dictionary=request(pending,1,"CHOOSE_DEFENSE",{"defender_supporter":"ACTOR"})
	check(not spoof_support["ok"],"defender cannot conscript opponent supporter")
	var valid_support:Dictionary=request(pending,1,"CHOOSE_DEFENSE",{"defender_supporter":"FOE-SUPPORT"})
	check(valid_support["ok"],"defender may commit own eligible adjacent supporter")
	if valid_support["ok"]:
		check(valid_support["state"]["units"][3]["exhausted"],"defender supporter exhausts")
		check(valid_support["state"]["players"][1]["heat"]==0,"supporter heat relief bounded at zero")
	var attacker_support:Dictionary=declaration()
	attacker_support["attacker_supporter"]="ALLY-SUPPORT"
	attacker_support["attacker_spend"]=1
	step=request(s,0,"DECLARE_ATTACK",attacker_support)
	check(step["ok"],"attacker may commit own single supporter and resource")
	if step["ok"]:
		result=request(step["state"],1,"CHOOSE_DEFENSE")
		check(result["ok"],"zero spend defense still legal")
		if result["ok"]:
			check(result["state"]["units"][2]["exhausted"],"attacker supporter exhausted at resolution")
			check(result["state"]["players"][0]["sinew"]==4,"attacker resource commitment paid exactly once")
	# Source-run 36-card replay and conservation remain checked by
	# test_full_match_replay.gd; these isolated fixtures include test units.
