extends Node
## Localhost-only authoritative 2-seat match transport. NOT internet-safe multiplayer.
## Every client action is validated by the same Godot deterministic reducer.
## Never return raw state, seed, unseen deck cards, private peeks or action log.
const Match = preload("res://scripts/match_integrator.gd")
const Source = preload("res://scripts/real_effects.gd")
const PORT := 31147
const MAX_MESSAGE := 16384
const MAX_CLIENTS := 2
var listener := TCPServer.new()
var connections: Array = []
var game: Dictionary = {}
var crypto := Crypto.new()

func _ready() -> void:
	var result:Dictionary=Match.create(8181)
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
	var players:Array=[]
	for i in range(game["players"].size()):
		var p:Dictionary=game["players"][i]
		var public_player:Dictionary={"seat":i,"faction":p["faction"],"name":p["name"],
			"marks":p["marks"],"heat":p["heat"],"sinew":p["sinew"],
			"sigil":p["sigil"],"oath":p["oath"],"hand_count":p["hand"].size(),
			"deck_count":p["deck"].size(),"discard_count":p["discard"].size()}
		if i==seat:
			public_player["hand"]=p["hand"].duplicate(true)
		players.append(public_player)
	var priority_view:Dictionary={}
	if not game.get("priority_queue",[]).is_empty():
		var front:Dictionary=game["priority_queue"][0]
		priority_view={"response_seat":int(front["seat"]),"source_id":front["source_id"]}
		if int(front["seat"])==seat:
			priority_view["options"]=front["options"].duplicate()
	return {"mode":"LOCAL_HOST_PREVIEW","revision":game["revision"],
		"pending_choice":priority_view,
		"seat":game["seat"],"round":game["round"],"phase":game["phase"],
		"setup_complete":game["setup_complete"],"winner":game["winner"],
		"players":players,"units":game["units"].duplicate(true),
		"sites":game["sites"].duplicate(true),
		"attachments":game["attachments"].duplicate(true),
		"events":game["events"].slice(maxi(0,game["events"].size()-12))}

func _process(_delta:float)->void:
	if listener.is_connection_available():
		var peer:StreamPeerTCP=listener.take_connection()
		if connections.size()>=MAX_CLIENTS:
			_send(peer,{"ok":false,"error":"TWO_SEAT_LOCAL_ONLY"})
			peer.disconnect_from_host()
		else:
			var seat:int=connections.size()
			var token:String=crypto.generate_random_bytes(32).hex_encode()
			connections.append({"seat":seat,"peer":peer,"token":token,"buffer":""})
			_send(peer,{"ok":true,"type":"WELCOME","seat":seat,"token":token,
				"warning":"LOCALHOST_ONLY_NOT_PRODUCTION_NETWORK","view":_projection(seat)})
	for entry in connections.duplicate():
		var peer:StreamPeerTCP=entry["peer"]
		peer.poll()
		if peer.get_status()!=StreamPeerTCP.STATUS_CONNECTED:
			connections.erase(entry)
			continue
		var count:int=peer.get_available_bytes()
		if count<=0: continue
		if count>MAX_MESSAGE:
			peer.disconnect_from_host()
			connections.erase(entry)
			continue
		var read: Array=peer.get_data(count)
		if read[0]!=OK:continue
		var packet:PackedByteArray=read[1]
		entry["buffer"]+=packet.get_string_from_utf8()
		if entry["buffer"].length()>MAX_MESSAGE:
			peer.disconnect_from_host()
			connections.erase(entry)
			continue
		while entry["buffer"].contains("\n"):
			var newline:int=entry["buffer"].find("\n")
			var line:String=entry["buffer"].substr(0,newline)
			entry["buffer"]=entry["buffer"].substr(newline+1)
			_message(entry,line)

func _message(entry:Dictionary,line:String)->void:
	var peer:StreamPeerTCP=entry["peer"]
	var body:Variant=JSON.parse_string(line)
	if typeof(body)!=TYPE_DICTIONARY:
		_send(peer,{"ok":false,"error":"JSON_OBJECT_REQUIRED"})
		return
	if str(body.get("token",""))!=str(entry["token"]):
		_send(peer,{"ok":false,"error":"BAD_SESSION_TOKEN"})
		return
	var seat:int=int(entry["seat"])
	if body.get("type")=="VIEW":
		_send(peer,{"ok":true,"type":"VIEW","view":_projection(seat)})
		return
	if body.get("type")!="ACTION" or typeof(body.get("action"))!=TYPE_DICTIONARY:
		_send(peer,{"ok":false,"error":"UNKNOWN_NETWORK_OPERATION"})
		return
	var action:Dictionary=body["action"].duplicate(true)
	if not ["KEEP","MULLIGAN","ADVANCE","DEPLOY","ATTACK","CAST","CAST_END","CLAUSE_DISCARD","CHOOSE_CONSEQUENCE","END_DISCARD","PEEK"].has(str(action.get("type",""))):
		_send(peer,{"ok":false,"error":"ACTION_NOT_ALLOWED"})
		return
	# Player ID is assigned by server, never trusted from the packet.
	action["seat"]=seat
	if typeof(action.get("revision")) not in [TYPE_INT,TYPE_FLOAT]:
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
