extends SceneTree
## Transport stress fixtures only; no invented gameplay or reward events.
const Host=preload("res://scripts/localhost_match_server.gd")
var passed:int=0
var failed:int=0
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:failed+=1;printerr("FAIL: "+label)
func pause()->void:
	await create_timer(0.04).timeout
func _initialize()->void:call_deferred("run")
func run()->void:
	for valid in ["", "ASCII", "é", "漢", "🪨"]:
		check(Host._valid_utf8(valid.to_utf8_buffer()),"valid Unicode frame accepted")
	for invalid in [PackedByteArray([128]),PackedByteArray([192,128]),PackedByteArray([226,130]),PackedByteArray([237,160,128]),PackedByteArray([244,144,128,128]),PackedByteArray([255])]:
		check(not Host._valid_utf8(invalid),"invalid UTF-8 rejected before decoding")
	var host:Node=Host.new();root.add_child(host);host.set_process(false)
	var peer:=StreamPeerTCP.new();peer.connect_to_host("127.0.0.1",Host.PORT)
	for i in range(10):
		peer.poll();host._process(0.0);await pause()
	check(host.connections.size()==1,"actual TCP connection accepted")
	if host.connections.size()!=1:peer.disconnect_from_host();host.free();quit(1);return
	var before:String=JSON.stringify(host.game)
	var entry:Dictionary=host.connections[0]
	# Fragment an unknown JSON string's Unicode value in the middle of its
	# multibyte sequence. The complete JOIN must remain one valid frame.
	var join:PackedByteArray='{"type":"JOIN","note":"é"}\n'.to_utf8_buffer()
	var split:int=join.find(195)+1
	peer.put_data(join.slice(0,split));await pause();host._process(0.0)
	check(int(entry["seat"])==-1,"partial UTF-8 JOIN cannot assign a seat")
	check(entry["buffer"].size()==split,"partial UTF-8 bytes preserved exactly")
	peer.put_data(join.slice(split));await pause();host._process(0.0)
	check(int(entry["seat"])==0,"fragmented UTF-8 JOIN completes normally")
	check(entry["buffer"].is_empty(),"complete frame consumes exact buffered bytes")
	peer.poll()
	if peer.get_available_bytes()>0:peer.get_data(peer.get_available_bytes())
	var payload:String=""
	for i in range(Host.MAX_MESSAGES_PER_FRAME+3):
		payload+=JSON.stringify({"type":"VIEW","token":"wrong-token"})+"\n"
	peer.put_data(payload.to_utf8_buffer());await pause();host._process(0.0)
	check(entry["buffer"].count(10)==3,"pipelined flood dispatch capped per frame")
	host._process(0.0)
	check(entry["buffer"].is_empty(),"queued frames drain without requiring new network bytes")
	check(JSON.stringify(host.game)==before,"malformed sessions and framing never change match state")
	# Bytes, not Unicode character count, bound incomplete queued messages.
	peer.put_data("é".repeat(Host.MAX_MESSAGE/2).to_utf8_buffer());await pause();host._process(0.0)
	check(entry["buffer"].size()==Host.MAX_MESSAGE,"exact byte ceiling may wait for delimiter")
	peer.put_data("x".to_utf8_buffer());await pause();host._process(0.0)
	check(host.connections.is_empty(),"one byte beyond incomplete frame ceiling disconnects")
	check(JSON.stringify(host.game)==before,"oversized input preserves authoritative match")
	peer.disconnect_from_host()
	var malformed:=StreamPeerTCP.new();malformed.connect_to_host("127.0.0.1",Host.PORT)
	for i in range(6):
		malformed.poll();host._process(0.0);await pause()
	malformed.put_data(PackedByteArray([255,10]));await pause();host._process(0.0)
	check(host.connections.is_empty(),"invalid UTF-8 TCP frame disconnects before JSON decoding")
	check(JSON.stringify(host.game)==before,"invalid encoding does not mutate match")
	malformed.disconnect_from_host();host.free()
	# Reverse direction uses the actual client parser with a controlled local
	# TCP peer; refused packets avoid injecting fabricated gameplay views.
	var server:=TCPServer.new()
	check(server.listen(31148,"127.0.0.1")==OK,"reverse-direction TCP listener available")
	var scene:PackedScene=load("res://scenes/local_match_client.tscn")
	var client:Control=scene.instantiate();root.add_child(client);client.set_process(false)
	client.peer.connect_to_host("127.0.0.1",31148)
	for i in range(6):client.peer.poll();await pause()
	var remote:StreamPeerTCP=server.take_connection()
	var response:PackedByteArray='{ "ok":false,"error":"é漢🪨"}\n'.to_utf8_buffer()
	split=response.find(195)+1
	remote.put_data(response.slice(0,split));await pause();client._process(0.0)
	check(client.incoming.size()==split,"client retains fragmented UTF-8 bytes")
	check(not client.status.text.contains("SERVER REFUSED"),"client waits for complete response")
	remote.put_data(response.slice(split));await pause();client._process(0.0)
	check(client.status.text=="SERVER REFUSED: é漢🪨","client decodes full Unicode response exactly")
	check(client.incoming.is_empty(),"client consumes complete frame")
	var responses:=PackedByteArray()
	for i in range(Host.MAX_MESSAGES_PER_FRAME+3):responses.append_array(response)
	remote.put_data(responses);await pause();client._process(0.0)
	check(client.incoming.count(10)==3,"client dispatch budget preserves extra queued frames")
	client._process(0.0)
	check(client.incoming.is_empty(),"client queued frames drain without new input")
	remote.put_data(PackedByteArray([255,10]));await pause();client._process(0.0)
	check(client.peer.get_status()!=StreamPeerTCP.STATUS_CONNECTED,"client disconnects malformed UTF-8 host")
	check(client.status.text.contains("Malformed host encoding"),"client explains encoding refusal")
	remote.disconnect_from_host();client.free();server.stop()
	print("KUDURRU_M25_NETWORK_FRAMING passed=%d failed=%d" % [passed,failed])
	quit(0 if failed==0 else 1)
