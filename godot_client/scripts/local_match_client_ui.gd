extends Control
const Pets = preload("res://scripts/match_pets.gd")
## Actual Godot TCP client for the two-seat loopback-only host.
## Zero player authority: private hand, priority and actions arrive from host.
## This scene is NOT a WAN/TLS/reconnect/4-seat production implementation.
const Source=preload("res://scripts/real_effects.gd")
const Match=preload("res://scripts/match_integrator.gd")
const Rules=preload("res://scripts/game_rules.gd")
const LocalHost=preload("res://scripts/localhost_match_server.gd")
const PORT:=31147
const MAX_MESSAGE:=16384
var host_node:Node
var peer:=StreamPeerTCP.new()
var incoming:String=""
var seat:int=-1
var token:String=""
var host_disconnect_reported:bool=false
var view:Dictionary={}
var status:Label
var title:Label
var summary:Label
var combat_hint:Label
var hand_list:VBoxContainer
var board:RichTextLabel
var recent:RichTextLabel
var target_unit:OptionButton
var target_permanent:OptionButton
var field_pick:OptionButton
var axis_pick:OptionButton
var attacker_pick:OptionButton
var defender_pick:OptionButton
var keep_button:Button
var mulligan_button:Button
var next_button:Button
var attack_button:Button
var defense_button:Button
var attack_spend:OptionButton
var defense_spend:OptionButton
var attack_supporter:OptionButton
var defense_supporter:OptionButton
var oath_button:Button
var exhaust_button:Button
var silence_button:Button
var peek_button:Button

func _label(parent:Node,body:String,size:int=14)->Label:
	var label:=Label.new()
	label.text=body
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",size)
	parent.add_child(label)
	return label

func _button(parent:Node,body:String,callback:Callable)->Button:
	var b:=Button.new()
	b.text=body
	b.custom_minimum_size.y=37
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _ready()->void:
	var bg:=ColorRect.new()
	bg.color=Color("#131A29")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root:=VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left=18
	root.offset_top=12
	root.offset_right=-18
	root.offset_bottom=-12
	root.add_theme_constant_override("separation",7)
	add_child(root)
	var bar:=HBoxContainer.new()
	bar.add_theme_constant_override("separation",12)
	root.add_child(bar)
	_button(bar,"BACK TO BOARD",func():get_tree().change_scene_to_file("res://scenes/main.tscn"))
	_label(bar,"TWO-SEAT LOCAL MATCH • ACTUAL HOST NETWORK",19)
	_button(bar,"HOST + JOIN (WINDOW 1)",_host_and_join)
	_button(bar,"JOIN HOST (WINDOW 2)",_join)
	status=_label(root,"LOCAL ONLY: 127.0.0.1:31147. Not internet-safe, no permanent rewards.",14)
	title=_label(root,"No match connection",18)
	summary=_label(root,"Host in the first window, join from the second game window.",14)
	combat_hint=_label(root,"No engagement awaiting a response.",14)
	var columns:=HBoxContainer.new()
	columns.size_flags_vertical=Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation",13)
	root.add_child(columns)
	var left:=VBoxContainer.new()
	left.custom_minimum_size.x=375
	columns.add_child(left)
	_label(left,"YOUR PRIVATE HAND",17)
	var scroll:=ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(370,250)
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	left.add_child(scroll)
	hand_list=VBoxContainer.new()
	hand_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(hand_list)
	_label(left,"UNIT TARGET / OPTIONAL HOST",13)
	target_unit=OptionButton.new()
	left.add_child(target_unit)
	_label(left,"SITE / RELIC TARGET",13)
	target_permanent=OptionButton.new()
	left.add_child(target_permanent)
	_label(left,"DEPLOY FIELD",13)
	field_pick=OptionButton.new()
	for field in Match.FIELD_NAMES:field_pick.add_item(field)
	left.add_child(field_pick)
	var middle:=VBoxContainer.new()
	middle.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	columns.add_child(middle)
	_label(middle,"SHARED BATTLEFIELD • PUBLIC STATE",17)
	board=RichTextLabel.new()
	board.size_flags_vertical=Control.SIZE_EXPAND_FILL
	board.custom_minimum_size.y=270
	middle.add_child(board)
	_label(middle,"BATTLE: ATTACKER / DEFENDER / AXIS",14)
	attacker_pick=OptionButton.new()
	defender_pick=OptionButton.new()
	axis_pick=OptionButton.new()
	for axis in Match.AXES:axis_pick.add_item(axis)
	middle.add_child(attacker_pick)
	middle.add_child(defender_pick)
	middle.add_child(axis_pick)
	var attacker_controls:=HBoxContainer.new()
	middle.add_child(attacker_controls)
	_label(attacker_controls,"Spend",12)
	attack_spend=OptionButton.new()
	for n in range(3):attack_spend.add_item(str(n))
	attacker_controls.add_child(attack_spend)
	attack_supporter=OptionButton.new()
	middle.add_child(attack_supporter)
	attack_button=_button(middle,"DECLARE ATTACK ? DEFENDER GETS RESPONSE",_attack)
	var defender_controls:=HBoxContainer.new()
	middle.add_child(defender_controls)
	_label(defender_controls,"Defender spend",12)
	defense_spend=OptionButton.new()
	for n in range(3):defense_spend.add_item(str(n))
	defender_controls.add_child(defense_spend)
	defense_supporter=OptionButton.new()
	middle.add_child(defense_supporter)
	defense_button=_button(middle,"SUBMIT DEFENDER-OWNED CHOICE",_defend)
	var right:=VBoxContainer.new()
	right.custom_minimum_size.x=340
	columns.add_child(right)
	_label(right,"SERVER AUTHORITATIVE ACTIONS",17)
	keep_button=_button(right,"KEEP OPENING SIX",func():_send_action("KEEP"))
	mulligan_button=_button(right,"ONE FREE MULLIGAN",func():_send_action("MULLIGAN"))
	next_button=_button(right,"ADVANCE ONE PHASE",func():_send_action("ADVANCE"))
	peek_button=_button(right,"MIRROR ARCHIVE: PRIVATE PEEK",func():_send_action("PEEK",{"target_seat":1-seat}))
	_label(right,"WHEN A RESPONSE CHOICE IS REQUIRED",13)
	oath_button=_button(right,"LOSE 2 OATH",func():_choose("LOSE_OATH"))
	exhaust_button=_button(right,"EXHAUST SELECTED UNIT",func():_choose("EXHAUST_UNIT"))
	silence_button=_button(right,"SILENCE SELECTED UNIT",func():_choose("SILENCE_UNIT"))
	_label(right,"RECENT PUBLIC EVENTS",14)
	recent=RichTextLabel.new()
	recent.size_flags_vertical=Control.SIZE_EXPAND_FILL
	recent.custom_minimum_size.y=120
	right.add_child(recent)
	_refresh()

