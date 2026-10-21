extends SceneTree
const Match=preload("res://scripts/match_integrator.gd")
const Storage=preload("res://scripts/match_storage.gd")
const Edicts=preload("res://scripts/match_edicts.gd")
const Priority=preload("res://scripts/match_priority.gd")
const Combat=preload("res://scripts/real_combat_core.gd")
var passed:int=0
var failed:int=0
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:failed+=1;printerr("FAIL: "+label)
func wait_frames(n:int=6)->void:
	for i in range(n):await create_timer(0.04).timeout
static func act(s:Dictionary,kind:String,owner:int,extra:Dictionary={})->Dictionary:
	var command:Dictionary={"type":kind,"seat":owner,"revision":s["revision"]}
	for key in extra:command[key]=extra[key]
	return Match.apply(s,command)
static func prepared(count:int)->Dictionary:
	var seed_value:int=2400
	var factions:Array=Match.SEAT_FACTIONS.slice(0,count)
	var made:Dictionary=Match.create(seed_value,"BorderstoneGuild","UnderwellKeepers",[],factions)
	assert(made["ok"])
	var decks:Array=made["state"]["initial_deck_ids"].duplicate(true)
	for seat in range(count):
		var cheap:String=""
		for card in Match._deck(factions[seat]):
			if card["card_family"]=="Character" and int(card["cost_sinew"])==1 and int(card["cost_sigil"])==0 and int(card["cost_oath"])==0:cheap=str(card["card_id"]);break
		assert(not cheap.is_empty())
		var wanted:Array=[cheap,"191"]
		var remaining:Array=decks[seat].duplicate()
		var ordered:Array=[];ordered.resize(36)
		var positions:Array=Match._shuffle(range(36),seed_value+seat*7919)
		for i in range(wanted.size()):
			remaining.erase(wanted[i]);ordered[positions[35-i]]=wanted[i]
		for i in range(36):
			if ordered[i]==null:ordered[i]=remaining.pop_front()
		decks[seat]=ordered
	return Match.create(seed_value,"BorderstoneGuild","UnderwellKeepers",decks,factions)["state"]
static func battle(count:int,initial_phase:int=4)->Dictionary:
	var s:Dictionary=prepared(count)
	for seat in range(count):s=act(s,"KEEP",seat)["state"]
	for seat in range(count):
		for i in range(3):s=act(s,"ADVANCE",seat)["state"]
		var cheap:String=""
		for c in s["players"][seat]["hand"]:
			if c["card_family"]=="Character" and int(c["cost_sinew"])==1 and int(c["cost_sigil"])==0 and int(c["cost_oath"])==0:cheap=str(c["card_id"]);break
		var deployed:Dictionary=act(s,"DEPLOY",seat,{"card_id":cheap,"field":"Warfield"})
		assert(deployed["ok"],str(deployed));s=deployed["state"]
		for i in range(4):s=act(s,"ADVANCE",seat)["state"]
	for i in range(initial_phase):s=act(s,"ADVANCE",0)["state"]
	return s
static func truce_ready(count:int)->Dictionary:
	var s:Dictionary=prepared(count)
	for seat in range(count):s=act(s,"KEEP",seat)["state"]
	for i in range(2):s=act(s,"ADVANCE",0)["state"]
	return s
static func truce_battle(count:int)->Dictionary:
	# Units entered exhausted in round 1. Cast in round 2 so the final
	# attacker readies normally before its turn, while Truce is still live.
	var s:Dictionary=battle(count,2)
	s=act(s,"CAST",0,{"card_id":"191","truce_seat_a":count-2,"truce_seat_b":count-1})["state"]
	for i in range(5):s=act(s,"ADVANCE",0)["state"]
	for owner in range(1,count-1):
		for i in range(7):s=act(s,"ADVANCE",owner)["state"]
	for i in range(4):s=act(s,"ADVANCE",count-1)["state"]
	return s
