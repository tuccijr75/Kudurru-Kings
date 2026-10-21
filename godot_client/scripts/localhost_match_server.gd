extends Node
## Localhost-only authoritative 2–4 seat candidate transport. NOT internet-safe multiplayer.
## Every client action is validated by the same Godot deterministic reducer.
## Never return raw state, seed, unseen deck cards, private peeks or action log.
const Lobby = preload("res://scripts/match_deck_lobby.gd")
const Command = preload("res://scripts/match_command.gd")
const Match = preload("res://scripts/match_integrator.gd")
const Source = preload("res://scripts/real_effects.gd")
const PORT := 31147
const MAX_MESSAGE := 16384
const MAX_CONNECTIONS := 8
const MAX_MESSAGES_PER_FRAME := 8
var seat_count:int=2
const HANDSHAKE_TIMEOUT_MS := 5000
var deck_selection_enabled:bool=false
var deck_lobby:Dictionary={}
var listener := TCPServer.new()
var connections: Array = []
var claimed_seats: Dictionary = {}
var recovery_keys: Dictionary = {}
var game: Dictionary = {}
var crypto := Crypto.new()

func _ready() -> void:
	if seat_count<2 or seat_count>4:push_error("PLAYER_COUNT_2_TO_4");get_tree().quit(1);return
	if deck_selection_enabled:deck_lobby=Lobby.create(seat_count)
	var match_seed:int=crypto.generate_random_bytes(6).hex_encode().hex_to_int() if deck_selection_enabled else 8181
	var factions:Array=Match.SEAT_FACTIONS.slice(0,seat_count) if seat_count>2 else []
	var result:Dictionary=Match.create(match_seed,"BorderstoneGuild","UnderwellKeepers",[],factions)
	if not result.get("ok",false):
		push_error("LOCAL_HOST_CANDIDATE_SETUP_FAILED")
		get_tree().quit(1)
		return
	game = result["state"]
	var status:Error=listener.listen(PORT,"127.0.0.1")
	if status!=OK:
		push_error("LOCAL_HOST_PORT_NOT_AVAILABLE")
		get_tree().quit(1)
		return
	print("KUDURRU_LOCAL_MATCH_SERVER_LISTENING 127.0.0.1:%d" % PORT)

func _send(peer:StreamPeerTCP,message:Dictionary)->void:
	if peer.get_status()!=StreamPeerTCP.STATUS_CONNECTED:return
	var payload:String=JSON.stringify(message)+"\n"
	if payload.to_utf8_buffer().size()>MAX_MESSAGE:
		peer.disconnect_from_host()
		return
	peer.put_data(payload.to_utf8_buffer())

func _projection(seat:int)->Dictionary:
	if not deck_lobby.is_empty() and not deck_lobby["started"]:
		return {"mode":"LOCAL_HOST_DECK_LOBBY","lobby":Lobby.projection(deck_lobby)}
	var players:Array=[]
	for i in range(game["players"].size()):
		var p:Dictionary=game["players"][i]
		var public_player:Dictionary={"seat":i,"faction":p["faction"],"name":p["name"],
			"marks":p["marks"],"heat":p["heat"],"sinew":p["sinew"],
			"sigil":p["sigil"],"oath":p["oath"],"hand_count":p["hand"].size(),
			"deck_count":p["deck"].size(),"discard_count":p["discard"].size(),"setup_ready":p["setup_ready"]}
		if i==seat:
			public_player["hand"]=p["hand"].duplicate(true)
		players.append(public_player)
	var attack_view:Dictionary=game.get("pending_attack",{}).duplicate(true)
	var priority_view:Dictionary={}
	if not game.get("priority_queue",[]).is_empty():
		var front:Dictionary=game["priority_queue"][0]
		priority_view={"response_seat":int(front["seat"]),"source_id":front["source_id"]}
		if int(front["seat"])==seat:
			priority_view["options"]=front["options"].duplicate()
	var pending_end:Dictionary=game.get("pending_end_clause",{})
	var active_pending:bool=not pending_end.is_empty() and int(pending_end.get("seat",-1))==seat
	return {"mode":"LOCAL_HOST_PREVIEW","revision":game["revision"],
		"pending_choice":priority_view,"pending_attack":attack_view,"pending_end_discard":active_pending,
		"seat":game["seat"],"round":game["round"],"phase":game["phase"],
		"setup_complete":game["setup_complete"],"winner":game["winner"],
		"players":players,"units":game["units"].duplicate(true),
		"sites":game["sites"].duplicate(true),
		"attachments":game["attachments"].duplicate(true),
		"events":game["events"].slice(maxi(0,game["events"].size()-12))}