func _host_and_join()->void:
	if host_node!=null:
		status.text="Already hosting; reconnect is not supported in this preview."
		return
	var check:=TCPServer.new()
	if check.listen(PORT,"127.0.0.1")!=OK:
		status.text="Local port already in use; use JOIN HOST."
		return
	check.stop()
	host_node=LocalHost.new()
	host_node.name="EmbeddedLocalhostAuthoritativeMatch"
	add_child(host_node)
	_join()

func _join()->void:
	if peer.get_status()==StreamPeerTCP.STATUS_CONNECTED or not token.is_empty():
		status.text="Already connected. Duplicate joins are blocked."
		return
	peer=StreamPeerTCP.new()
	incoming=""
	host_disconnect_reported=false
	var result:Error=peer.connect_to_host("127.0.0.1",PORT)
	if result!=OK:
		status.text="Cannot contact local host. Launch HOST + JOIN in first window."
		return
	status.text="Connecting to the local host; the server assigns your seat."

func _process(_delta:float)->void:
	peer.poll()
	if peer.get_status()!=StreamPeerTCP.STATUS_CONNECTED:
		if not token.is_empty() and not host_disconnect_reported:
			host_disconnect_reported=true
			status.text="Local host disconnected. End this preview and restart the host."
		return
	var available:int=peer.get_available_bytes()
	if available<=0:return
	if available>MAX_MESSAGE:
		peer.disconnect_from_host()
		status.text="Host message too large; disconnected safely."
		return
	var received:Array=peer.get_data(available)
	if received[0]!=OK:return
	incoming+=received[1].get_string_from_utf8()
	if incoming.to_utf8_buffer().size()>MAX_MESSAGE:
		peer.disconnect_from_host()
		status.text="Network buffer limit exceeded."
		return
	while incoming.contains("\n"):
		var split_at:int=incoming.find("\n")
		var line:String=incoming.substr(0,split_at)
		incoming=incoming.substr(split_at+1)
		var message:Variant=JSON.parse_string(line)
		if typeof(message)==TYPE_DICTIONARY:_received(message)
		else:status.text="Malformed server packet rejected."