func _initialize()->void:call_deferred("run")
func run()->void:
	for count in [3,4]:
		var s:Dictionary=prepared(count)
		check(s["players"].size()==count,"source-backed requested seat count")
		check(Storage.pack(s).get("ok",false),"all initial source lists reconstitute via replay")
		for seat in range(count-1):
			s=act(s,"KEEP",seat)["state"]
			check(not s["setup_complete"],"opening waits for every configured seat")
		s=act(s,"MULLIGAN",count-1)["state"]
		check(s["setup_complete"],"last owner free full mulligan completes setup")
		for seat in range(count):
			check(s["seat"]==seat and s["round"]==1,"turn follows configured order without premature round increment")
			for i in range(7):s=act(s,"ADVANCE",seat)["state"]
		check(s["seat"]==0 and s["round"]==2,"round advances only after all seats finish seven phases")
		var packed:Dictionary=Storage.pack(s)
		check(packed.get("ok",false),"full N-seat round conserves all physical cards and replays")
		if packed.get("ok",false):check(Storage.unpack(packed["serialized"]).get("ok",false),"N-seat JSON save round trip")
		var malformed:Dictionary=s.duplicate(true);malformed["players"][-1]["sinew"]=0.5
		check(not Storage.pack(malformed).get("ok",false),"extra-seat malformed balance refused")
		malformed=s.duplicate(true);malformed["seat"]=count
		check(not Storage.pack(malformed).get("ok",false),"out-of-range active seat refused")
		check(not act(s,"ADVANCE",count)["ok"],"nonexistent actor refused without access")
		s=battle(count)
		check(Storage.pack(s).get("ok",false),"every deployed combatant has logged real source origin")
		check(Match._control(s)==-1,"candidate objective tied across all seats has no owner")
		var income_case:Dictionary=s.duplicate(true)
		for unit in income_case["units"]:
			unit["exhausted"]=false
			if int(unit["controller"])!=count-1:unit["field"]="Sanctuary"
		check(Match._control(income_case)==count-1,"last seat can be unique candidate objective controller")
		check(Match._summary_income(income_case,count-1)=={"sinew":0,"sigil":0,"oath":1},"ready-count tie across seats grants no most-ready reward")
		for unit in income_case["units"]:
			if int(unit["controller"])!=count-1:unit["exhausted"]=true
		check(Match._summary_income(income_case,count-1)=={"sinew":1,"sigil":0,"oath":1},"last-seat unique ready leader gets source Sinew and objective Oath")
		var truce_state:Dictionary=truce_battle(count)
		check(Storage.pack(truce_state).get("ok",false),"organic chosen-player Truce and deployments replay")
		var blocked:Dictionary=act(truce_state,"DECLARE_ATTACK",count-1,{"attacker":"REAL_"+str(count),"defender":"REAL_"+str(count-1),"axis":"Stone"})
		check(blocked.get("error")=="FESTIVAL_TRUCE_NO_ENGAGEMENT","integrated reducer refuses selected pair's actual engagement")
		var allowed:Dictionary=act(truce_state,"DECLARE_ATTACK",count-1,{"attacker":"REAL_"+str(count),"defender":"REAL_1","axis":"Stone"})
		check(allowed.get("ok",false) and Storage.pack(allowed.get("state",{})).get("ok",false),"Truce does not block actual engagement with unselected third player")
		var before:String=JSON.stringify(s)
		var declaration:Dictionary=act(s,"DECLARE_ATTACK",0,{"attacker":"REAL_1","defender":"REAL_"+str(count),"axis":"Stone"})
		check(declaration["ok"],"first seat may engage final seat, not forced opposite-seat arithmetic")
		if declaration["ok"]:
			check(declaration["state"]["pending_attack"]["defender_seat"]==count-1,"actual target controller owns response")
			check(not act(declaration["state"],"CHOOSE_DEFENSE",1,{"defender_spend":0})["ok"],"third party cannot choose defender spend")
			var result:Dictionary=act(declaration["state"],"CHOOSE_DEFENSE",count-1,{"defender_spend":0})
			check(result["ok"] and Storage.pack(result["state"]).get("ok",false),"last-seat defense commits replayable combat")
			for neutral in range(1,count-1):check(result["state"]["players"][neutral]==s["players"][neutral],"uninvolved seat cards and balances unchanged by combat")
		check(JSON.stringify(s)==before,"declaration leaves original caller state immutable")
		# Explicit edge fixtures below test public-card effects. They are not
		# presented as organically reachable Heat or saved gameplay states.
		var edict:Dictionary=s.duplicate(true);edict["phase"]=2
		for owner in range(count):edict["players"][owner]["heat"]=owner+2
		var pair:Dictionary={"truce_seat_a":count-2,"truce_seat_b":count-1}
		var truce:Dictionary=Edicts.resolve(edict,0,"191",pair)
		check(truce["ok"],"printed Festival Truce selects two distinct players")
		if truce["ok"]:
			for owner in range(count):check(truce["state"]["players"][owner]["heat"]==edict["players"][owner]["heat"]-(1 if owner>=count-2 else 0),"only selected players receive printed Heat relief")
			check(Edicts.engagements_blocked(truce["state"],count-1,count-2),"selected pair truce works in reverse direction")
			check(not Edicts.engagements_blocked(truce["state"],0,count-1),"unselected third player is not bound by chosen pair")
		check(not Edicts.resolve(edict,0,"191",{})["ok"],"multi-seat Truce cannot silently choose a pair")
		check(not Edicts.resolve(edict,0,"191",{"truce_seat_a":1,"truce_seat_b":1})["ok"],"duplicate Truce player refused")
		check(not act(edict,"CAST",0,{"card_id":"191","truce_seat_a":0.5,"truce_seat_b":count-1})["ok"],"fractional Truce owner refused before integer conversion")
		var reckoning:Dictionary=Priority.issue(edict,0,"182",{})
		check(reckoning["ok"] and reckoning["state"]["priority_queue"].size()==count-2,"Public Reckoning queues every qualifying opponent's own choice")
	for factions in [["BorderstoneGuild"],Match.SEAT_FACTIONS+["Fateforge"],[null,"UnderwellKeepers"]]:check(not Match.create(1,"BorderstoneGuild","UnderwellKeepers",[],factions)["ok"],"invalid seat configuration refused")
	check(not Match.create(1,"BorderstoneGuild","UnderwellKeepers",[[],{},[]],Match.SEAT_FACTIONS.slice(0,3))["ok"],"malformed nested custom deck refused instead of silently defaulted")
	await network(3)
	await network(4)
	print("KUDURRU_M24_FOUR_SEAT_MATCH passed=%d failed=%d" % [passed,failed])
	quit(0 if failed==0 else 1)
