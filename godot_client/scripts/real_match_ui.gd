extends Control
## Source-backed 36-card 2-seat match candidate. NOT a certified Standard release.
const Match = preload("res://scripts/match_integrator.gd")
const Rules = preload("res://scripts/game_rules.gd")
const Source = preload("res://scripts/real_effects.gd")
const Storage = preload("res://scripts/match_storage.gd")
const Decks = preload("res://scripts/deck_registry.gd")
var state: Dictionary = {}
var headline: Label
var scoreboard: Label
var end_income_preview: Label
var status: Label
var hand_list: VBoxContainer
var board_view: RichTextLabel
var log_view: RichTextLabel
var attacker_select: OptionButton
var defender_select: OptionButton
var axis_select: OptionButton
var next_button: Button
var night_market_button: Button
var attack_button: Button
var hand_scroll: ScrollContainer
var player_faction_pick: OptionButton
var enemy_faction_pick: OptionButton
var edict_target_select: OptionButton
var permanent_target_select: OptionButton
var downed_target_select: OptionButton
var displacement_a:OptionButton
var displacement_b:OptionButton
var audit_target_pick: OptionButton
var priority_label: Label
var priority_oath_button: Button
var priority_exhaust_button: Button
var priority_silence_button: Button
var saved_deck_pick: OptionButton
var saved_deck_names: Array = []

