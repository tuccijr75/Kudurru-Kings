extends SceneTree
const Match=preload("res://scripts/match_integrator.gd")
const Edicts=preload("res://scripts/match_edicts.gd")
const Storage=preload("res://scripts/match_storage.gd")
var passed:int=0
var failed:int=0
func check(ok:bool,why:String)->void:
	if ok:passed+=1
	else:
		failed+=1
		printerr("FAIL: "+why)
func fixture()->Dictionary:
	var s:Dictionary={}
	for seed in range(1,151):
		var made:Dictionary=Match.create(seed)
		if not made.get("ok",false):continue
		var found:bool=false
		for c in made["state"]["players"][0]["hand"]:
			if str(c["card_id"])=="187":found=true
		if found:
			s=made["state"]
			break
	if s.is_empty():return {}
	for seat in range(2):
		var setup:Dictionary=Match.apply(s,{"type":"KEEP","seat":seat,"revision":int(s["revision"])})
		s=setup["state"]
	for k in range(6):
		var transition:Dictionary=Match.apply(s,{"type":"ADVANCE","seat":0,"revision":int(s["revision"])})
		s=transition["state"]
	return s
func act(s:Dictionary,typ:String,opts:Dictionary={})->Dictionary:
	var cmd:Dictionary={"seat":0,"revision":s["revision"],"type":typ}
	for k in opts:cmd[k]=opts[k]
	return Match.apply(s,cmd)
func _initialize()->void:
	_run()
	print("KUDURRU_M11_NIGHT_MARKET_CHOICE passed=%d failed=%d" % [passed,failed])
	quit(0 if failed==0 else 1)
func _run()->void:
	check(Edicts.verified("187"),"source-hashed Night Market Clause")
	var state:Dictionary=fixture()
	var pre:String=JSON.stringify(state)
	var pre_deck:int=state["players"][0]["deck"].size()
	var pre_hand:int=state["players"][0]["hand"].size()
	var pre_discard:int=state["players"][0]["discard"].size()
	var called:Dictionary=act(state,"CAST_END")
	check(called["ok"],"cast only in End")
	if not called["ok"]:return
	var after:Dictionary=called["state"]
	check(not after["pending_end_clause"].is_empty(),"discard choice pending")
	check(after["players"][0]["hand"].size()==pre_hand-1+2,"two real cards drawn")
	check(after["players"][0]["deck"].size()==pre_deck-2,"deck order consumed correctly")
	check(after["players"][0]["discard"].size()==pre_discard+1,"cast Edict placed in discard")
	check(after["players"][0]["discard"][-1]["card_id"]=="187","Night Market actual card spent")
	check(after["players"][0]["sigil"]==0,"printed deployment cost paid")
	check(after["players"][0]["heat"]==0,"Heat deferred to chosen discard")
	check(after["events"][-1]["type"]=="NIGHT_MARKET_DRAW","private draw event")
	check(not after["events"][-1].has("cards"),"hidden drawn card identities not public")
	check(JSON.stringify(state)==pre,"original state unchanged")
	check(act(after,"ADVANCE")["error"]=="NIGHT_MARKET_DISCARD_PENDING","cannot end turn with pending choice")
	check(act(after,"CAST_END")["error"]=="DISCARD_PENDING","cannot cast another pending Clause")
	check(act(after,"CLAUSE_DISCARD",{"hand_index":-1})["error"]=="INVALID_DISCARD_CHOICE","negative choice rejected")
	check(act(after,"CLAUSE_DISCARD",{"hand_index":999})["error"]=="INVALID_DISCARD_CHOICE","out of range choice rejected")
	var to_discard:String=after["players"][0]["hand"][-1]["card_id"]
	var completed:Dictionary=act(after,"CLAUSE_DISCARD",{"hand_index":after["players"][0]["hand"].size()-1})
	check(completed["ok"],"player chooses real card to discard")
	if not completed["ok"]:return
	var done:Dictionary=completed["state"]
	check(done["pending_end_clause"].is_empty(),"no pending choice after discard")
	check(done["players"][0]["heat"]==1,"one printed Heat earned only on completion")
	check(done["players"][0]["discard"][-1]["card_id"]==to_discard,"chosen card correctly discarded")
	check(done["revision"]==done["action_log"].size(),"both actions replayable")
	check(Storage.replay(done)["ok"],"Night Market full-choice replay deterministic")
	check(act(done,"CLAUSE_DISCARD",{"hand_index":0})["error"]=="NO_PENDING_END_DISCARD","choice cannot repeat")
	var next:Dictionary=act(done,"ADVANCE")
	check(next["ok"],"legal End phase completes after choice")
	check(next["state"]["seat"]==1,"opponent turn reached after legal discard")
	var wrong:Dictionary=fixture()
	wrong["phase"]=3
	check(act(wrong,"CAST_END")["error"]=="END_WINDOW_REQUIRED","Clause impossible in Main")
	check(act(state,"CAST",{"card_id":"187"})["error"]=="EDICTS_WINDOW_REQUIRED","Clause not Edicts phase")
	var no_sigils:Dictionary=fixture()
	no_sigils["players"][0]["sigil"]=0
	check(not act(no_sigils,"CAST_END")["ok"],"insufficient Sigil prevented")
	check(act(state,"CLAUSE_DISCARD",{"hand_index":0})["error"]=="NO_PENDING_END_DISCARD","no discard without prior cast")
	check(state["players"][0]["hand"].size()+state["players"][0]["deck"].size()+state["players"][0]["discard"].size()==36,"pre-cast cards conserved")
	check(done["players"][0]["hand"].size()+done["players"][0]["deck"].size()+done["players"][0]["discard"].size()==36,"cast and choice preserve all cards")
