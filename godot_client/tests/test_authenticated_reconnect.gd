extends SceneTree
const Match=preload("res://scripts/match_integrator.gd")
const Storage=preload("res://scripts/match_storage.gd")
var passed:int=0
var failed:int=0
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:
		failed+=1
		printerr("FAIL: "+label)
func wait_frames(n:int=6)->void:
	for i in range(n):await create_timer(0.04).timeout
func handshake(body:Dictionary)->Dictionary:
	var peer:=StreamPeerTCP.new()
	peer.connect_to_host("127.0.0.1",31147)
	for i in range(12):
		peer.poll()
		if peer.get_status()==StreamPeerTCP.STATUS_CONNECTED:break
		await wait_frames(1)
	peer.put_data((JSON.stringify(body)+"\n").to_utf8_buffer())
	var line:String=""
	for i in range(24):
		peer.poll()
		var count:int=peer.get_available_bytes()
		if count>0:
			var received:Array=peer.get_data(count)
			if received[0]==OK:line+=received[1].get_string_from_utf8()
		if line.contains("\n"):break
		await wait_frames(1)
	peer.disconnect_from_host()
	var result:Variant=JSON.parse_string(line.get_slice("\n",0))
	return result if typeof(result)==TYPE_DICTIONARY else {"ok":false,"error":"NO_RESPONSE"}
static func organic_battle()->Dictionary:
	var seed_value:int=13342
	var made:Dictionary=Match.create(seed_value)
	var decks:Array=made["state"]["initial_deck_ids"].duplicate(true)
	var cheap:Array=[]
	for seat in range(2):
		var id:String=""
		for card in Match._deck("BorderstoneGuild" if seat==0 else "UnderwellKeepers"):
			if card["card_family"]=="Character" and int(card["cost_sinew"])==1 and int(card["cost_sigil"])==0 and int(card["cost_oath"])==0:
				id=str(card["card_id"]);break
		assert(not id.is_empty())
		cheap.append(id)
		var positions:Array=Match._shuffle(range(36),seed_value+seat*7919)
		var desired:int=int(positions[35])
		var old:int=decks[seat].find(id)
		var swap:Variant=decks[seat][desired]
		decks[seat][desired]=id;decks[seat][old]=swap
	made=Match.create(seed_value,"BorderstoneGuild","UnderwellKeepers",decks)
	assert(made["ok"])
	var s:Dictionary=made["state"]
	var actions:Array=[{"type":"KEEP","seat":0},{"type":"KEEP","seat":1}]
	for owner in range(2):
		for i in range(3):actions.append({"type":"ADVANCE","seat":owner})
		actions.append({"type":"DEPLOY","seat":owner,"card_id":cheap[owner],"field":"Warfield"})
		for i in range(4):actions.append({"type":"ADVANCE","seat":owner})
	for i in range(4):actions.append({"type":"ADVANCE","seat":0})
	for action in actions:
		action["revision"]=s["revision"]
		var next:Dictionary=Match.apply(s,action)
		assert(next.get("ok",false),str(next))
		s=next["state"]
	return s