func _received(msg:Dictionary)->void:
	if not bool(msg.get("ok",false)):
		status.text="SERVER REFUSED: "+str(msg.get("error","UNKNOWN"))
		return
	var kind:String=str(msg.get("type",""))
	if kind=="WELCOME":
		seat=int(msg["seat"])
		token=str(msg["token"])
		if token.length()!=64 or seat not in [0,1]:
			peer.disconnect_from_host()
			status.text="Host handshake rejected."
			return
		view=msg["view"]
		status.text="Connected as Seat %d. Localhost-only match." % seat
	elif kind=="UPDATED" or kind=="VIEW":
		view=msg["view"]
		status.text="Host confirmed revision %d." % int(view["revision"])
	else:
		status.text="Unexpected server response."
		return
	if msg.has("private_card_id"):
		var secret:Dictionary=Source.find_card(Source.catalog(),str(msg["private_card_id"]))
		status.text="PRIVATE TOP CARD: "+str(secret.get("card_name","UNKNOWN"))
	_refresh()

func _send_action(kind:String,values:Dictionary={})->void:
	if token.is_empty() or view.is_empty() or peer.get_status()!=StreamPeerTCP.STATUS_CONNECTED:
		status.text="Join the local host before playing."
		return
	var action:Dictionary={"type":kind,"revision":int(view["revision"])}
	for key in values:action[key]=values[key]
	var data:PackedByteArray=(JSON.stringify({"type":"ACTION","token":token,"action":action})+"\n").to_utf8_buffer()
	if data.size()>MAX_MESSAGE:
		status.text="Oversized action not sent."
		return
	peer.put_data(data)
	status.text="Requested "+kind+"; waiting for host decision."

func _pick_unit()->String:
	if target_unit.item_count<=0 or target_unit.selected<0:return ""
	return str(target_unit.get_item_metadata(target_unit.selected))

func _choose(option:String)->void:
	var payload:Dictionary={"choice":option}
	if option=="SILENCE_UNIT" or option=="EXHAUST_UNIT":
		payload["unit_uid"]=_pick_unit()
	_send_action("CHOOSE_CONSEQUENCE",payload)

func _attack()->void:
	if attacker_pick.selected<0 or defender_pick.selected<0:
		status.text="Choose two combatants first."
		return
	var supporter:String=""
	if attack_supporter.selected>0:supporter=str(attack_supporter.get_item_metadata(attack_supporter.selected))
	_send_action("DECLARE_ATTACK",{"attacker":str(attacker_pick.get_item_metadata(attacker_pick.selected)),
		"defender":str(defender_pick.get_item_metadata(defender_pick.selected)),
		"axis":Match.AXES[axis_pick.selected],"attacker_spend":attack_spend.selected,
		"attacker_supporter":supporter})

func _defend()->void:
	var pending:Dictionary=view.get("pending_attack",{})
	if int(pending.get("defender_seat",-1))!=seat:return
	var supporter:String=""
	if defense_supporter.selected>0:supporter=str(defense_supporter.get_item_metadata(defense_supporter.selected))
	_send_action("CHOOSE_DEFENSE",{"defender_spend":defense_spend.selected,
		"defender_supporter":supporter})

