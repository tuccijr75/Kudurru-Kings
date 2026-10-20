extends SceneTree
## M18: two actual TCP clients against one authoritative Godot host,
## including both players' real UI decisions and forbidden network input.
const Match=preload("res://scripts/match_integrator.gd")
const Core=preload("res://scripts/real_combat_core.gd")
var passed:int=0
var failed:int=0
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:
		failed+=1
		printerr("FAIL: "+label)
func wait_frames(n:int=7)->void:
	for i in range(n):await create_timer(0.04).timeout
func fixture()->Dictionary:
	var made:Dictionary=Match.create(13342,"BorderstoneGuild","BorderstoneGuild")
	var s:Dictionary=made["state"]
	s["setup_complete"]=true
	s["phase"]=4
	s["seat"]=0
	for seat in range(2):
		var player:Dictionary=s["players"][seat]
		player["setup_ready"]=true
		player["sinew"]=5
		var found:Dictionary={}
		for zone in ["hand","deck"]:
			for i in range(player[zone].size()-1,-1,-1):
				var card:Dictionary=player[zone][i]
				if card["card_family"]=="Character":
					found=player[zone].pop_at(i)
					break
			if not found.is_empty():break
		if found.is_empty():
			printerr("FIXTURE_SOURCE_CHARACTER_MISSING")
			return {}
		var uid:String="ATTACKER" if seat==0 else "DEFENDER"
		s["units"].append(Core.unit(uid,str(found["card_id"]),seat,0,"Warfield"))
	return s