func _label(parent: Node, title: String, size: int = 16) -> Label:
	var l := Label.new()
	l.text = title
	l.add_theme_font_size_override("font_size",size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l

func _button(parent: Node, label_text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = label_text
	b.custom_minimum_size.y = 42
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _ready() -> void:
	var result: Dictionary = Match.create()
	if not result["ok"]:
		push_error("Integrated match setup blocked: " + str(result["error"]))
		return
	state = result["state"]
	_build()
	_refresh()

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#0E101B")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 20
	root.offset_right = -20
	root.offset_top = 15
	root.offset_bottom = -15
	root.add_theme_constant_override("separation",12)
	add_child(root)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation",16)
	root.add_child(header)
	_button(header,"BACK TO BOARD",func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	_label(header,"KUDURRU KINGS  •  REAL MATCH CANDIDATE",25)
	_label(header,"LOCAL TWO-SEAT GAME • NOT STANDARD CERTIFIED • NO REWARDS",14)
	var setup_bar := HBoxContainer.new()
	setup_bar.add_theme_constant_override("separation",12)
	root.add_child(setup_bar)
	_label(setup_bar,"Your faction:",14)
	player_faction_pick = OptionButton.new()
	for faction in Match.FACTIONS: player_faction_pick.add_item(faction)
	setup_bar.add_child(player_faction_pick)
	_label(setup_bar,"Opponent faction:",14)
	enemy_faction_pick = OptionButton.new()
	for faction in Match.FACTIONS: enemy_faction_pick.add_item(faction)
	enemy_faction_pick.select(3)
	setup_bar.add_child(enemy_faction_pick)
	_button(setup_bar,"NEW GAME WITH SELECTED FACTIONS",_restart)
	var deck_bar:=HBoxContainer.new()
	deck_bar.add_theme_constant_override("separation",12)
	root.add_child(deck_bar)
	_label(deck_bar,"Your 36-card deck:",14)
	saved_deck_pick=OptionButton.new()
	saved_deck_pick.custom_minimum_size.x=365
	deck_bar.add_child(saved_deck_pick)
	_button(deck_bar,"REFRESH SAVED DECKS",_refresh_saved_decks)
	_button(deck_bar,"OPEN 754-CARD DECK BUILDER",
		func():get_tree().change_scene_to_file("res://scenes/deck_builder.tscn"))
	_refresh_saved_decks()
	headline = _label(root,"",20)
	scoreboard = _label(root,"",16)
	end_income_preview = _label(root,"",14)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation",20)
	root.add_child(columns)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 370
	columns.add_child(left)
	_label(left,"YOUR REAL-CARD HAND",19)
	hand_scroll = ScrollContainer.new()
	hand_scroll.custom_minimum_size = Vector2(350,360)
	hand_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(hand_scroll)
	hand_list = VBoxContainer.new()
	hand_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_scroll.add_child(hand_list)
	_label(left,"EDICT TARGET (MERCY / CONVOY)",13)
	edict_target_select = OptionButton.new()
	left.add_child(edict_target_select)
	_label(left,"DOWNED UNIT TARGET (CONDEMNATION)",13)
	downed_target_select=OptionButton.new()
	left.add_child(downed_target_select)
	_label(left,"EDICT PERMANENT TARGET (WRIT)",13)
	permanent_target_select=OptionButton.new()
	left.add_child(permanent_target_select)
	_label(left,"RIVER EVACUATION: FIRST UNIT / SECOND OPTIONAL",13)
	displacement_a=OptionButton.new()
	displacement_b=OptionButton.new()
	left.add_child(displacement_a)
	left.add_child(displacement_b)
	_label(left,"CENSOR AUDIT TARGET PLAYER",13)
	audit_target_pick=OptionButton.new()
	audit_target_pick.add_item("Player (you)")
	audit_target_pick.add_item("Opponent")
	audit_target_pick.select(1)
	left.add_child(audit_target_pick)
	var middle := VBoxContainer.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(middle)
	_label(middle,"BATTLEFIELDS  |  SANCTUARY + WARFIELD",19)
	board_view = RichTextLabel.new()
	board_view.bbcode_enabled = false
	board_view.custom_minimum_size.y = 240
	board_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_child(board_view)
	_label(middle,"COMBAT: SELECT TWO UNITS IN SAME FIELD",16)
	attacker_select = OptionButton.new()
	middle.add_child(attacker_select)
	defender_select = OptionButton.new()
	middle.add_child(defender_select)
	axis_select = OptionButton.new()
	for axis in Match.AXES: axis_select.add_item(axis)
	middle.add_child(axis_select)
	attack_button = _button(middle,"ATTACK (0 EXTRA RESOURCE SPEND)",_attack)
	_button(middle,"MIRROR ARCHIVE: PEEK ENEMY DECK (MAIN)",func(): _action("PEEK",{"target_seat":1}))
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 320
	columns.add_child(right)
	_label(right,"RECENT MATCH EVENTS",18)
	log_view = RichTextLabel.new()
	log_view.bbcode_enabled = false
	log_view.custom_minimum_size.y = 320
	log_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(log_view)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation",15)
	root.add_child(bar)
	next_button = _button(bar,"NEXT PHASE / END TURN",_next)
	night_market_button = _button(bar,"CAST NIGHT MARKET (END)",func():_action("CAST_END"))
	_button(bar,"SAVE LOCAL GAME",_save_game)
	_button(bar,"CONTINUE SAVED GAME",_load_game)
	var priority_bar:=HBoxContainer.new()
	priority_bar.add_theme_constant_override("separation",10)
	root.add_child(priority_bar)
	priority_label=_label(priority_bar,"",13)
	priority_oath_button=_button(priority_bar,"RESPONSE: LOSE 2 OATH",func():_choice("LOSE_OATH"))
	priority_exhaust_button=_button(priority_bar,"RESPONSE: EXHAUST UNIT",func():_choice("EXHAUST_UNIT"))
	priority_silence_button=_button(priority_bar,"RESPONSE: SILENCE UNIT",func():_choice("SILENCE_UNIT"))
	status = _label(root,"One complete pregame choice per seat. Opponent runs deterministic legal-action AI.",15)

func _refresh_saved_decks()->void:
	if saved_deck_pick==null:return
	var prior:String=""
	if saved_deck_pick.item_count>0 and saved_deck_pick.selected>=0:
		prior=str(saved_deck_names[saved_deck_pick.selected])
	saved_deck_pick.clear()
	saved_deck_names=[""]
	saved_deck_pick.add_item("AUTO SOURCE-VERIFIED STARTER")
	for name in Decks.names():
		var report:Dictionary=Decks.load(str(name))
		if not report.get("ok",false):continue
		saved_deck_names.append(name)
		saved_deck_pick.add_item(str(name)+(
			" ? PREVIEW READY" if report["report"]["effect_ready"] else " ? DESIGN ONLY"))
	var select_index:int=saved_deck_names.find(prior)
	saved_deck_pick.select(select_index if select_index>=0 else 0)

func _restart() -> void:
	var decks:Array=[]
	if saved_deck_pick.selected>0:
		var deck_name:String=str(saved_deck_names[saved_deck_pick.selected])
		var found:Dictionary=Decks.load(deck_name)
		if not found.get("ok",false):
			status.text="CUSTOM DECK INVALID: "+str(found.get("error","UNKNOWN"))
			return
		if not bool(found["report"]["effect_ready"]):
			status.text="This is a legal Standard deck, but some card effects are not implemented for match preview."
			return
		decks=[found["ids"],[]]
	var built: Dictionary = Match.create(int(state["seed"])+1,
		Match.FACTIONS[player_faction_pick.selected],Match.FACTIONS[enemy_faction_pick.selected],
		decks)
	if not built["ok"]:
		status.text = "NEW MATCH BLOCKED"
		return
	state = built["state"]
	_refresh()

func _save_game(path: String = Storage.SLOT) -> void:
	var result: Dictionary = Storage.save(state,path)
	status.text = ("Saved local game at revision "+str(state["revision"])) if result["ok"] else (
		"Save refused: "+str(result["error"]))

func _load_game(path: String = Storage.SLOT) -> void:
	var result: Dictionary = Storage.load(path)
	if not result["ok"]:
		status.text = "Cannot load local game: "+str(result["error"])
		return
	state = result["state"]
	player_faction_pick.select(Match.FACTIONS.find(str(state["players"][0]["faction"])))
	enemy_faction_pick.select(Match.FACTIONS.find(str(state["players"][1]["faction"])))
	_refresh()
	status.text = "Verified saved match restored (revision "+str(state["revision"])+")"

func _action(kind: String, parameters: Dictionary = {}) -> void:
	if state.is_empty(): return
	var args: Dictionary = {"type":kind,"seat":0,"revision":int(state["revision"])}
	for key in parameters: args[key] = parameters[key]
	var result: Dictionary = Match.apply(state,args)
	if not result["ok"]:
		status.text = "BLOCKED: "+str(result["error"])
		return
	state = result["state"]
	status.text = "PRIVATE VIEW: "+str(Source.find_card(Source.catalog(),str(result["private_card_id"]))["card_name"]) if result.has("private_card_id") else ("Action accepted: "+kind+" (revision "+str(state["revision"])+")")
	_run_opponent()
	_refresh()

func _run_opponent() -> void:
	if state.is_empty() or not state["setup_complete"] or int(state["winner"]) >= 0:return
	var steps:int=0
	while int(state["winner"])<0 and steps<90:
		var pending:Array=state.get("priority_queue",[])
		if not pending.is_empty() and int(pending[0]["seat"])!=1:break
		if pending.is_empty() and int(state["seat"])!=1:break
		var decision:Dictionary=Match.next_action(state,1)
		if decision.is_empty():
			status.text="OPPONENT PAUSED: NO LEGAL RESPONSE"
			return
		var response:Dictionary=Match.apply(state,decision)
		if not response["ok"]:
			status.text="OPPONENT PAUSED: "+str(response["error"])
			return
		state=response["state"]
		steps+=1
	if steps>=90:status.text="OPPONENT STOPPED: SAFETY ACTION BUDGET"

func _next() -> void:
	if not state.get("priority_queue",[]).is_empty():
		status.text="Resolve the outstanding opponent-choice window before advancing."
		return
	if state["setup_complete"] and int(state["phase"])==6 and int(state["seat"])==0 and state["players"][0]["hand"].size()>6:
		status.text="Choose the card(s) to discard down to six before ending the turn."
		return
	if not state["pending_end_clause"].is_empty():
		status.text="Choose one card in your hand to DISCARD before ending your turn."
		return
	if not state["setup_complete"]:
		if not state["players"][0]["setup_ready"]:
			_action("KEEP")
		elif not state["players"][1]["setup_ready"]:
			var keep: Dictionary = Match.apply(state, {"type":"KEEP","seat":1,"revision":state["revision"]})
			if keep["ok"]: state=keep["state"]
			_refresh()
		return
	_action("ADVANCE")

func _deploy(id: String, selected_index:int=-1) -> void:
	var pending:Array=state.get("priority_queue",[])
	if not pending.is_empty():
		if int(pending[0]["seat"])!=0:return
		var op:String="DISCARD_NAME" if pending[0]["options"].has("DISCARD_NAME") else "DISCARD_CARD"
		if not pending[0]["options"].has(op):return
		for i in range(state["players"][0]["hand"].size()):
			if selected_index>=0 and i!=selected_index:continue
			if str(state["players"][0]["hand"][i]["card_id"])!=id:continue
			if op=="DISCARD_NAME" and state["players"][0]["hand"][i]["card_family"]!="Name":continue
			_action("CHOOSE_CONSEQUENCE",{"choice":op,"hand_index":i})
			return
		return
	if not state["pending_end_clause"].is_empty():
		if int(state["pending_end_clause"]["seat"])!=0:return
		for i in range(state["players"][0]["hand"].size()):
			if selected_index>=0 and i!=selected_index:continue
			if str(state["players"][0]["hand"][i]["card_id"])==id:
				_action("CLAUSE_DISCARD",{"hand_index":i})
				return
		return
	if state["setup_complete"] and int(state["seat"])==0 and int(state["phase"])==6 and state["players"][0]["hand"].size()>6:
		var pick:int=selected_index
		if pick<0:
			for i in range(state["players"][0]["hand"].size()):
				if str(state["players"][0]["hand"][i]["card_id"])==id:pick=i;break
		if pick<0 or pick>=state["players"][0]["hand"].size():
			status.text="Select a valid card to discard."
			return
		_action("END_DISCARD",{"hand_index":pick})
		return
	var card: Dictionary = Source.find_card(Source.catalog(),id)
	var family: String = str(card.get("card_family",""))
	if family=="Edict":
		var parameters: Dictionary = {"card_id":id}
		if id=="184":
			if downed_target_select.item_count==0:
				status.text="Condemnation requires a Downed unit in either field."
				return
			parameters["target_uid"]=str(downed_target_select.get_item_metadata(downed_target_select.selected))
		if id=="188" or id=="193":
			if edict_target_select.item_count==0:
				status.text="A friendly Character or unit target is required."
				return
			parameters["target_uid"]=str(edict_target_select.get_item_metadata(edict_target_select.selected))
		if id=="186":
			if displacement_a.item_count<1 or displacement_a.selected<0:
				status.text="River Evacuation needs at least one unit."
				return
			var primary:String=str(displacement_a.get_item_metadata(displacement_a.selected))
			var selected_uids:Array=[primary]
			if displacement_b.selected>0:
				selected_uids.append(str(displacement_b.get_item_metadata(displacement_b.selected)))
			parameters["target_uids"]=selected_uids
			var source_field:String=""
			for unit in state["units"]:
				if str(unit["uid"])==primary:source_field=str(unit["field"]);break
			parameters["destination_field"]="Sanctuary" if source_field=="Warfield" else "Warfield"
		if id=="190":
			parameters["target_seat"]=audit_target_pick.selected
		if id=="185":
			if permanent_target_select.item_count==0:
				status.text="No eligible Site or Relic available."
				return
			var selected:Dictionary=permanent_target_select.get_item_metadata(permanent_target_select.selected)
			for key in selected:parameters[key]=selected[key]
		_action("CAST",parameters)
		return
	var parameters := {"card_id":id,"field":"Warfield"}
	if family=="Site":
		parameters["field"] = "Sanctuary" if id=="214" else "Warfield"
	elif family=="Pet" or family=="Relic":
		var host: String = ""
		for u in state["units"]:
			if int(u["controller"])==0 and not u["downed"] and not u["defeated"]:
				host = str(u["uid"])
				break
		if host.is_empty():
			status.text = "Deploy a friendly Character before attaching support."
			return
		parameters["host_uid"] = host
	_action("DEPLOY",parameters)

func _choice(choice:String)->void:
	var pending:Array=state.get("priority_queue",[])
	if pending.is_empty() or int(pending[0]["seat"])!=0:return
	var payload:Dictionary={"choice":choice}
	if choice=="EXHAUST_UNIT" or choice=="SILENCE_UNIT":
		if edict_target_select.item_count==0:
			status.text="Select a friendly unit before choosing this response."
			return
		payload["unit_uid"]=str(edict_target_select.get_item_metadata(edict_target_select.selected))
	_action("CHOOSE_CONSEQUENCE",payload)

func _attack() -> void:
	if attacker_select.item_count==0 or defender_select.item_count==0: return
	var a: String = str(attacker_select.get_item_metadata(attacker_select.selected))
	var b: String = str(defender_select.get_item_metadata(defender_select.selected))
	var axis: String = Match.AXES[axis_select.selected]
	_action("ATTACK",{"attacker":a,"defender":b,"axis":axis})

func _refresh() -> void:
	if state.is_empty(): return
	var winner: int = int(state["winner"])
	headline.text = ("WINNER: "+str(state["players"][winner]["name"])+" • 10 MARKS REACHED" if winner>=0 else
		"ROUND %d | %s | %s | Warfield holder: %s" % [
			int(state["round"]), str(state["players"][int(state["seat"])]["name"]),
			Rules.PHASES[int(state["phase"])],
			"contested" if Match._control(state)<0 else str(state["players"][Match._control(state)]["name"])])
	var stats: Array = []
	for p in state["players"]:
		stats.append("%s  |  Marks %d  |  Sinew %d  Sigil %d  Oath %d  |  Hand %d  Deck %d" % [
			p["name"],p["marks"],p["sinew"],p["sigil"],p["oath"],p["hand"].size(),p["deck"].size()])
	scoreboard.text = "\n".join(stats)
	var income:Dictionary=Match._summary_income(state,0)
	var my_ready:int=0
	var their_ready:int=0
	for unit in state["units"]:
		if not Match._ready(unit):continue
		if int(unit["controller"])==0:my_ready+=1
		else:their_ready+=1
	var owns_site:bool=false
	for site in state["sites"]:
		if int(site["controller"])==0:owns_site=true
	var owns_objective:bool=Match._control(state)==0
	end_income_preview.text="END FORECAST | Sinew: most ready %d vs %d | Sigil: Site held %s | Oath: objective held %s | +%d Sinew / +%d Sigil / +%d Oath (fallback +1 Sinew)" % [
		my_ready,their_ready,"YES" if owns_site else "NO","YES" if owns_objective else "NO",
		int(income["sinew"]),int(income["sigil"]),int(income["oath"])]
	var pending:Array=state.get("priority_queue",[])
	var human_response:bool=not pending.is_empty() and int(pending[0]["seat"])==0
	var legal:Array=pending[0]["options"] if human_response else []
	priority_label.text=("RESPONSE REQUIRED: "+str(pending[0]["source_id"])) if human_response else ""
	priority_oath_button.disabled=not legal.has("LOSE_OATH")
	priority_exhaust_button.disabled=not legal.has("EXHAUST_UNIT")
	priority_silence_button.disabled=not legal.has("SILENCE_UNIT")
	var end_overflow:bool=state["setup_complete"] and int(state["phase"])==6 and int(state["seat"])==0 and state["players"][0]["hand"].size()>6
	next_button.disabled = winner>=0 or int(state["seat"])!=0 or not state["pending_end_clause"].is_empty() or not pending.is_empty() or end_overflow
	var clause_in_hand:bool=false
	for card in state["players"][0]["hand"]:
		if str(card["card_id"])=="187":clause_in_hand=true
	night_market_button.disabled = winner>=0 or not state["setup_complete"] or int(state["seat"])!=0 or int(state["phase"])!=6 or (
		clause_in_hand==false or not state["pending_end_clause"].is_empty())
	for child in hand_list.get_children():
		hand_list.remove_child(child)
		child.queue_free()
	var discarding:bool=not state["pending_end_clause"].is_empty() and int(state["pending_end_clause"].get("seat",-1))==0
	var forced_discard:bool=human_response and (legal.has("DISCARD_CARD") or legal.has("DISCARD_NAME"))
	var name_only:bool=human_response and legal.has("DISCARD_NAME")
	var can_deploy: bool = state["setup_complete"] and winner<0 and int(state["seat"])==0 and int(state["phase"])==3
	var can_cast: bool = state["setup_complete"] and winner<0 and int(state["seat"])==0 and int(state["phase"])==2
	edict_target_select.clear()
	displacement_a.clear()
	displacement_b.clear()
	displacement_b.add_item("ONLY FIRST UNIT")
	for unit in state["units"]:
		if unit["defeated"]:continue
		var shown:Dictionary=Source.find_card(Source.catalog(),str(unit["card_id"]))
		var choice_name:String=str(shown["card_name"])+" / "+str(unit["field"])+" / "+str(unit["uid"])
		displacement_a.add_item(choice_name)
		displacement_a.set_item_metadata(displacement_a.item_count-1,str(unit["uid"]))
		displacement_b.add_item(choice_name)
		displacement_b.set_item_metadata(displacement_b.item_count-1,str(unit["uid"]))
	downed_target_select.clear()
	for unit in state["units"]:
		if not unit["downed"] or unit["defeated"]:continue
		if int(unit.get("cannot_rescue_round",-1))==int(state["round"]):continue
		var downed_card:Dictionary=Source.find_card(Source.catalog(),str(unit["card_id"]))
		downed_target_select.add_item(str(downed_card["card_name"])+
			(" / FRIENDLY" if int(unit["controller"])==0 else " / OPPONENT"))
		downed_target_select.set_item_metadata(downed_target_select.item_count-1,str(unit["uid"]))
	permanent_target_select.clear()
	for site in state["sites"]:
		if site.get("exhausted",false):continue
		var info:Dictionary={"target_kind":"Site","target_card_id":str(site["card_id"]),
			"target_controller":int(site["controller"])}
		permanent_target_select.add_item(str(Source.find_card(Source.catalog(),str(site["card_id"]))["card_name"])+
			" / Seat "+str(site["controller"]))
		permanent_target_select.set_item_metadata(permanent_target_select.item_count-1,info)
	for attached in state["attachments"]:
		if attached.get("exhausted",false):continue
		var source:Dictionary=Source.find_card(Source.catalog(),str(attached["card_id"]))
		if source.get("card_family")!="Relic":continue
		var info:Dictionary={"target_kind":"Relic","target_card_id":str(attached["card_id"]),
			"target_controller":int(attached["controller"]),"target_host_uid":str(attached["host_uid"])}
		permanent_target_select.add_item(str(source["card_name"])+" / Host "+str(attached["host_uid"]))
		permanent_target_select.set_item_metadata(permanent_target_select.item_count-1,info)
	for u in state["units"]:
		if int(u["controller"])!=0 or u["defeated"]: continue
		var target_card: Dictionary=Source.find_card(Source.catalog(),str(u["card_id"]))
		edict_target_select.add_item(str(target_card["card_name"])+" ? "+
			("EXHAUSTED" if u["exhausted"] else "READY")+" ? Wounds "+str(u["wounds"]))
		edict_target_select.set_item_metadata(edict_target_select.item_count-1,u["uid"])
	for hand_index in range(state["players"][0]["hand"].size()):
		var card:Dictionary=state["players"][0]["hand"][hand_index]
		var id: String = str(card["card_id"])
		var b: Button = _button(hand_list,("DISCARD: " if discarding or forced_discard or end_overflow else "")+str(card["card_name"])+" | "+str(card["card_family"])+
			"  S"+str(int(card["cost_sinew"]))+" G"+str(int(card["cost_sigil"]))+" O"+str(int(card["cost_oath"])),_deploy.bind(id,hand_index))
		b.disabled = (name_only and card["card_family"]!="Name") if forced_discard else (
			false if discarding or end_overflow else (
			not (can_cast if card["card_family"]=="Edict" and str(card["card_id"])!="187" else can_deploy) or
			int(card["cost_sinew"])>int(state["players"][0]["sinew"]) or
			int(card["cost_sigil"])>int(state["players"][0]["sigil"]) or
			int(card["cost_oath"])>int(state["players"][0]["oath"])))
	var lines: Array = []
	for field in Match.FIELD_NAMES:
		lines.append("═══ "+field.to_upper()+" ═══")
		for seat in range(2):
			var labels: Array = []
			for u in state["units"]:
				if u["field"]!=field or int(u["controller"])!=seat: continue
				var real: Dictionary = Source.find_card(Source.catalog(),str(u["card_id"]))
				var status_name:String="READY"
				if u["defeated"]:
					status_name="DEFEATED - return round "+str(int(u.get("defeated_round",-1))+3)
				elif u["downed"]:
					status_name="FLIPPED / DOWNED"
				elif u["exhausted"]:
					status_name="EXHAUSTED"
				labels.append(str(real["card_name"])+" ("+str(u["uid"])+
					" | Wounds "+str(u["wounds"])+
					" | "+status_name+")")
			lines.append(str(state["players"][seat]["name"])+": "+(", ".join(labels) if not labels.is_empty() else "no units"))
		for site in state["sites"]:
			if site["field"] == field:
				lines.append("Site: "+str(Source.find_card(Source.catalog(),str(site["card_id"]))["card_name"])+
					" • "+str(state["players"][int(site["controller"])]["name"]))
	board_view.text = "\n".join(lines)
	attacker_select.clear()
	defender_select.clear()
	for u in state["units"]:
		if u["downed"] or u["defeated"]: continue
		var card: Dictionary = Source.find_card(Source.catalog(),str(u["card_id"]))
		if int(u["controller"])==0 and not u["exhausted"]:
			attacker_select.add_item(str(card["card_name"])+"  | "+str(u["field"]))
			attacker_select.set_item_metadata(attacker_select.item_count-1,u["uid"])
		if int(u["controller"])==1:
			defender_select.add_item(str(card["card_name"])+"  | "+str(u["field"]))
			defender_select.set_item_metadata(defender_select.item_count-1,u["uid"])
	attack_button.disabled = winner>=0 or not state["setup_complete"] or int(state["seat"])!=0 or int(state["phase"])!=4 or (
		attacker_select.item_count==0 or defender_select.item_count==0)
	var log_lines: Array = []
	for event in state["events"].slice(maxi(0,state["events"].size()-15)):
		log_lines.append(str(event))
	log_view.text="\n".join(log_lines)