func _process(_delta:float)->void:
	if listener.is_connection_available():
		var peer:StreamPeerTCP=listener.take_connection()
		if connections.size()>=mini(MAX_CONNECTIONS,seat_count+4):
			_send(peer,{"ok":false,"error":"LOCAL_CONNECTION_LIMIT"})
			peer.disconnect_from_host()
		else:
			# No identity or private projection until explicit JOIN or RESUME.
			connections.append({"seat":-1,"peer":peer,"token":"","buffer":PackedByteArray(),
				"accepted_ms":Time.get_ticks_msec()})
	for entry in connections.duplicate():
		var peer:StreamPeerTCP=entry["peer"]
		peer.poll()
		if peer.get_status()!=StreamPeerTCP.STATUS_CONNECTED:
			connections.erase(entry)
			continue
		if int(entry["seat"])<0 and Time.get_ticks_msec()-int(entry["accepted_ms"])>=HANDSHAKE_TIMEOUT_MS:
			peer.disconnect_from_host()
			connections.erase(entry)
			continue
		var count:int=peer.get_available_bytes()
		if count>0:
			if count>MAX_MESSAGE or entry["buffer"].size()+count>MAX_MESSAGE:
				peer.disconnect_from_host()
				connections.erase(entry)
				continue
			var read:Array=peer.get_data(count)
			if read[0]!=OK:continue
			entry["buffer"].append_array(read[1])
		# TCP may split a UTF-8 codepoint anywhere. Decode only complete byte
		# frames, and bound both queued bytes and dispatch work per peer/frame.
		var dispatched:int=0
		while dispatched<MAX_MESSAGES_PER_FRAME:
			var newline:int=entry["buffer"].find(10)
			if newline<0:break
			var frame:PackedByteArray=entry["buffer"].slice(0,newline)
			entry["buffer"]=entry["buffer"].slice(newline+1)
			dispatched+=1
			if not _valid_utf8(frame):
				_reject_handshake(entry,"INVALID_UTF8")
				break
			_message(entry,frame.get_string_from_utf8())
			if not connections.has(entry):break

static func _valid_utf8(bytes:PackedByteArray)->bool:
	# Reject malformed wire data before Godot's decoder can emit console errors.
	var i:int=0
	while i<bytes.size():
		var first:int=bytes[i]
		if first<128:i+=1;continue
		var length:int=2 if first>=194 and first<=223 else 3 if first>=224 and first<=239 else 4 if first>=240 and first<=244 else 0
		if length==0 or i+length>bytes.size():return false
		for j in range(1,length):
			if bytes[i+j]<128 or bytes[i+j]>191:return false
		var second:int=bytes[i+1]
		if (first==224 and second<160) or (first==237 and second>159) or (first==240 and second<144) or (first==244 and second>143):return false
		i+=length
	return true

func _reject_handshake(entry:Dictionary,code:String)->void:
	_send(entry["peer"],{"ok":false,"error":code})
	entry["peer"].disconnect_from_host()
	connections.erase(entry)

func _handshake(entry:Dictionary,body:Dictionary)->void:
	var seat:int=-1
	if body.get("type")=="JOIN":
		for available in range(seat_count):
			if not claimed_seats.has(available):seat=available;break
		if seat<0:_reject_handshake(entry,"TWO_SEAT_LOCAL_ONLY" if seat_count==2 else "LOBBY_FULL");return
	elif body.get("type")=="RESUME":
		var secret:Variant=body.get("token")
		if typeof(secret)!=TYPE_STRING or secret.length()!=64:
			_reject_handshake(entry,"BAD_RESUME_TOKEN");return
		for owner in recovery_keys:
			if recovery_keys[owner]==secret:seat=int(owner);break
		if seat<0:_reject_handshake(entry,"BAD_RESUME_TOKEN");return
		for other in connections:
			if other==entry or int(other["seat"])!=seat:continue
			other["peer"].poll()
			if other["peer"].get_status()==StreamPeerTCP.STATUS_CONNECTED:
				_reject_handshake(entry,"SEAT_ALREADY_CONNECTED");return
	else:
		_reject_handshake(entry,"JOIN_OR_RESUME_REQUIRED");return
	# Claimed seats never become anonymous again. The owner recovery key
	# survives a lost WELCOME; active connection tokens rotate on every bind.
	var fresh:String=crypto.generate_random_bytes(32).hex_encode()
	claimed_seats[seat]=true
	if not recovery_keys.has(seat):recovery_keys[seat]=crypto.generate_random_bytes(32).hex_encode()
	entry["seat"]=seat
	entry["token"]=fresh
	_send(entry["peer"],{"ok":true,"type":"WELCOME","seat":seat,"token":fresh,"resume_token":recovery_keys[seat],"player_count":seat_count,
		"warning":"LOCALHOST_ONLY_NOT_PRODUCTION_NETWORK","view":_projection(seat)})

