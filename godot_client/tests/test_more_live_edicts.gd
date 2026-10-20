extends SceneTree
const Match=preload("res://scripts/match_integrator.gd")
const Edicts=preload("res://scripts/match_edicts.gd")
const Combat=preload("res://scripts/real_combat_core.gd")
var passed:int=0
var failed:int=0
func check(v:bool,why:String)->void:
	if v:passed+=1
	else:
		failed+=1
		printerr("FAIL: "+why)
func fixture(id:String)->Dictionary:
	var s:Dictionary=Match.create(927)["state"]
	s["setup_complete"]=true
	for p in s["players"]:p["setup_ready"]=true
	s["phase"]=2
	s["players"][0]["sigil"]=8
	var hand:Array=s["players"][0]["hand"]
	for c in hand:
		if c["card_id"]==id:return s
	for i in range(s["players"][0]["deck"].size()):
		if s["players"][0]["deck"][i]["card_id"]==id:
			hand.append(s["players"][0]["deck"].pop_at(i))
			break
	return s
func cast(s:Dictionary,id:String,payload:Dictionary={})->Dictionary:
	var request:Dictionary={"type":"CAST","seat":0,"revision":s["revision"],"card_id":id}
	for k in payload:request[k]=payload[k]
	return Match.apply(s,request)
func _initialize()->void:
	_run()
	print("KUDURRU_M11_EDICT_TARGETING passed=%d failed=%d" % [passed,failed])
	quit(0 if failed==0 else 1)
func _run()->void:
	for id in ["184","185"]:
		check(Edicts.verified(id),"printed-source hash "+id)
		check(Match.EDICTS.has(id),"real source Edict in opening decks "+id)
	var downed:Dictionary=fixture("184")
	var a:Dictionary=Combat.unit("DOWNED","421",1,0,"Warfield")
	a["downed"]=true
	downed["units"]=[a]
	var old:String=JSON.stringify(downed)
	var denied:Dictionary=cast(downed,"184",{"target_uid":"MISSING"})
	check(not denied["ok"] and denied["error"]=="DOWNED_UNIT_REQUIRED","cannot seal non-existing")
	check(JSON.stringify(downed)==old,"invalid action does not mutate source")
	var result:Dictionary=cast(downed,"184",{"target_uid":"DOWNED"})
	check(result["ok"],"Condemnation Seal legal in Edicts")
	if result["ok"]:
		check(result["state"]["units"][0]["cannot_rescue_round"]==1,"rescue forbidden through current round")
		check(result["state"]["units"][0]["cannot_ready_round"]==1,"ready forbidden through current round")
		check(result["state"]["players"][0]["sigil"]==7,"correct printed 1 Sigil paid")
		check(result["state"]["players"][0]["discard"][-1]["card_id"]=="184","Edict discarded")
		check(cast(result["state"],"184",{"target_uid":"DOWNED"})["error"]=="EDICT_NOT_IN_HAND","consumed source card cannot recast")
	var site:Dictionary=fixture("185")
	site["sites"]=[{"card_id":"216","controller":1,"field":"Warfield"}]
	var u:Dictionary=Combat.unit("HOST","421",1,0,"Warfield")
	var combat:Dictionary={"sites":site["sites"],"attachments":[]}
	check(Combat._owned_passive_bonus(combat,u,"Stone",true)==1,"Bitumen Furnace active baseline")
	old=JSON.stringify(site)
	result=cast(site,"185",{"target_kind":"Site","target_card_id":"216","target_controller":1})
	check(result["ok"],"Writ of Seizure suppresses opponent Site")
	if result["ok"]:
		check(result["state"]["sites"][0]["exhausted"],"Site exhausted")
		check(Combat._owned_passive_bonus(result["state"],u,"Stone",true)==0,"exhausted Furnace gives zero bonus")
		check(result["state"]["players"][0]["sigil"]==7,"Writ cost paid")
		check(JSON.stringify(site)==old,"no input mutation")
		var beginning:Dictionary=result["state"].duplicate(true)
		beginning["phase"]=0
		beginning["seat"]=1
		var advance:Dictionary=Match.apply(beginning,{"type":"ADVANCE","seat":1,"revision":beginning["revision"]})
		check(advance["ok"],"owner can advance next Upkeep")
		if advance["ok"]:
			check(not advance["state"]["sites"][0]["exhausted"],"Site wakes exactly at controller Upkeep")
			check(Combat._owned_passive_bonus(advance["state"],u,"Stone",true)==1,"active Furnace restored")
	var relic:Dictionary=fixture("185")
	relic["attachments"]=[{"card_id":"239","controller":1,"host_uid":"HOST"}]
	check(Combat._owned_passive_bonus(relic,u,"Stone",true)==1,"Harness active baseline")
	result=cast(relic,"185",{"target_kind":"Relic","target_card_id":"239","target_controller":1,"target_host_uid":"HOST"})
	check(result["ok"],"Writ of Seizure suppresses opponent Relic")
	if result["ok"]:
		check(result["state"]["attachments"][0]["exhausted"],"Relic exhausted")
		check(Combat._owned_passive_bonus(result["state"],u,"Stone",true)==0,"exhausted Harness has zero bonus")
		var beginning:Dictionary=result["state"].duplicate(true)
		beginning["phase"]=0
		beginning["seat"]=1
		result=Match.apply(beginning,{"type":"ADVANCE","seat":1,"revision":beginning["revision"]})
		check(result["ok"] and not result["state"]["attachments"][0]["exhausted"],"Relic refreshed on owner's next Upkeep")
	var wrong:Dictionary=fixture("185")
	wrong["sites"]=[{"card_id":"216","controller":1,"field":"Warfield"}]
	check(cast(wrong,"185",{"target_kind":"Pet","target_card_id":"216","target_controller":1})["error"]=="RELIC_OR_SITE_REQUIRED","Pet not a target")
	check(cast(wrong,"185",{"target_kind":"Site","target_card_id":"999","target_controller":1})["error"]=="TARGET_PERMANENT_NOT_FOUND","nonexistent Site denied")
	check(cast(wrong,"185",{"target_kind":"Site","target_card_id":"216","target_controller":3})["error"]=="TARGET_CONTROLLER_INVALID","wrong seat refused")
	wrong["sites"][0]["exhausted"]=true
	check(cast(wrong,"185",{"target_kind":"Site","target_card_id":"216","target_controller":1})["error"]=="TARGET_ALREADY_EXHAUSTED","redundant exhausted target refused")