func _hand_play(index:int)->void:
	if view.is_empty() or seat<0:return
	var cards:Array=view["players"][seat].get("hand",[])
	if index<0 or index>=cards.size():return
	var c:Dictionary=cards[index]
	var id:String=str(c["card_id"])
	var prompt:Dictionary=view.get("pending_choice",{})
	if int(prompt.get("response_seat",-1))==seat and prompt.has("options"):
		var options:Array=prompt["options"]
		if options.has("DISCARD_NAME") and c["card_family"]=="Name":
			_send_action("CHOOSE_CONSEQUENCE",{"choice":"DISCARD_NAME","hand_index":index})
		elif options.has("DISCARD_CARD"):
			_send_action("CHOOSE_CONSEQUENCE",{"choice":"DISCARD_CARD","hand_index":index})
		else:status.text="That card is not a legal response."
		return
	var pending_clause:bool=bool(view.get("pending_end_discard",false))
	if pending_clause:
		_send_action("CLAUSE_DISCARD",{"hand_index":index})
		return
	var phase:int=int(view["phase"])
	if phase==6 and cards.size()>6:
		_send_action("END_DISCARD",{"hand_index":index})
		return
	if not bool(view["setup_complete"]) or int(view["seat"])!=seat:
		status.text="Not your active turn."
		return
	if phase==6 and id=="187":
		_send_action("CAST_END")
		return
	if phase==2 and c["card_family"]=="Edict":
		var payload:Dictionary={"card_id":id}
		if id in ["184","188","193"]:payload["target_uid"]=_pick_unit()
		if id=="186":
			var uid:String=_pick_unit()
			if uid.is_empty():
				status.text="Choose a unit to displace first."
				return
			payload["target_uids"]=[uid]
			var from_field:String=""
			for u in view["units"]:
				if str(u["uid"])==uid:from_field=str(u["field"]);break
			payload["destination_field"]="Sanctuary" if from_field=="Warfield" else "Warfield"
		if id=="190":payload["target_seat"]=1-seat
		if id=="185":
			if target_permanent.selected<0:
				status.text="Choose Site or Relic target."
				return
			var permanent:Dictionary=target_permanent.get_item_metadata(target_permanent.selected)
			for key in permanent:payload[key]=permanent[key]
		_send_action("CAST",payload)
		return
	if phase==3:
		var payload:Dictionary={"card_id":id,"field":Match.FIELD_NAMES[field_pick.selected]}
		if c["card_family"]=="Site":
			payload["field"]="Sanctuary" if id=="214" else "Warfield"
		if c["card_family"]=="Relic" or c["card_family"]=="Pet":
			payload["host_uid"]=_pick_unit()
		_send_action("DEPLOY",payload)
		return
	status.text="Card has no legal play action during this phase."

