extends SceneTree
const Match = preload("res://scripts/match_integrator.gd")
const FX = preload("res://scripts/real_effects.gd")
const Edict = preload("res://scripts/match_edicts.gd")
const Core = preload("res://scripts/real_combat_core.gd")
var passed:=0
var failed:=0

func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:
		failed+=1
		printerr("FAIL: "+label)

func fixture(id:String)->Dictionary:
	var state:Dictionary=Match.create(445)["state"]
	state["players"][0]["setup_ready"]=true
	state["players"][1]["setup_ready"]=true
	state["setup_complete"]=true
	state["phase"]=2
	state["players"][0]["sinew"]=5
	state["players"][0]["sigil"]=5
	state["players"][0]["oath"]=5
	var p:Dictionary=state["players"][0]
	var located:bool=false
	for c in p["hand"]:
		if str(c["card_id"])==id:located=true
	if not located:
		for idx in range(p["deck"].size()):
			if str(p["deck"][idx]["card_id"])==id:
				p["hand"].append(p["deck"].pop_at(idx))
				located=true
				break
	if not located:push_error("Missing source Edict "+id)
	return state

func cast(state:Dictionary,id:String,uid:String="")->Dictionary:
	return Match.apply(state,{"seat":0,"revision":int(state["revision"]),"type":"CAST",
		"card_id":id,"target_uid":uid})

func _initialize()->void:
	run()
	print("KUDURRU_M8_LIVE_EDICTS passed=%d failed=%d" % [passed,failed])
	quit(0 if failed==0 else 1)

func run()->void:
	for id in Match.EDICTS:
		check(Edict.verified(id),"exact original effect hash "+id)
	check(Match.EDICTS.size()==9,"nine source-verified Edicts available")
	var s:Dictionary=fixture("181")
	s["units"]=[Core.unit("ALLY","421",0,0),Core.unit("FOE","273",1,0)]
	s["units"][0]["wounds"]=1
	var original:String=JSON.stringify(s)
	var result:Dictionary=cast(s,"181")
	check(result["ok"],"Sun-Script Overload cast in Edicts")
	if not result["ok"]:return
	check(result["state"]["units"][0]["wounds"]==2,"friendly Warfield unit takes damage")
	check(result["state"]["units"][1]["wounds"]==1,"enemy Warfield unit takes damage")
	check(result["state"]["units"][0]["downed"],"threshold converts to Downed")
	check(not result["state"]["units"][1]["downed"],"single wound below threshold")
	check(result["state"]["players"][0]["sigil"]==3,"pays 2 Sigil")
	check(result["state"]["players"][0]["oath"]==4,"pays 1 Oath")
	check(result["state"]["players"][0]["discard"][-1]["card_id"]=="181","one-shot Edict goes discard")
	check(JSON.stringify(s)==original,"source fixture not mutated")
	s=fixture("188")
	s["units"]=[Core.unit("HEAL","421",0,0),Core.unit("ENEMY","273",1,0)]
	s["units"][0]["wounds"]=1
	s["units"][0]["silenced"]=true
	result=cast(s,"188","HEAL")
	check(result["ok"],"Mercy Docket resolves on friendly wounded Character")
	check(result["state"]["units"][0]["wounds"]==0,"clears exactly one wound")
	check(not result["state"]["units"][0]["silenced"],"removes Silence")
	check(cast(s,"188","ENEMY")["error"]=="FRIENDLY_CHARACTER_REQUIRED","cannot heal enemy")
	var fail_fixture:Dictionary=fixture("188")
	fail_fixture["units"]=[Core.unit("HEAL","421",0,0)]
	check(cast(fail_fixture,"188","HEAL")["error"]=="HEAL_OR_SILENCE_REQUIRED","no phantom empty heal")
	s=fixture("193")
	s["units"]=[Core.unit("UNIT","421",0,0)]
	s["units"][0]["exhausted"]=true
	result=cast(s,"193","UNIT")
	check(result["ok"],"Convoy Priority resolves")
	check(not result["state"]["units"][0]["exhausted"],"unit readied")
	check(result["state"]["units"][0]["cannot_support_round"]==1,"cannot support for current round")
	var before_phase:Dictionary=s.duplicate(true)
	before_phase["phase"]=3
	check(cast(before_phase,"193","UNIT")["error"]=="EDICTS_WINDOW_REQUIRED","out-of-phase Edict blocked")
	check(cast(fixture("193"),"193","NONE")["error"]=="FRIENDLY_EXHAUSTED_REQUIRED","requires actual exhausted target")
	var combat:Dictionary=Core.create([["255"],["16"]],
		[Core.unit("MAIN","421",0,0),Core.unit("SUPPORT","407",0,1)])["state"]
	combat["units"][1]["cannot_support_round"]=1
	check(Core._support(combat,combat["units"][0],"SUPPORT","Stone")["error"]=="SUPPORT_RESTRICTED_THIS_ROUND","Convoy supporter ban enforced")
	combat["round"]=2
	check(Core._support(combat,combat["units"][0],"SUPPORT","Stone")["ok"],"support allowed in later round")
	s=fixture("191")
	s["players"][0]["heat"]=4
	s["players"][1]["heat"]=2
	result=cast(s,"191")
	check(result["ok"],"Festival Truce resolves")
	if not result["ok"]:return
	check(result["state"]["players"][0]["heat"]==3 and result["state"]["players"][1]["heat"]==1,"Heat relief on both seats")
	check(Edict.engagements_blocked(result["state"],0,1),"mutual engagements blocked")
	check(not Edict.engagements_blocked(s,0,1),"never blocks when not cast")
	var next:Dictionary=result["state"].duplicate(true)
	next["phase"]=0
	next["seat"]=0
	next["round"]=2
	next=Match.apply(next,{"seat":0,"revision":next["revision"],"type":"ADVANCE"})["state"]
	check(not Edict.engagements_blocked(next,0,1),"truce expires on caster's next Upkeep")
	var wrong:Dictionary=fixture("191")
	wrong["players"][0]["sigil"]=0
	original=JSON.stringify(wrong)
	check(cast(wrong,"191")["error"]=="INSUFFICIENT_sigil","cannot cast unpaid Truce")
	check(JSON.stringify(wrong)==original,"no mutation on insufficient resources")
	check(Edict.verified("187"),"Night Market source now supported in the End-only reducer path")
