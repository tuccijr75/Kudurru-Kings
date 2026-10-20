extends SceneTree
const Match=preload("res://scripts/match_integrator.gd")
const Source=preload("res://scripts/real_effects.gd")
const Priority=preload("res://scripts/match_priority.gd")
const Combat=preload("res://scripts/real_combat_core.gd")
var passed:int=0
var failed:int=0
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:
		failed+=1
		printerr("FAIL: "+label)
func fixture(id:String,enemy_heat:int)->Dictionary:
	var s:Dictionary=Match.create(303)["state"]
	s["setup_complete"]=true
	for p in s["players"]:p["setup_ready"]=true
	s["phase"]=2
	s["players"][0]["sigil"]=10
	s["players"][0]["oath"]=10
	s["players"][1]["heat"]=enemy_heat
	var p:Dictionary=s["players"][0]
	var found:bool=false
	for c in p["hand"]:
		if str(c["card_id"])==id:found=true
	if not found:
		for i in range(p["deck"].size()):
			if str(p["deck"][i]["card_id"])==id:
				p["hand"].append(p["deck"].pop_at(i))
				break
	return s
func cast(s:Dictionary,id:String,extras:Dictionary={})->Dictionary:
	var cmd:Dictionary={"seat":0,"revision":s["revision"],"type":"CAST","card_id":id}
	for k in extras:cmd[k]=extras[k]
	return Match.apply(s,cmd)
func respond(s:Dictionary,seat:int,choice:String,extras:Dictionary={})->Dictionary:
	var cmd:Dictionary={"seat":seat,"revision":s["revision"],"type":"CHOOSE_CONSEQUENCE","choice":choice}
	for k in extras:cmd[k]=extras[k]
	return Match.apply(s,cmd)
func _initialize()->void:
	_run()
	print("KUDURRU_M12_PRIORITY_CHOICES passed=%d failed=%d" % [passed,failed])
	quit(0 if failed==0 else 1)
