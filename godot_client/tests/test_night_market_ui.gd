extends SceneTree
const Match=preload("res://scripts/match_integrator.gd")
const Store=preload("res://scripts/match_storage.gd")
var checks:int=0
var fails:int=0
func check(ok:bool,label:String)->void:
	if ok:checks+=1
	else:
		fails+=1
		printerr("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
	var node:Control=load("res://scenes/real_match.tscn").instantiate()
	root.add_child(node)
	var fixture:Dictionary={}
	for seed in range(1,125):
		var r:Dictionary=Match.create(seed)
		if not r["ok"]:continue
		for c in r["state"]["players"][0]["hand"]:
			if str(c["card_id"])=="187":
				fixture=r["state"]
				break
		if not fixture.is_empty():break
	check(not fixture.is_empty(),"seed with real printed Night Market")
	if fixture.is_empty():node.free();quit(1);return
	for seat in range(2):
		var a:Dictionary=Match.apply(fixture,{"seat":seat,"revision":fixture["revision"],"type":"KEEP"})
		fixture=a["state"]
	for i in range(6):
		var next:Dictionary=Match.apply(fixture,{"seat":0,"revision":fixture["revision"],"type":"ADVANCE"})
		fixture=next["state"]
	node.state=fixture
	node._refresh()
	check(not node.night_market_button.disabled,"End-only Night Market UI enabled")
	check(not node.next_button.disabled,"End advance available before chosen effect")
	node._action("CAST_END")
	check(not node.state["pending_end_clause"].is_empty(),"clicked live Edict waits for discard")
	check(node.next_button.disabled,"End button disabled until user choice")
	check(node.night_market_button.disabled,"cannot recast while waiting for discard")
	check(node.hand_list.get_child_count()==node.state["players"][0]["hand"].size(),
		"hand buttons include newly drawn cards")
	var id:String=str(node.state["players"][0]["hand"][-1]["card_id"])
	check(node.hand_list.get_child(0).text.begins_with("DISCARD:"),"UI says DISCARD instead of DEPLOY")
	node._deploy(id)
	check(node.state["pending_end_clause"].is_empty(),"selection resolves pending Night Market")
	check(node.state["players"][0]["heat"]==1,"Heat increment on selected discard")
	check(not node.next_button.disabled,"End advance enabled after choice")
	check(Store.replay(node.state)["ok"],"UI choice is fully replayable")
	node._next()
	check(node.state["phase"]==0 and node.state["seat"]==0,"opponent turn auto-executed safely")
	check(Store.replay(node.state)["ok"],"AI continuation after choice deterministic")
	node.free()
	print("KUDURRU_M11_NIGHT_MARKET_UI passed=%d failed=%d" % [checks,fails])
	quit(0 if fails==0 else 1)