func _initialize()->void:call_deferred("run")
func run()->void:
	var scene:PackedScene=load("res://scenes/local_match_client.tscn")
	var a:Control=scene.instantiate()
	root.add_child(a)
	a._host_and_join()
	await wait_frames()
	var b:Control=scene.instantiate()
	root.add_child(b)
	b._join()
	await wait_frames()
	check(a.seat==0 and b.seat==1,"two independent real local network seats connected")
	check(a.token.length()==64 and b.token.length()==64 and a.token!=b.token,
		"authentic unique ephemeral session tokens")
	if a.seat!=0 or b.seat!=1:b.free();a.free();quit(1);return
	var state:Dictionary=fixture()
	check(not state.is_empty(),"source-backed physical Character cards selected from each 36-card deck")
	if state.is_empty():b.free();a.free();quit(1);return
	for seat in range(2):
		var p:Dictionary=state["players"][seat]
		check(p["hand"].size()+p["deck"].size()+p["discard"].size()+1==36,
			"actual physical source card conserved for seat "+str(seat))
	a.host_node.game=state
	# A and B explicitly refresh via authenticated TCP, not direct copies.
	a._send_action("PEEK")
	await wait_frames(3)
	a.peer.put_data((JSON.stringify({"type":"VIEW","token":a.token})+"\n").to_utf8_buffer())
	b.peer.put_data((JSON.stringify({"type":"VIEW","token":b.token})+"\n").to_utf8_buffer())
	await wait_frames()
	check(a.view["phase"]==4 and b.view["phase"]==4,"battle phase synchronized to both network clients")
	check(a.view["units"].size()==2 and b.view["units"].size()==2,"both see two real public combatants")
	check(a.attack_button.disabled==false,"attacker can submit declaration in first window")
	check(b.defense_button.disabled,"defender cannot respond before a declared engagement")
	check(not a.view["players"][1].has("hand") and not b.view["players"][0].has("hand"),
		"neither client's opponent hand is exposed")
	a._send_action("ATTACK",{"attacker":"ATTACKER","defender":"DEFENDER",
		"axis":"Stone","defender_spend":2})
	await wait_frames(4)
	check(int(a.view["revision"])==0,"removed one-packet ATTACK opcode rejected at transport")
	a._send_action("DECLARE_ATTACK",{"attacker":"ATTACKER","defender":"DEFENDER",
		"axis":"Stone","defender_spend":2})
	await wait_frames(4)
	check(int(a.view["revision"])==0 and int(b.view["revision"])==0,
		"attacker attempt to spend victim resources refused")
	check(int(a.host_node.game["players"][1]["sinew"])==5,"malicious client did not alter host resources")
	# M19: malformed input reaches the real transport and UI, not a mock host.
	var snapshot: String = JSON.stringify(a.host_node.game)
	for bad_revision in [0.5, -0.5, 1e30]:
		a.peer.put_data((JSON.stringify({"type":"ACTION","token":a.token,
			"action":{"type":"DECLARE_ATTACK","revision":bad_revision,
			"attacker":"ATTACKER","defender":"DEFENDER","axis":"Stone"}})+"\n").to_utf8_buffer())
		await wait_frames(4)
		check(JSON.stringify(a.host_node.game) == snapshot, "malformed revision preserves host state")
		check(a.status.text.contains("SERVER REFUSED"), "client surfaces malformed revision refusal")
	for bad_spend in [1.5, true, "1", [], {}]:
		a._send_action("DECLARE_ATTACK", {"attacker":"ATTACKER","defender":"DEFENDER",
			"axis":"Stone","attacker_spend":bad_spend})
		await wait_frames(4)
		check(JSON.stringify(a.host_node.game) == snapshot, "malformed spend preserves host state")
		check(a.status.text.contains("SERVER REFUSED"), "client surfaces malformed spend refusal")
	# Real first-window UI declaration with a resource commitment.
	a.attack_spend.select(1)
	a._attack()
	await wait_frames(8)
	check(int(a.view["revision"])==1 and int(b.view["revision"])==1,
		"both clients received same authoritative declaration revision")
	check(int(a.view["pending_attack"].get("defender_seat",-1))==1,
		"attacker sees correct public defending seat")
	check(int(b.view["pending_attack"].get("defender_seat",-1))==1,
		"defender sees mandatory response window")
	check(not b.defense_button.disabled,"defender response UI enabled in second window")
	check(b.combat_hint.text.contains("DEFEND YOUR UNIT") and b.combat_hint.text.contains("Stone"),
		"defender sees disputed axis and mandatory decision text")
	check(a.combat_hint.text.contains("WAIT FOR DEFENDER"),
		"attacker sees waiting indicator without control of opponent choice")
	check(a.defense_button.disabled,"attacker cannot use defender response UI")
	check(a.next_button.disabled and b.next_button.disabled,
		"both clients blocked from phase advance until response")
	check(a.host_node.game["players"][0]["sinew"]==5 and a.host_node.game["players"][1]["sinew"]==5,
		"no premature payment before defender consent")
	a._send_action("CHOOSE_DEFENSE",{"seat":1,"defender_spend":2})
	await wait_frames(4)
	check(int(a.host_node.game["revision"])==1,"forged target seat in attacker packet rejected")
	check(int(b.view["revision"])==1,"defender still owns unresolved choice")
	b._send_action("ADVANCE")
	await wait_frames(4)
	check(int(a.host_node.game["revision"])==1,"defender cannot bypass unresolved combat by advancing")
	# Real second-window UI response decides actual opposing resource payment.
	b.defense_spend.select(2)
	b._defend()
	await wait_frames(8)
	check(int(a.view["revision"])==2 and int(b.view["revision"])==2,
		"both clients received identical authoritative combat revision")
	check(a.view["pending_attack"].is_empty() and b.view["pending_attack"].is_empty(),
		"mandatory opponent response window cleared on both clients")
	check(a.combat_hint.text.contains("No engagement") and b.combat_hint.text.contains("No engagement"),
		"combat response indicators clear on both clients after completion")
	check(int(a.host_node.game["players"][0]["sinew"])==4,
		"attacker pays one Sinew chosen only by attacker")
	check(int(a.host_node.game["players"][1]["sinew"])==3,
		"defender pays two Sinew chosen only by defender")
	check(a.host_node.game["action_log"][-2]["type"]=="DECLARE_ATTACK",
		"attacker-owned declaration persisted as first action")
	check(a.host_node.game["action_log"][-1]["type"]=="CHOOSE_DEFENSE",
		"defender-owned commitment persisted as second action")
	check(a.host_node.game["action_log"][-1]["seat"]==1,
		"server authenticated actual defending seat")
	check(a.host_node.game["events"][-1]["type"]=="COMBAT",
		"real combat resolved after both decisions")
	check(a.view["players"][1]["sinew"]==3 and b.view["players"][0]["sinew"]==4,
		"both clients receive consistent public resource results")
	check(not a.view["players"][1].has("hand") and not b.view["players"][0].has("hand"),
		"private hand remains protected even after combat")
	var revision:int=int(a.host_node.game["revision"])
	b._send_action("CHOOSE_DEFENSE",{"defender_spend":2})
	await wait_frames(4)
	check(int(a.host_node.game["revision"])==revision,"duplicate defense cannot re-spend resources")
	b.free()
	a.free()
	print("KUDURRU_M18_LIVE_SOCKET_BATTLE passed=%d failed=%d" % [passed,failed])
	quit(0 if failed==0 else 1)