func _refresh()->void:
	var ready:bool=not view.is_empty() and seat in [0,1]
	keep_button.disabled=true
	mulligan_button.disabled=true
	next_button.disabled=true
	attack_button.disabled=true
	defense_button.disabled=true
	peek_button.disabled=true
	oath_button.disabled=true
	exhaust_button.disabled=true
	silence_button.disabled=true
	for child in hand_list.get_children():
		hand_list.remove_child(child)
		child.queue_free()
	target_unit.clear()
	target_permanent.clear()
	attacker_pick.clear()
	defender_pick.clear()
	attack_supporter.clear()
	attack_supporter.add_item("NO ATTACK SUPPORTER")
	defense_supporter.clear()
	defense_supporter.add_item("NO DEFENSE SUPPORTER")
	if not ready:return
	var players:Array=view["players"]
	var mine:Dictionary=players[seat]
	var other:Dictionary=players[1-seat]
	title.text="ROUND %d / %s / Host revision %d / YOU ARE SEAT %d" % [
		int(view["round"]),Rules.PHASES[int(view["phase"])],int(view["revision"]),seat]
	summary.text="You: %d Marks / S%d G%d O%d / %d hand | Opponent: %d Marks / S%d G%d O%d / %d hidden hand" % [
		int(mine["marks"]),int(mine["sinew"]),int(mine["sigil"]),int(mine["oath"]),int(mine["hand_count"]),
		int(other["marks"]),int(other["sinew"]),int(other["sigil"]),int(other["oath"]),int(other["hand_count"])]
	var prompt:Dictionary=view.get("pending_choice",{})
	var combat_pending:Dictionary=view.get("pending_attack",{})
	var defend_now:bool=int(combat_pending.get("defender_seat",-1))==seat
	if combat_pending.is_empty():
		combat_hint.text="No engagement awaiting a response."
	else:
		combat_hint.text=("%s | %s vs %s | %s axis | attacker committed %d | choose defender spend 0-2" % [
			"DEFEND YOUR UNIT" if defend_now else "WAIT FOR DEFENDER",
			str(combat_pending["attacker"]),str(combat_pending["defender"]),
			str(combat_pending["axis"]),int(combat_pending["attacker_spend"])])
	var response:bool=int(prompt.get("response_seat",-1))==seat and prompt.has("options")
	var options:Array=prompt.get("options",[])
	var active:bool=bool(view["setup_complete"]) and int(view["seat"])==seat and int(view["winner"])<0
	keep_button.disabled=bool(view["setup_complete"]) or bool(mine.get("setup_ready",false))
	mulligan_button.disabled=keep_button.disabled
	var cards:Array=mine.get("hand",[])
	var must_discard:bool=bool(view.get("pending_end_discard",false)) or (active and int(view["phase"])==6 and cards.size()>6)
	next_button.disabled=not active or response or not prompt.is_empty() or not combat_pending.is_empty() or must_discard
	defense_button.disabled=not defend_now
	oath_button.disabled=not response or not options.has("LOSE_OATH")
	exhaust_button.disabled=not response or not options.has("EXHAUST_UNIT")
	silence_button.disabled=not response or not options.has("SILENCE_UNIT")
	peek_button.disabled=not active or int(view["phase"])!=3
	for i in range(cards.size()):
		var card:Dictionary=cards[i]
		var text_value:String=(str(card["card_name"])+" / "+str(card["card_family"])+
			" S"+str(card["cost_sinew"])+" G"+str(card["cost_sigil"])+" O"+str(card["cost_oath"]))
		if response or must_discard:text_value="DISCARD CHOICE: "+text_value
		var b:Button=_button(hand_list,text_value,_hand_play.bind(i))
		b.disabled=not (response or must_discard or (active and int(view["phase"]) in [2,3,6]))
	var lines:Array=[]
	for field in Match.FIELD_NAMES:
		lines.append(field.to_upper())
		for unit in view["units"]:
			if str(unit["field"])!=field:continue
			var card:Dictionary=Source.find_card(Source.catalog(),str(unit["card_id"]))
			var info:String=str(card.get("card_name","UNKNOWN"))
			info+=" [Seat %d] %s" % [int(unit["controller"]),str(unit["uid"])]
			info+=" / DEFEATED" if unit["defeated"] else (
				" / DOWNED" if unit["downed"] else
				" / EXHAUSTED" if unit["exhausted"] else " / READY")
			lines.append(info)
			target_unit.add_item(info)
			target_unit.set_item_metadata(target_unit.item_count-1,unit["uid"])
			if int(unit["controller"])==seat and not unit["exhausted"] and not unit["downed"] and not unit["defeated"]:
				attack_supporter.add_item(info)
				attack_supporter.set_item_metadata(attack_supporter.item_count-1,unit["uid"])
				defense_supporter.add_item(info)
				defense_supporter.set_item_metadata(defense_supporter.item_count-1,unit["uid"])
				attacker_pick.add_item(info)
				attacker_pick.set_item_metadata(attacker_pick.item_count-1,unit["uid"])
			if int(unit["controller"])!=seat and not unit["downed"] and not unit["defeated"]:
				defender_pick.add_item(info)
				defender_pick.set_item_metadata(defender_pick.item_count-1,unit["uid"])
		for site in view["sites"]:
			if str(site["field"])!=field:continue
			var name:String=str(Source.find_card(Source.catalog(),str(site["card_id"])).get("card_name","SITE"))
			lines.append(name+" / Seat "+str(site["controller"]))
			if not site.get("exhausted",false):
				target_permanent.add_item(name)
				target_permanent.set_item_metadata(target_permanent.item_count-1,
					{"target_kind":"Site","target_card_id":site["card_id"],
					 "target_controller":int(site["controller"])})
	for attached in view["attachments"]:
		var record:Dictionary=Source.find_card(Source.catalog(),str(attached["card_id"]))
		lines.append(str(record.get("card_name","SUPPORT"))+" on "+str(attached["host_uid"]))
		var guard:String=Pets.guard_label(attached,int(view["round"]))
		if not guard.is_empty():lines.append(guard)
		if record.get("card_family")=="Relic" and not attached.get("exhausted",false):
			target_permanent.add_item(str(record["card_name"]))
			target_permanent.set_item_metadata(target_permanent.item_count-1,
				{"target_kind":"Relic","target_card_id":attached["card_id"],
				"target_controller":int(attached["controller"]),"target_host_uid":attached["host_uid"]})
	attack_button.disabled=not active or not combat_pending.is_empty() or int(view["phase"])!=4 or attacker_pick.item_count==0 or defender_pick.item_count==0
	board.text="\n".join(lines)
	var last:Array=[]
	for event in view["events"]:last.append(str(event))
	recent.text="\n".join(last)