func network(count:int)->void:
	var scene:PackedScene=load("res://scenes/local_match_client.tscn")
	var clients:Array=[]
	for seat in range(count):
		var ui:Control=scene.instantiate();root.add_child(ui);clients.append(ui)
		if seat==0:ui._host_and_join(true,count)
		else:ui._join()
		await wait_frames()
		check(ui.seat==seat,"real independent TCP client owns configured seat")
		if ui.seat!=seat:
			for client in clients:client.free()
			return
	var host:Node=clients[0].host_node
	for seat in range(count):
		clients[seat]._lock_deck();await wait_frames(3)
		if seat<count-1:check(clients[0].view.has("lobby"),"no network hand dealt before every player's final lock")
	await wait_frames()
	for seat in range(count):
		check(clients[seat].view.get("players",[]).size()==count,"client UI receives all public seats")
		for other in range(count):check(clients[seat].view["players"][other].has("hand")== (other==seat),"private projection reveals only authenticated owner's hand")
		check(clients[seat].summary.text.contains("Seat "+str(count-1)),"public standings include final seat")
		check(clients[seat].income_hint.text.contains("Site held") and clients[seat].income_hint.text.contains("Sinew"),"network UI shows source End income conditions")
	host.game=truce_ready(count)
	for client in clients:client.peer.put_data((JSON.stringify({"type":"VIEW","token":client.token})+"\n").to_utf8_buffer())
	await wait_frames()
	clients[0].player_target.select(count-2);clients[0].second_player.select(count-1)
	var index:int=-1
	for i in range(clients[0].view["players"][0]["hand"].size()):
		if str(clients[0].view["players"][0]["hand"][i]["card_id"])=="191":index=i;break
	check(index>=0,"source-arranged caster holds physical Festival Truce")
	if index>=0:clients[0]._hand_play(index)
	await wait_frames()
	check(host.game["truce"].get("seats",[])==[count-2,count-1],"real player selectors choose exact source Truce pair through TCP")
	check(host.game["players"][0]["sigil"]==0 and host.game["players"][count-1]["sigil"]==1,"caster pays printed cost without opponent resource control")
	check(Storage.pack(host.game).get("ok",false),"real Truce UI cast and selected players deterministically replay")
	host.game=battle(count)
	for client in clients:client.peer.put_data((JSON.stringify({"type":"VIEW","token":client.token})+"\n").to_utf8_buffer())
	await wait_frames()
	var snapshot:String=JSON.stringify(host.game)
	clients[1]._send_action("ADVANCE",{"seat":0});await wait_frames(3)
	check(JSON.stringify(host.game)==snapshot,"third-party seat forgery cannot advance active player")
	clients[0]._send_action("DECLARE_ATTACK",{"attacker":"REAL_1","defender":"REAL_"+str(count),"axis":"Stone"});await wait_frames()
	check(not clients[-1].defense_button.disabled and clients[1].defense_button.disabled,"only actual defending seat receives spend controls")
	clients[-1].peer.disconnect_from_host();await wait_frames()
	clients[-1]._reconnect();await wait_frames()
	check(clients[-1].seat==count-1 and not clients[-1].defense_button.disabled,"final seat reconnect restores its pending decision")
	clients[-1]._defend();await wait_frames()
	check(host.game["pending_attack"].is_empty() and Storage.pack(host.game).get("ok",false),"real multi-seat network defense replays and conserves 36 cards per owner")
	for client in clients:check(client.view["revision"]==host.game["revision"],"all clients converge on same authoritative revision")
	for client in clients.slice(1):client.free()
	clients[0].free()
	await wait_frames(2)