func _message(entry:Dictionary,line:String)->void:
	var peer:StreamPeerTCP=entry["peer"]
	var body:Variant=JSON.parse_string(line)
	if typeof(body)!=TYPE_DICTIONARY:
		_send(peer,{"ok":false,"error":"JSON_OBJECT_REQUIRED"})
		return
	if int(entry["seat"])<0:
		_handshake(entry,body)
		return
	if str(body.get("token",""))!=str(entry["token"]):
		_send(peer,{"ok":false,"error":"BAD_SESSION_TOKEN"})
		return
	var seat:int=int(entry["seat"])
	if body.get("type")=="VIEW":
		_send(peer,{"ok":true,"type":"VIEW","view":_projection(seat)})
		return
	if body.get("type")=="SELECT_DECK":
		if deck_lobby.is_empty():
			_send(peer,{"ok":false,"error":"DECK_SELECTION_NOT_ENABLED"})
			return
		if not Command.whole(body.get("deck_revision")):
			_send(peer,{"ok":false,"error":"DECK_REVISION_REQUIRED"})
			return
		var locked:Dictionary=Lobby.select(deck_lobby,seat,int(body["deck_revision"]),body.get("card_ids"))
		if not locked.get("ok",false):
			_send(peer,{"ok":false,"error":locked["error"]})
			return
		var next:Dictionary=locked["state"]
		if next["started"]:
			var made:Dictionary=Match.create(int(game["seed"]),"BorderstoneGuild","UnderwellKeepers",next["deck_ids"],Match.SEAT_FACTIONS.slice(0,seat_count) if seat_count>2 else [])
			if not made.get("ok",false):
				_send(peer,{"ok":false,"error":"LOCKED_DECK_SETUP_FAILED"})
				return
			game=made["state"]
		deck_lobby=next
		for client in connections:
			if int(client["seat"])<0:continue
			_send(client["peer"],{"ok":true,"type":"UPDATED","view":_projection(int(client["seat"]))})
		return
	if not deck_lobby.is_empty() and not deck_lobby["started"]:
		_send(peer,{"ok":false,"error":"BOTH_DECKS_REQUIRED"})
		return
	if body.get("type")!="ACTION" or typeof(body.get("action"))!=TYPE_DICTIONARY:
		_send(peer,{"ok":false,"error":"UNKNOWN_NETWORK_OPERATION"})
		return
	var action:Dictionary=body["action"].duplicate(true)
	if not ["KEEP","MULLIGAN","ADVANCE","DEPLOY","DECLARE_ATTACK","CHOOSE_DEFENSE","CAST","CAST_END","CLAUSE_DISCARD","CHOOSE_CONSEQUENCE","END_DISCARD","PEEK"].has(str(action.get("type",""))):
		_send(peer,{"ok":false,"error":"ACTION_NOT_ALLOWED"})
		return
	# Player ID is assigned by server, never trusted from the packet.
	action["seat"]=seat
	if not Command.whole(action.get("revision")):
		_send(peer,{"ok":false,"error":"REVISION_REQUIRED"})
		return
	action["revision"]=int(action["revision"])
	var outcome:Dictionary=Match.apply(game,action)
	if not outcome.get("ok",false):
		_send(peer,{"ok":false,"error":str(outcome.get("error","INVALID_ACTION")),
			"revision":game["revision"]})
		return
	game=outcome["state"]
	for connection in connections:
		if int(connection["seat"])<0:continue
		var receiver:Dictionary={"ok":true,"type":"UPDATED",
			"view":_projection(int(connection["seat"]))}
		# Mirror Archive peek is sent privately to the acting player only.
		if connection["seat"]==seat and outcome.has("private_card_id"):
			receiver["private_card_id"]=outcome["private_card_id"]
		_send(connection["peer"],receiver)

func _exit_tree()->void:
	listener.stop()
	for entry in connections:
		entry["peer"].disconnect_from_host()