func _run()->void:
	for id in ["182","190"]:
		check(Priority.verified(id),"exact source text certified "+id)
		check(Match.EDICTS.has(id),"Edict included in real 36-card candidate "+id)
	var s:Dictionary=fixture("182",4)
	s["players"][1]["oath"]=4
	s["units"]=[Combat.unit("VICTIM","421",1,0,"Warfield")]
	var original:String=JSON.stringify(s)
	var result:Dictionary=cast(s,"182")
	check(result["ok"],"Public Reckoning casts in Edicts against Heat 4")
	if not result["ok"]:return
	var pending:Dictionary=result["state"]
	check(pending["priority_queue"].size()==1,"opponent-choice prompt created")
	check(pending["priority_queue"][0]["seat"]==1,"opponent must respond, not caster")
	check(pending["priority_queue"][0]["options"].has("DISCARD_CARD"),"discard option present")
	check(pending["priority_queue"][0]["options"].has("EXHAUST_UNIT"),"exhaust option present")
	check(pending["priority_queue"][0]["options"].has("LOSE_OATH"),"Oath option present")
	check(pending["seat"]==0,"active turn remains owner during response")
	check(pending["players"][0]["discard"][-1]["card_id"]=="182","real Edict spent once")
	check(JSON.stringify(s)==original,"original state immutable")
	check(Match.apply(pending,{"seat":0,"revision":pending["revision"],"type":"ADVANCE"})["error"]=="RESPONSE_CHOICE_REQUIRED","cannot advance before victim responds")
	check(respond(pending,0,"LOSE_OATH")["error"]=="NOT_CHOICE_OWNER","caster cannot choose opponent loss")
	check(respond(pending,1,"INVENTED_CHOICE")["error"]=="UNAVAILABLE_CHOICE","invented choice blocked")
	var paid:Dictionary=respond(pending,1,"LOSE_OATH")
	check(paid["ok"],"responding opponent may lose 2 Oath")
	if paid["ok"]:
		check(paid["state"]["players"][1]["oath"]==2,"exact Oath loss")
		check(paid["state"]["priority_queue"].is_empty(),"priority window closes")
		check(paid["state"]["revision"]==pending["revision"]+1,"choice separately logged")
		check(paid["event"]["choice"]=="LOSE_OATH","canonical action event")
		check(paid["state"]["seat"]==0,"owner's turn resumes")
		check(respond(paid["state"],1,"LOSE_OATH")["error"]=="NO_PENDING_PRIORITY_CHOICE","can't reply twice")
	var discarded:Dictionary=respond(pending,1,"DISCARD_CARD",{"hand_index":0})
	check(discarded["ok"],"opponent may choose one hand card to discard")
	if discarded["ok"]:
		check(discarded["state"]["players"][1]["hand"].size()==pending["players"][1]["hand"].size()-1,"one real hand card removed")
		check(discarded["state"]["players"][1]["discard"].size()==pending["players"][1]["discard"].size()+1,"selected card enters discard")
		check(discarded["event"].has("discarded_card_id"),"selected discard visible as public result")
	check(respond(pending,1,"DISCARD_CARD",{"hand_index":999})["error"]=="INVALID_CHOSEN_CARD","arbitrary index rejected")
	var exhausted:Dictionary=respond(pending,1,"EXHAUST_UNIT",{"unit_uid":"VICTIM"})
	check(exhausted["ok"],"opponent can exhaust selected ready unit")
	if exhausted["ok"]:
		check(exhausted["state"]["units"][0]["exhausted"],"specified unit actually exhausted")
	check(respond(pending,1,"EXHAUST_UNIT",{"unit_uid":"NONE"})["error"]=="FRIENDLY_UNIT_REQUIRED","phantom target refused")
	var low:Dictionary=fixture("182",2)
	var nothing:Dictionary=cast(low,"182")
	check(nothing["ok"] and nothing["state"]["priority_queue"].is_empty(),"no opponent Heat 4 means no forced response")
	s=fixture("190",3)
	s["units"]=[Combat.unit("AUDIT_TARGET","421",1,0,"Warfield")]
	result=cast(s,"190",{"target_seat":1})
	check(result["ok"],"Censor Audit chooses Heat >=3 player")
	if not result["ok"]:return
	pending=result["state"]
	check(pending["priority_queue"].size()==1,"Censor Audit creates target choice")
	check(pending["priority_queue"][0]["options"].has("SILENCE_UNIT"),"Silence choice present")
	check(not pending["priority_queue"][0]["options"].has("DISCARD_NAME"),"can't discard absent Name")
	var silenced:Dictionary=respond(pending,1,"SILENCE_UNIT",{"unit_uid":"AUDIT_TARGET"})
	check(silenced["ok"],"victim chooses unit for Silence")
	if silenced["ok"]:
		check(silenced["state"]["units"][0]["silenced"],"Silence actually placed")
	check(respond(pending,1,"DISCARD_NAME",{"hand_index":0})["error"]=="UNAVAILABLE_CHOICE","cannot discard absent Name")
	check(cast(s,"190",{"target_seat":999})["error"]=="INVALID_AUDIT_TARGET","invalid seat rejected")
	check(cast(fixture("190",2),"190",{"target_seat":1})["error"]=="AUDIT_HEAT_BELOW_THREE","Heat threshold enforced")
	var no_options:Dictionary=fixture("190",4)
	no_options["players"][1]["hand"]=[]
	no_options["units"]=[]
	check(cast(no_options,"190",{"target_seat":1})["error"]=="AUDIT_NO_LEGAL_CONSEQUENCE","cannot force impossible target")
	var name_state:Dictionary=fixture("190",4)
	var name_card:Dictionary=Source.find_card(Source.catalog(),"198")
	name_state["players"][1]["hand"].append(name_card)
	result=cast(name_state,"190",{"target_seat":1})
	check(result["ok"],"future Name-bearing deck supports Name discard choice")
	if result["ok"]:
		var idx:int=result["state"]["players"][1]["hand"].size()-1
		var name_drop:Dictionary=respond(result["state"],1,"DISCARD_NAME",{"hand_index":idx})
		check(name_drop["ok"],"Name discard response actually resolves")
		if name_drop["ok"]:
			check(name_drop["state"]["players"][1]["discard"][-1]["card_id"]=="198","real source Name correctly discarded")
		check(respond(result["state"],1,"DISCARD_NAME",{"hand_index":0})["error"]=="NAME_CARD_REQUIRED","cannot substitute Character for Name")
	check(Priority.deterministic_response(pending,1).get("type","")=="CHOOSE_CONSEQUENCE","AI selects legitimate response")
	check(Priority.deterministic_response(pending,0).is_empty(),"AI cannot choose for human")
