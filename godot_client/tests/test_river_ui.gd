extends SceneTree
const Match=preload("res://scripts/match_integrator.gd")
const Combat=preload("res://scripts/real_combat_core.gd")
var passed:int=0
var failed:int=0
func check(ok:bool,what:String)->void:
	if ok:passed+=1
	else:
		failed+=1
		printerr("FAIL: "+what)
func _initialize()->void:call_deferred("run")
func run()->void:
	var scene:PackedScene=load("res://scenes/real_match.tscn")
	var ui:Control=scene.instantiate()
	root.add_child(ui)
	check(ui.displacement_a!=null and ui.displacement_b!=null,"two player-controlled displacement selectors")
	var s:Dictionary=Match.create(4731)["state"]
	s["setup_complete"]=true
	for p in s["players"]:p["setup_ready"]=true
	s["phase"]=2
	s["players"][0]["sigil"]=3
	var present:bool=false
	for c in s["players"][0]["hand"]:
		if str(c["card_id"])=="186":present=true
	if not present:
		for i in range(s["players"][0]["deck"].size()):
			if s["players"][0]["deck"][i]["card_id"]=="186":
				s["players"][0]["hand"].append(s["players"][0]["deck"].pop_at(i))
				break
	s["units"]=[Combat.unit("TARGET-A","421",0,0,"Warfield"),Combat.unit("TARGET-B","422",1,0,"Warfield")]
	ui.state=s
	ui._refresh()
	check(ui.displacement_a.item_count==2,"real unit target selector populated")
	check(ui.displacement_b.item_count==3,"optional second unit selector present")
	ui.displacement_a.select(0)
	ui.displacement_b.select(2)
	ui._deploy("186")
	check(ui.state["units"][0]["field"]=="Sanctuary","first chosen unit moved through UI")
	check(ui.state["units"][1]["field"]=="Sanctuary","second chosen unit moved through UI")
	check(ui.state["players"][0]["discard"][-1]["card_id"]=="186","correct printed Edict consumed in real screen")
	check(ui.state["events"][-1]["resolved"]["displaced"].size()==2,"both targets journaled in screen")
	check(ui.state["revision"]==1,"screen's reducer committed one legal action")
	ui.free()
	print("KUDURRU_M16_DISPLACEMENT_UI passed=%d failed=%d" % [passed,failed])
	quit(0 if failed==0 else 1)