func _initialize()->void:call_deferred("run")
func run()->void:
	var scene:PackedScene=load("res://scenes/local_match_client.tscn")
	var a:Control=scene.instantiate();root.add_child(a);a._host_and_join(true)
	await wait_frames()
	var b:Control=scene.instantiate();root.add_child(b);b._join()
	await wait_frames()
	check(a.seat==0 and b.seat==1,"explicit JOIN authenticates two real UI seats")
	if a.seat!=0 or b.seat!=1:b.free();a.free();quit(1);return
	var host:Node=a.host_node
	check(host.recovery_keys.size()==2,"one host-owned recovery key per seat")
	a._lock_deck();await wait_frames()
	check(host.deck_lobby["ready"]==[true,false],"own deck locks before connection loss")
	var old_a:String=a.token
	var snapshot:String=JSON.stringify(host.game)
	var lobby_snapshot:String=JSON.stringify(host.deck_lobby)
	a.peer.disconnect_from_host();await wait_frames()
	check(a.awaiting_welcome and a.keep_button.disabled and a.deck_lock.disabled,"disconnected UI cannot play or change locked deck")
	a._reconnect();await wait_frames()
	check(a.seat==0 and a.token!=old_a and a.token.length()==64,"real client resumes own seat with rotated secret")
	check(JSON.stringify(host.game)==snapshot and JSON.stringify(host.deck_lobby)==lobby_snapshot,"recovery preserves exact game and locked lobby")
	check(a.view.has("lobby") and a.deck_lock.disabled,"recovered owner sees existing final lock")
	check(not a.view.has("players"),"lobby resume does not reveal undealt cards")
	var invalid:Dictionary=await handshake({"type":"RESUME","token":old_a})
	check(invalid.get("error")=="BAD_RESUME_TOKEN","rotated old token cannot resume")
	check(not invalid.has("view") and not invalid.has("token"),"refused recovery reveals no projection or secret")
	b._lock_deck();await wait_frames()
	check(not a.view.has("lobby") and not b.view.has("lobby"),"recovered lobby proceeds to selected real match")
	check(Storage.pack(host.game).get("ok",false),"actual lobby deal deterministically replays")
	# Test harness installs a source-legal state made entirely from logged real
	# actions. No client reset operation or injected cards/balances exist.
	host.game=organic_battle()
	check(Storage.pack(host.game).get("ok",false),"organic combat fixture conserves source cards and replays")
	for client in [a,b]:client.peer.put_data((JSON.stringify({"type":"VIEW","token":client.token})+"\n").to_utf8_buffer())
	await wait_frames()
	var anonymous:=StreamPeerTCP.new();anonymous.connect_to_host("127.0.0.1",31147)
	await wait_frames();anonymous.poll()
	check(anonymous.get_available_bytes()==0,"unidentified socket receives no unsolicited hand or credential")
	a._send_action("DECLARE_ATTACK",{"attacker":"REAL_1","defender":"REAL_2","axis":"Stone","attacker_spend":0})
	await wait_frames()
	check(int(host.game["pending_attack"].get("defender_seat",-1))==1,"real declaration waits for defending player")
	anonymous.poll()
	check(anonymous.get_available_bytes()==0,"unauthenticated connection receives no game broadcasts")
	for entry in host.connections:
		if int(entry["seat"])<0:entry["accepted_ms"]=Time.get_ticks_msec()-host.HANDSHAKE_TIMEOUT_MS-1
	await wait_frames(2);anonymous.poll()
	check(anonymous.get_status()!=StreamPeerTCP.STATUS_CONNECTED,"unidentified connection expires at bounded handshake deadline")
	anonymous.disconnect_from_host()
	var old_b:String=b.token
	snapshot=JSON.stringify(host.game)
	b.peer.disconnect_from_host();await wait_frames()
	check(b.awaiting_welcome and b.defense_button.disabled,"disconnected defender cannot submit stale decisions")
	a._send_action("CHOOSE_DEFENSE",{"seat":1,"defender_spend":2})
	await wait_frames(3)
	check(JSON.stringify(host.game)==snapshot,"attacker cannot spend disconnected defender resources")
	invalid=await handshake({"type":"VIEW","token":old_b})
	check(invalid.get("error")=="JOIN_OR_RESUME_REQUIRED" and not invalid.has("view"),"raw VIEW cannot bypass recovery handshake")
	for bad in [null,true,{},"forged", "a".repeat(64)]:
		invalid=await handshake({"type":"RESUME","token":bad,"seat":1})
		check(invalid.get("error")=="BAD_RESUME_TOKEN" and not invalid.has("view"),"malformed or forged resume gets no private view")
	invalid=await handshake({"type":"JOIN","seat":1})
	check(invalid.get("error")=="TWO_SEAT_LOCAL_ONLY","anonymous join cannot inherit disconnected seat")
	invalid=await handshake({"type":"RESUME","token":a.resume_token,"seat":1})
	check(invalid.get("error")=="SEAT_ALREADY_CONNECTED","duplicate active credential cannot kick current owner")
	check(JSON.stringify(host.game)==snapshot,"all rejected recovery attempts preserve exact pending decision")
	b._reconnect();await wait_frames()
	check(b.seat==1 and b.token!=old_b,"returning defender owns same seat and new secret")
	check(JSON.stringify(host.game)==snapshot,"successful reconnect does not change revision, resources, cards or pending attack")
	check(b.view["pending_attack"]["defender_seat"]==1 and not b.defense_button.disabled,"resumed UI restores pending defender consent window")
	check(not b.view["players"][0].has("hand") and not a.view["players"][1].has("hand"),"recovery keeps both opponent hands private")
	check(not b.view.has("seed") and not b.view.has("action_log") and not b.view.has("initial_deck_ids"),"resumed projection withholds host secrets and full deck lists")
	check(not b.status.text.contains(b.token) and not b.board.text.contains(b.token) and not b.status.text.contains(b.resume_token) and not b.board.text.contains(b.resume_token),"credentials are not displayed in game text")
	check(not JSON.stringify(host.game).contains(b.token) and not JSON.stringify(host.game).contains(b.resume_token),"transport credentials never enter match state or replay history")
	check(not JSON.stringify(b.view).contains(b.resume_token) and not JSON.stringify(a.view).contains(b.resume_token),"public/seat projections never contain owner recovery key")
	check(Storage.pack(host.game).get("ok",false),"pending engagement replays after transport recovery")
	b.defense_spend.select(0);b._defend();await wait_frames()
	check(host.game["pending_attack"].is_empty(),"recovered defender resolves real engagement through own UI")
	check(a.view["revision"]==b.view["revision"],"both clients synchronize resolved engagement")
	check(Storage.pack(host.game).get("ok",false),"post-reconnect combat replay and 36-card conservation pass")
	snapshot=JSON.stringify(host.game)
	var current_b:String=b.token
	b.peer.disconnect_from_host();await wait_frames()
	invalid=await handshake({"type":"RESUME","token":old_b})
	check(invalid.get("error")=="BAD_RESUME_TOKEN","old active token cannot become an owner recovery key")
	var recovery_key:String=b.resume_token
	# A genuine owner reconnects but its WELCOME is lost to that window.
	# The helper closes the replacement socket without updating b's token.
	var lost_reply:Dictionary=await handshake({"type":"RESUME","token":recovery_key,"seat":0})
	check(lost_reply.get("ok",false) and int(lost_reply.get("seat",-1))==1,"host derives recovery seat from key, ignoring packet seat")
	check(str(lost_reply.get("token",""))!=current_b,"lost reply had a fresh active connection token")
	await wait_frames(3)
	b._reconnect();await wait_frames()
	check(b.resume_token==recovery_key and b.token!=str(lost_reply.get("token","")),"owner can recover again after losing recovery reply")
	check(b.token!=current_b and b.seat==1,"second legitimate recovery rotates again without reassignment")
	check(JSON.stringify(host.game)==snapshot,"repeated reconnect remains a transport event only")
	check(host.claimed_seats.size()==2,"seat reservations remain exactly two")
	b.free();a.free()
	print("KUDURRU_M23_AUTHENTICATED_RECONNECT passed=%d failed=%d" % [passed,failed])
	quit(0 if failed==0 else 1)
