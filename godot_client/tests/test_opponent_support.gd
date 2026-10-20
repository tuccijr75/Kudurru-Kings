extends SceneTree
const Match=preload("res://scripts/match_integrator.gd")
const Combat=preload("res://scripts/real_combat_core.gd")
var passed:int=0
var failed:int=0
func check(value:bool,label:String)->void:
	if value:passed+=1
	else:
		failed+=1
		printerr("FAIL: "+label)
func fixture(support_id:String)->Dictionary:
	var state:Dictionary=Match.create(711)["state"]
	for seat in range(2):
		var ready:Dictionary=Match.apply(state,{"type":"KEEP","seat":seat,"revision":state["revision"]})
		state=ready["state"]
	for i in range(3):
		state=Match.apply(state,{"type":"ADVANCE","seat":0,"revision":state["revision"]})["state"]
	var p:Dictionary=state["players"][0]
	var all:Array=p["hand"]+p["deck"]
	var support_card:Dictionary={}
	var char_card:Dictionary={}
	var unused:Array=[]
	for card in all:
		if str(card["card_id"])==support_id and support_card.is_empty():
			support_card=card
		elif str(card["card_family"])=="Character" and char_card.is_empty():
			char_card=card
		else:
			unused.append(card)
	if support_card.is_empty() or char_card.is_empty():return {}
	p["hand"]=[support_card]
	p["deck"]=unused
	p["sinew"]=5
	p["sigil"]=5
	var unit:Dictionary=Combat.unit("HOST",str(char_card["card_id"]),0,0,"Warfield")
	unit["exhausted"]=false
	state["units"]=[unit]
	return state
func _initialize()->void:
	_run()
	print("KUDURRU_M11_OPPONENT_SUPPORT passed=%d failed=%d" % [passed,failed])
	quit(0 if failed==0 else 1)
func _run()->void:
	for id in ["239","241","254"]:
		var state:Dictionary=fixture(id)
		check(not state.is_empty(),"real source support exists "+id)
		if state.is_empty():continue
		var advice:Dictionary=Match.next_action(state,0)
		check(advice["type"]=="DEPLOY","AI chooses actual Pet/Relic deployment "+id)
		check(advice.get("card_id","")==id,"no wrong source card "+id)
		check(advice.get("host_uid","")=="HOST","real host chosen "+id)
		check(advice.get("field","")=="Warfield","correct host field "+id)
		var deployed:Dictionary=Match.apply(state,advice)
		check(deployed["ok"],"AI support is legal paid action "+id)
		if not deployed["ok"]:continue
		check(deployed["state"]["attachments"].size()==1,"support enters actual attachment zone "+id)
		check(deployed["state"]["attachments"][0]["card_id"]==id,"exact real item enters zone "+id)
		check(deployed["state"]["players"][0]["hand"].is_empty(),"played support removed from hand "+id)
		check(deployed["state"]["revision"]==state["revision"]+1,"support action logged as revision "+id)
		check(Match.next_action(deployed["state"],0)["type"]=="ADVANCE","AI progresses after supported equipment played "+id)
	var no_host:Dictionary=fixture("239")
	no_host["units"].clear()
	check(Match.next_action(no_host,0)["type"]=="ADVANCE","AI cannot equip without host")
