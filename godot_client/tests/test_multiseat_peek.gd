extends SceneTree
const Match=preload("res://scripts/match_integrator.gd")
const Storage=preload("res://scripts/match_storage.gd")
var passed:int=0
var failed:int=0
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:failed+=1;printerr("FAIL: "+label)
static func act(s:Dictionary,kind:String,owner:int,extra:Dictionary={})->Dictionary:
	return Match.apply(s,{"type":kind,"seat":owner,"revision":s["revision"]}.merged(extra,true))
static func prepared(count:int)->Dictionary:
	# Arrange real legal deck order so every owner draws physical Mirror Archive.
	var seed_value:int=2501
	var factions:Array=Match.SEAT_FACTIONS.slice(0,count)
	var made:Dictionary=Match.create(seed_value,"BorderstoneGuild","UnderwellKeepers",[],factions)
	assert(made["ok"])
	var decks:Array=made["state"]["initial_deck_ids"].duplicate(true)
	for seat in range(count):
		var remaining:Array=decks[seat].duplicate()
		remaining.erase("214")
		var ordered:Array=[];ordered.resize(36)
		var positions:Array=Match._shuffle(range(36),seed_value+seat*7919)
		ordered[positions[35]]="214"
		for i in range(36):
			if ordered[i]==null:ordered[i]=remaining.pop_front()
		decks[seat]=ordered
	var s:Dictionary=Match.create(seed_value,"BorderstoneGuild","UnderwellKeepers",decks,factions)["state"]
	for seat in range(count):s=act(s,"KEEP",seat)["state"]
	return s
func conservation(s:Dictionary,count:int)->void:
	for seat in range(count):
		var p:Dictionary=s["players"][seat]
		var total:int=p["hand"].size()+p["deck"].size()+p["discard"].size()
		for site in s["sites"]:
			if int(site["controller"])==seat:total+=1
		check(total==36,"peek conserves physical cards for seat "+str(seat))
func _initialize()->void:call_deferred("run")
func run()->void:
	for count in [2,3,4]:
		var s:Dictionary=prepared(count)
		for turn_round in [1,2]:
			for seat in range(count):
				for i in range(3):s=act(s,"ADVANCE",seat)["state"]
				if turn_round==1:
					var deployment:Dictionary=act(s,"DEPLOY",seat,{"card_id":"214","field":"Sanctuary"})
					check(deployment.get("ok",false),"source Mirror Archive deployed from real opening hand")
					if not deployment.get("ok",false):continue
					s=deployment["state"]
				var target:int=(seat+1)%count
				var expected:String=str(s["players"][target]["deck"][-1]["card_id"])
				var before:String=JSON.stringify(s)
				var nonowner:Dictionary=act(s,"PEEK",(seat+1)%count,{"target_seat":target})
				check(nonowner.get("error")=="NOT_ACTIVE_SEAT","nonowner cannot use active owner's private action")
				var peek:Dictionary=act(s,"PEEK",seat,{"target_seat":target})
				check(peek.get("ok",false),"every owner may peek in each distinct turn count=%d round=%d seat=%d"%[count,turn_round,seat])
				if not peek.get("ok",false):continue
				check(peek.get("private_card_id")==expected and peek.get("private_for_seat")==seat,"only acting owner's result carries exact top card")
				check(not JSON.stringify(peek["event"]).contains("private_card_id"),"public event does not contain private top card payload")
				check(JSON.stringify(s)==before,"peek and rejected nonowner decision preserve input")
				check(peek==act(s,"PEEK",seat,{"target_seat":target}),"same source action deterministically reproduces private result")
				s=peek["state"]
				check(act(s,"PEEK",seat,{"target_seat":target}).get("error")=="MIRROR_ALREADY_USED","same owner cannot peek twice in same turn")
				conservation(s,count)
				for i in range(4):s=act(s,"ADVANCE",seat)["state"]
			if count>2:
				var legacy:Dictionary=s.duplicate(true)
				legacy["peek_used"]={}
				for prior_round in range(1,turn_round+1):
					for prior_seat in range(count):legacy["peek_used"][str(prior_round*2+prior_seat)]=true
				var migrated:Dictionary=Storage.replay(legacy)
				if turn_round==1:
					check(migrated.get("ok",false),"exact authentic legacy multiseat peek stamps migrate")
					if migrated.get("ok",false):check(Storage._hash(migrated["state"])==Storage._hash(s),"migration reconstructs exact corrected state")
					var legacy_pack:Dictionary=Storage.pack(legacy)
					check(legacy_pack.get("ok",false),"legacy state repacks after strict replay proof")
					if legacy_pack.get("ok",false):check(Storage._hash(Storage.unpack(legacy_pack["serialized"])["state"])==Storage._hash(s),"repacked legacy state contains corrected stamp map")
					var forged:Dictionary=legacy.duplicate(true)
					forged["peek_used"]["forged"]=true
					check(not Storage.replay(forged).get("ok",false),"migration rejects extra forged stamp")
					forged=legacy.duplicate(true);forged["peek_used"].erase("2")
					check(not Storage.replay(forged).get("ok",false),"migration rejects missing historical stamp")
					forged=legacy.duplicate(true);forged["peek_used"]["2"]=1
					check(not Storage.replay(forged).get("ok",false),"migration rejects nonboolean historical stamp")
					forged=legacy.duplicate(true);forged["players"][0]["sigil"]+=1
					check(not Storage.replay(forged).get("ok",false),"migration still verifies all resource balances")
				else:check(not migrated.get("ok",false),"migration rejects trace containing peek old engine would deny")
			var packed:Dictionary=Storage.pack(s)
			check(packed.get("ok",false),"complete multi-seat peek round independently replays")
			if packed.get("ok",false):check(Storage.unpack(packed["serialized"]).get("ok",false),"peek state JSON round trip conserves and replays")
	await network()
	print("KUDURRU_M25_MULTISEAT_PEEK passed=%d failed=%d"%[passed,failed])
	quit(0 if failed==0 else 1)

