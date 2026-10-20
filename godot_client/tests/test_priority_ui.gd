extends SceneTree
const Match=preload("res://scripts/match_integrator.gd")
const Combat=preload("res://scripts/real_combat_core.gd")
const Server=preload("res://scripts/localhost_match_server.gd")
var passed:int=0
var failed:int=0
func check(v:bool,label:String)->void:
	if v:passed+=1
	else:
		failed+=1
		printerr("FAIL: "+label)
func fixture(acting:int,id:String,heat_seat:int,heat_amount:int)->Dictionary:
	var s:Dictionary=Match.create(848)["state"]
	s["setup_complete"]=true
	for p in s["players"]:p["setup_ready"]=true
	s["phase"]=2
	s["seat"]=acting
	s["players"][acting]["sigil"]=10
	s["players"][acting]["oath"]=10
	s["players"][heat_seat]["heat"]=heat_amount
	s["players"][heat_seat]["oath"]=5
	var p:Dictionary=s["players"][acting]
	var found:bool=false
	for card in p["hand"]:
		if str(card["card_id"])==id:found=true
	if not found:
		for i in range(p["deck"].size()):
			if str(p["deck"][i]["card_id"])==id:
				p["hand"].append(p["deck"].pop_at(i))
				break
	return s
func _initialize()->void:call_deferred("run")
func run()->void:
	var screen:Control=load("res://scenes/real_match.tscn").instantiate()
	root.add_child(screen)
	var source:Dictionary=fixture(0,"182",1,4)
	screen.state=source
	screen._refresh()
	var discard_before:int=source["players"][1]["discard"].size()
	screen._action("CAST",{"card_id":"182"})
	check(screen.state["priority_queue"].is_empty(),"local AI answers opponent choice outside its active turn")
	check(screen.state["players"][1]["discard"].size()==discard_before+1,
		"victim AI discarded its own real hand card")
	check(screen.state["seat"]==0,"actor gets control after opponent response")
	check(screen.state["events"][-1]["type"]=="OPPONENT_CHOICE","victim choice logged")
	var victim:Dictionary=fixture(1,"182",0,4)
	victim["players"][0]["oath"]=5
	victim["units"]=[Combat.unit("FRIEND","421",0,0,"Warfield")]
	var cast:Dictionary=Match.apply(victim,{"seat":1,"revision":victim["revision"],
		"type":"CAST","card_id":"182"})
	check(cast["ok"],"opponent can force source-verified priority")
	if not cast["ok"]:screen.free();quit(1);return
	screen.state=cast["state"]
	screen._refresh()
	check(not screen.state["priority_queue"].is_empty(),"player response still pending")
	check(screen.next_button.disabled,"cannot advance while targeted player responding")
	check(not screen.priority_oath_button.disabled,"real lose-Oath response button available")
	check(not screen.priority_exhaust_button.disabled,"real exhaust response button available")
	check(screen.hand_list.get_child(0).text.begins_with("DISCARD:"),"hand becomes a legal victim-controlled discard")
	var server=Server.new()
	server.game=screen.state
	var view0:Dictionary=server._projection(0)
	var view1:Dictionary=server._projection(1)
	check(view0["pending_choice"].has("options"),"victim receives its legally available choices")
	check(not view1["pending_choice"].has("options"),"other player cannot inspect victim-specific choice inventory")
	check(not view1["players"][0].has("hand"),"no opponent hand leaked")
	server.free()
	screen._choice("LOSE_OATH")
	check(screen.state["priority_queue"].is_empty(),"UI choice releases priority window")
	check(screen.state["players"][0]["oath"]==3,"player knowingly paid exact two Oath")
	var audit:Dictionary=fixture(1,"190",0,3)
	audit["units"]=[Combat.unit("LEGAL","421",0,0,"Warfield")]
	cast=Match.apply(audit,{"seat":1,"revision":audit["revision"],
		"type":"CAST","card_id":"190","target_seat":0})
	check(cast["ok"],"opponent targets player with legal Censor Audit")
	screen.state=cast["state"]
	screen._refresh()
	check(not screen.priority_silence_button.disabled,"Silence response control enabled")
	check(screen.edict_target_select.item_count>0,"friendly unit available for response")
	screen._choice("SILENCE_UNIT")
	check(screen.state["priority_queue"].is_empty(),"Censor Audit choice closed")
	check(screen.state["units"][0]["silenced"],"real targeted unit Silenced by its controller")
	screen.free()
	print("KUDURRU_M12_PRIORITY_MATCH_UI passed=%d failed=%d" % [passed,failed])
	quit(0 if failed==0 else 1)
