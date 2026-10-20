extends SceneTree
const Match=preload("res://scripts/match_integrator.gd")
const Core=preload("res://scripts/real_combat_core.gd")
var passed:int=0
var failed:int=0
func check(v:bool,label:String)->void:
	if v:passed+=1
	else:
		failed+=1
		printerr("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func fixture(acting:int)->Dictionary:
	var s:Dictionary=Match.create(3468)["state"]
	s["setup_complete"]=true
	for p in s["players"]:
		p["setup_ready"]=true
		p["sinew"]=4
	s["seat"]=acting
	s["phase"]=4
	s["units"]=[Core.unit("HERO","421",acting,0,"Warfield"),
		Core.unit("VICTIM","421",1-acting,0,"Warfield")]
	return s
func run()->void:
	var scene:PackedScene=load("res://scenes/real_match.tscn")
	var ui:Control=scene.instantiate()
	root.add_child(ui)
	check(ui.attack_spend_pick!=null and ui.defense_spend_pick!=null,"independent attacker/defender spend controls")
	check(ui.defense_button!=null,"defender choice button exists")
	var s:Dictionary=fixture(0)
	ui.state=s
	ui._refresh()
	check(not ui.attack_button.disabled,"attacker can declare real battle")
	ui.attack_spend_pick.select(1)
	ui._attack()
	check(ui.state["pending_attack"].is_empty(),"local opponent answered defender-owned choice")
	check(ui.state["players"][0]["sinew"]==3,"attacker-selected 1 Sinew paid")
	check(ui.state["players"][1]["sinew"]==4,"defender opponent retains its own Sinew by choosing zero")
	check(ui.state["action_log"][-2]["type"]=="DECLARE_ATTACK","real UI declaration logged")
	check(ui.state["action_log"][-1]["type"]=="CHOOSE_DEFENSE","AI defender chose independently")
	check(ui.state["action_log"][-1]["seat"]==1,"AI defense action owned by victim")
	var enemy:Dictionary=fixture(1)
	var attack:Dictionary=Match.apply(enemy,{"seat":1,"revision":enemy["revision"],
		"type":"DECLARE_ATTACK","attacker":"HERO","defender":"VICTIM","axis":"Stone"})
	check(attack["ok"],"legal AI engagement asks player for defense")
	if not attack["ok"]:ui.free();quit(1);return
	ui.state=attack["state"]
	ui._refresh()
	check(not ui.defense_button.disabled,"human defender sees enabled choice")
	check(ui.combat_hint.text.contains("DEFEND YOUR UNIT") and ui.combat_hint.text.contains("Stone"),
		"solo player sees attacker, axis and own defense prompt")
	check(ui.next_button.disabled,"normal turn advancement stops for mandatory defense")
	ui.defense_spend_pick.select(2)
	ui._defend()
	check(ui.state["pending_attack"].is_empty(),"human chosen defense resolves battle")
	var found:bool=false
	for action in ui.state["action_log"]:
		if action["type"]=="CHOOSE_DEFENSE" and action["seat"]==0 and action["defender_spend"]==2:found=true
	check(found,"real human interface commits exactly their chosen two-resource response")
	check(ui.state["players"][0]["sinew"]==2,"human defender pays own chosen resource amount")
	ui.free()
	print("KUDURRU_M17_COMBAT_CHOICE_UI passed=%d failed=%d" % [passed,failed])
	quit(0 if failed==0 else 1)