func wait_frames(n:int=5)->void:
	for i in range(n):await create_timer(0.04).timeout
func network()->void:
	var count:int=4
	var s:Dictionary=prepared(count)
	for seat in range(count):
		for i in range(3):s=act(s,"ADVANCE",seat)["state"]
		s=act(s,"DEPLOY",seat,{"card_id":"214","field":"Sanctuary"})["state"]
		s=act(s,"PEEK",seat,{"target_seat":(seat+1)%count})["state"]
		for i in range(4):s=act(s,"ADVANCE",seat)["state"]
	for i in range(3):s=act(s,"ADVANCE",0)["state"]
	var scene:PackedScene=load("res://scenes/local_match_client.tscn")
	var clients:Array=[]
	for seat in range(count):
		var ui:Control=scene.instantiate();root.add_child(ui);clients.append(ui)
		if seat==0:ui._host_and_join(true,count)
		else:ui._join()
		await wait_frames()
		check(ui.seat==seat,"TCP client authenticated as actual configured seat")
		if ui.seat!=seat:
			for client in clients:client.free()
			return
	for client in clients:client._lock_deck();await wait_frames(3)
	var host:Node=clients[0].host_node
	host.game=s
	for client in clients:client.peer.put_data((JSON.stringify({"type":"VIEW","token":client.token})+"\n").to_utf8_buffer())
	await wait_frames()
	var before:String=JSON.stringify(host.game)
	clients[1]._send_action("PEEK",{"seat":0,"target_seat":3});await wait_frames()
	check(JSON.stringify(host.game)==before,"TCP opponent cannot impersonate active peek owner")
	clients[0].player_target.select(3)
	clients[0].peek_button.pressed.emit();await wait_frames()
	check(host.game["revision"]==s["revision"]+1,"existing UI private-peek action succeeds after previous-round late-seat peek")
	check(clients[0].status.text.begins_with("PRIVATE TOP CARD:"),"TCP owner receives private card through existing UI")
	for seat in range(1,count):check(not clients[seat].status.text.begins_with("PRIVATE TOP CARD:"),"TCP other seats receive no private top-card result")
	check(Storage.pack(host.game).get("ok",false),"actual TCP/UI private peek deterministically replays")
	for client in clients.slice(1):client.free()
	clients[0].free()
	await wait_frames(2)
