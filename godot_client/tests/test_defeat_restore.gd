extends SceneTree
const Match=preload("res://scripts/match_integrator.gd")
const Combat=preload("res://scripts/real_combat_core.gd")
var passed:int=0
var failed:int=0
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:
		failed+=1
		printerr("FAIL: "+label)
func take_id(s:Dictionary,owner:int,id:String)->Dictionary:
	for zone in ["hand","deck"]:
		for i in range(s["players"][owner][zone].size()):
			var card:Dictionary=s["players"][owner][zone][i]
			if str(card["card_id"])==id:
				return s["players"][owner][zone].pop_at(i)
	return {}
func tally(s:Dictionary,owner:int)->int:
	var total:int=0
	for zone in ["hand","deck","discard"]:
		total+=s["players"][owner][zone].size()
	for unit in s["units"]:
		if int(unit["owner"])==owner:total+=1
	for att in s["attachments"]:
		if int(att["controller"])==owner:total+=1
	for site in s["sites"]:
		if int(site["controller"])==owner:total+=1
	return total
func _initialize()->void:
	run()
	print("KUDURRU_M14_DEFEAT_RETURN passed=%d failed=%d" % [passed,failed])
	quit(0 if failed==0 else 1)
func run()->void:
	var s:Dictionary=Match.create(2801)["state"]
	for seat in range(2):
		s=Match.apply(s,{"type":"KEEP","seat":seat,"revision":s["revision"]})["state"]
	var selected:Array=[]
	for zone in ["hand","deck"]:
		for c in s["players"][0][zone]:
			if c["card_family"]=="Character" and not selected.has(c["card_id"]):
				selected.append(c["card_id"])
				if selected.size()==2:break
		if selected.size()==2:break
	check(selected.size()==2,"two distinct real source Characters exist")
	var card0:Dictionary=take_id(s,0,str(selected[0]))
	var card1:Dictionary=take_id(s,0,str(selected[1]))
	var harness:Dictionary=take_id(s,0,"239")
	check(not card0.is_empty() and not card1.is_empty() and not harness.is_empty(),"three real physical source cards moved to Field")
	var a:Dictionary=Combat.unit("DEF-A",str(selected[0]),0,0)
	a["defeated"]=true
	a["defeated_round"]=1
	var b:Dictionary=Combat.unit("DEF-B",str(selected[1]),1,0)
	b["owner"]=0
	b["defeated"]=true
	b["defeated_round"]=1
	s["units"]=[a,b]
	s["attachments"]=[{"card_id":"239","controller":0,"host_uid":"DEF-A"}]
	while s["players"][0]["hand"].size()<5 and not s["players"][0]["deck"].is_empty():
		s["players"][0]["hand"].append(s["players"][0]["deck"].pop_back())
	check(tally(s,0)==36 and tally(s,1)==36,"physical source card conservation before restore")
	var source:String=JSON.stringify(s)
	s["round"]=2
	s["seat"]=1
	s["phase"]=6
	var too_early:Dictionary=Match.apply(s,{"type":"ADVANCE","seat":1,"revision":s["revision"]})
	check(too_early["ok"],"turn boundary at round 2")
	if not too_early["ok"]:return
	check(too_early["state"]["round"]==3,"round increments to 3")
	check(too_early["state"]["units"].size()==2,"Defeated units remain Field through two full rounds")
	check(too_early["event"]["defeated_returns"].is_empty(),"no early restoration after one full round")
	check(too_early["state"]["attachments"].size()==1,"attached Relic remains until host leaves")
	var due:Dictionary=too_early["state"].duplicate(true)
	due["seat"]=1
	due["phase"]=6
	due["round"]=3
	var original:String=JSON.stringify(due)
	var transition:Dictionary=Match.apply(due,{"type":"ADVANCE","seat":1,"revision":due["revision"]})
	check(transition["ok"],"second intervening round End transitions to restoration")
	if not transition["ok"]:return
	var restored:Dictionary=transition["state"]
	check(restored["round"]==4,"due only on round four")
	check(restored["units"].is_empty(),"both Defeated units removed only when due")
	check(restored["attachments"].is_empty(),"orphaned attachments removed when host leaves")
	check(restored["players"][0]["hand"].size()==6,"owner Hand takes first return if capacity")
	check(restored["players"][0]["deck"].size()==due["players"][0]["deck"].size()+1,"second return into deck when hand full")
	check(restored["players"][0]["hand"][-1]["card_id"]==selected[0],"correct unit returned to owner's Hand")
	check(restored["players"][0]["discard"][-1]["card_id"]=="239","Relic moved to former controller's discard candidate path")
	check(restored["events"][-1]["type"]=="PHASE","return is recorded in actual round transition")
	check(restored["events"][-1]["defeated_returns"].size()==2,"both exact return identities journaled")
	check(restored["events"][-1]["released_support"].size()==1,"support release journaled")
	check(restored["events"][-1]["defeated_returns"][1]["original_owner"]==0,"control change does not steal original ownership")
	check(tally(restored,0)==36 and tally(restored,1)==36,"all 36 source cards conserved after restoration")
	check(JSON.stringify(due)==original,"original match state not mutated")
	var second:Dictionary=Match._restore_defeated_due(restored)
	check(second["ok"] and second["returns"].is_empty(),"restoration cannot duplicate")
	check(tally(restored,0)==36,"repeat cannot mint card")
	check(s["round"]==2,"pre-round fixture unchanged")
	var stay:Dictionary=due.duplicate(true)
	stay["units"][1]["defeated_round"]=2
	transition=Match.apply(stay,{"type":"ADVANCE","seat":1,"revision":stay["revision"]})
	check(transition["ok"],"mixed due and not due transition accepted")
	if transition["ok"]:
		check(transition["state"]["units"].size()==1,"only overdue unit restored")
		check(transition["state"]["units"][0]["uid"]=="DEF-B","one newer defeat remains on battlefield")
		check(tally(transition["state"],0)==36,"mixed-age restoration conserves cards")
	var invalid:Dictionary=due.duplicate(true)
	invalid["units"][0]["owner"]=27
	var bad:Dictionary=Match.apply(invalid,{"type":"ADVANCE","seat":1,"revision":invalid["revision"]})
	check(bad["error"]=="RESTORE_ORIGINAL_OWNER_INVALID","bad original owner rejected atomically")
	check(JSON.stringify(invalid).contains("DEF-A"),"rejected restoration retains original state")
