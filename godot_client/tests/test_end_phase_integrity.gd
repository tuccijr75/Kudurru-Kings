extends SceneTree
const Match=preload("res://scripts/match_integrator.gd")
const Source=preload("res://scripts/real_effects.gd")
var passed:int=0
var failed:int=0
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:
		failed+=1
		printerr("FAIL: "+label)
func action(s:Dictionary,kind:String,payload:Dictionary={})->Dictionary:
	var cmd:Dictionary={"seat":int(s["seat"]),"revision":int(s["revision"]),"type":kind}
	for k in payload:cmd[k]=payload[k]
	return Match.apply(s,cmd)
func fixture()->Dictionary:
	var s:Dictionary=Match.create(7113)["state"]
	for seat in range(2):
		s=Match.apply(s,{"type":"KEEP","seat":seat,"revision":s["revision"]})["state"]
	for i in range(6):
		s=action(s,"ADVANCE")["state"]
	# Arrange 8-source-card hand without inventing cards. This fixture is not
	# replayable because it bypasses the real draw engine solely for gate tests.
	for i in range(2):s["players"][0]["hand"].append(s["players"][0]["deck"].pop_back())
	return s
func _initialize()->void:call_deferred("run")
func run()->void:
	var s:Dictionary=fixture()
	check(int(s["phase"])==6,"actual End window")
	check(s["players"][0]["hand"].size()==8,"eight source cards before hand limit")
	var total:int=s["players"][0]["hand"].size()+s["players"][0]["deck"].size()+s["players"][0]["discard"].size()
	check(total==36,"real 36 cards conserved pre-discard")
	var original:String=JSON.stringify(s)
	check(action(s,"ADVANCE")["error"]=="END_HAND_LIMIT_CHOICE_REQUIRED","automatic ending with eight blocked")
	check(action(s,"END_DISCARD",{"hand_index":-1})["error"]=="INVALID_END_DISCARD","negative index denied")
	check(action(s,"END_DISCARD",{"hand_index":400})["error"]=="INVALID_END_DISCARD","out of range denied")
	var target_id:String=str(s["players"][0]["hand"][2]["card_id"])
	var end1:Dictionary=action(s,"END_DISCARD",{"hand_index":2})
	check(end1["ok"],"owner chooses third exact hand instance")
	if not end1["ok"]:quit(1);return
	var s1:Dictionary=end1["state"]
	check(s1["players"][0]["hand"].size()==7,"first selected discard removes one card")
	check(s1["players"][0]["discard"][-1]["card_id"]==target_id,"chosen card, not last, discarded")
	check(s1["events"][-1]["type"]=="END_HAND_LIMIT_DISCARD","exact action event journaled")
	check(JSON.stringify(s)==original,"source match state immutable")
	check(action(s1,"ADVANCE")["error"]=="END_HAND_LIMIT_CHOICE_REQUIRED","still seven: must choose again")
	var second_id:String=str(s1["players"][0]["hand"][0]["card_id"])
	var end2:Dictionary=action(s1,"END_DISCARD",{"hand_index":0})
	check(end2["ok"],"second selected discard resolves")
	var s2:Dictionary=end2["state"]
	check(s2["players"][0]["hand"].size()==6,"End hand now exactly six")
	check(s2["players"][0]["discard"][-1]["card_id"]==second_id,"second chosen card matches index")
	check(action(s2,"END_DISCARD",{"hand_index":0})["error"]=="HAND_LIMIT_NOT_EXCEEDED","no gratuitous extra discard")
	check(s2["revision"]==s2["action_log"].size(),"extra player actions replay-journalled")
	var income:Dictionary=Match._summary_income(s2,0)
	check(income.has("sinew") and income.has("sigil") and income.has("oath"),"three independently named income components")
	var closed:Dictionary=action(s2,"ADVANCE")
	check(closed["ok"],"ending is legal after six")
	check(closed["state"]["seat"]==1,"turn passes to opponent")
	check(closed["state"]["players"][0]["hand"].size()==6,"no hidden automatic card discard")
	check(closed["state"]["players"][0]["hand"].size()+closed["state"]["players"][0]["deck"].size()+closed["state"]["players"][0]["discard"].size()==36,"all source cards remain conserved")
	var invalid_phase:Dictionary=s.duplicate(true)
	invalid_phase["phase"]=3
	check(action(invalid_phase,"END_DISCARD",{"hand_index":0})["error"]=="END_WINDOW_REQUIRED","cannot use End discard in Main")
	var a:Dictionary=Match.next_action(s,0)
	check(a["type"]=="END_DISCARD","opponent decision generator can choose discard")
	check(action(s,a["type"],{"hand_index":a["hand_index"]})["ok"],"automated End discard valid")
	var ui:Control=load("res://scenes/real_match.tscn").instantiate()
	root.add_child(ui)
	check(ui.end_income_preview!=null,"End income preview label instantiated")
	check(ui.end_income_preview.text.contains("Sinew:") and ui.end_income_preview.text.contains("Sigil:") and ui.end_income_preview.text.contains("Oath:"),"three resource earning conditions visible")
	ui.state=s
	ui._refresh()
	check(ui.next_button.disabled,"End advance disabled while >6 cards")
	check(ui.hand_list.get_child(0).text.begins_with("DISCARD:"),"every hand card offered as discard choice")
	ui._deploy(str(s["players"][0]["hand"][2]["card_id"]),2)
	check(ui.state["players"][0]["hand"].size()==7,"UI chooses exactly one discard")
	check(ui.state["players"][0]["discard"][-1]["card_id"]==target_id,"UI selects designated hand index")
	ui._deploy(str(ui.state["players"][0]["hand"][0]["card_id"]),0)
	check(ui.state["players"][0]["hand"].size()==6,"UI closes hand limit")
	check(not ui.next_button.disabled,"End advance re-enabled after choices")
	ui.free()
	print("KUDURRU_M13_END_PHASE_INTEGRITY passed=%d failed=%d" % [passed,failed])
	quit(0 if failed==0 else 1)
