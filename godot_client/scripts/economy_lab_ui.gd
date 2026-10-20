extends Control
## Local economic laboratory: fictional fixture cards, no real effects or rewards.
const Match = preload("res://scripts/dev_match.gd")
const Rules = preload("res://scripts/game_rules.gd")
var state: Dictionary = {}
var headline: Label
var notice: Label
var field_view: Label
var seat_views: Array = []
var card_buttons: Array = []
var keep_button: Button
var mulligan_button: Button
var advance_button: Button

func _label(parent: Node, message: String, size: int = 16) -> Label:
	var l := Label.new()
	l.text = message
	l.add_theme_font_size_override("font_size", size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l

func _button(parent: Node, message: String, pressed: Callable) -> Button:
	var b := Button.new()
	b.text = message
	b.custom_minimum_size.y = 48
	b.pressed.connect(pressed)
	parent.add_child(b)
	return b

func _ready() -> void:
	var built: Dictionary = Match.create(["Player", "Kira", "Vex", "Nael"], 20261020)
	if not built["ok"]:
		push_error("Economy lab unavailable: " + str(built["error"]))
		return
	state = built["state"]
	_build()
	_refresh()

func _build() -> void:
	var back := ColorRect.new()
	back.color = Color("#100A1D")
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 24
	root.offset_top = 18
	root.offset_right = -24
	root.offset_bottom = -18
	root.add_theme_constant_override("separation", 14)
	add_child(root)
	_label(root, "KUDURRU KINGS  /  ECONOMIC LAB", 28)
	_label(root, "DEVELOPMENT ONLY  |  754 REAL CARDS LOCKED  |  NO ABILITY RESOLUTION, SCORING, OR REWARDS", 15)
	var seats := HBoxContainer.new()
	seats.add_theme_constant_override("separation", 16)
	root.add_child(seats)
	for i in range(4):
		var l := _label(seats, "", 15)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		seat_views.append(l)
	headline = _label(root, "", 22)
	field_view = _label(root, "", 16)
	field_view.custom_minimum_size.y = 120
	notice = _label(root, "Each player chooses Keep or Mulligan before the first turn.", 15)
	_label(root, "FIXTURE HAND: SELECT A CHARACTER OR SITE IN MAIN", 18)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	row.custom_minimum_size.y = 154
	root.add_child(row)
	for i in range(6):
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(150, 145)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.pressed.connect(_on_card.bind(i))
		row.add_child(slot)
		card_buttons.append(slot)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	root.add_child(actions)
	keep_button = _button(actions, "KEEP SIX", func(): _dispatch("KEEP"))
	mulligan_button = _button(actions, "FREE MULLIGAN", func(): _dispatch("MULLIGAN"))
	advance_button = _button(actions, "NEXT PHASE", func(): _dispatch("ADVANCE"))
	_button(actions, "RETURN TO BOARD", func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))

func _acting_seat() -> int:
	if bool(state["setup_complete"]): return int(state["seat"])
	for i in range(state["setup_ready"].size()):
		if not bool(state["setup_ready"][i]): return i
	return 0

func _dispatch(kind: String, extra: Dictionary = {}) -> void:
	var action: Dictionary = {"type": kind, "seat": _acting_seat(),
		"revision": int(state["revision"])}
	for key in extra: action[key] = extra[key]
	var outcome: Dictionary = Match.apply(state, action)
	if not outcome["ok"]:
		notice.text = "BLOCKED: " + str(outcome["error"])
		return
	state = outcome["state"]
	notice.text = kind + " accepted. Event revision " + str(state["revision"])
	_refresh()

func _on_card(index: int) -> void:
	if not bool(state["setup_complete"]): return
	var player: Dictionary = state["players"][int(state["seat"])]
	if index < player["hand"].size():
		_dispatch("DEPLOY", {"card_id": player["hand"][index]["card_id"]})

func _refresh() -> void:
	var in_setup: bool = not bool(state["setup_complete"])
	var seat: int = _acting_seat()
	var player: Dictionary = state["players"][seat]
	headline.text = ("SETUP: SEAT %d CHOOSE KEEP OR MULLIGAN" % (seat + 1)) if in_setup else (
		"ROUND %d  /  SEAT %d  /  %s" % [state["round"], seat + 1, Rules.current_phase(state)])
	keep_button.disabled = not in_setup
	mulligan_button.disabled = not in_setup
	advance_button.disabled = in_setup
	var rows: Array = []
	for i in range(4):
		var p: Dictionary = state["players"][i]
		seat_views[i].text = "%s  [%s]\nS:%d G:%d O:%d\nHand:%d Deck:%d Field:%d" % [
			p["name"], p["faction"], p["sinew"], p["sigil"], p["oath"],
			p["hand"].size(), p["deck"].size(), p["field"].size()]
		rows.append("%s: %d deployed fixture(s)" % [p["name"], p["field"].size()])
	field_view.text = "FIELD STATE\n" + "\n".join(rows)
	for i in range(card_buttons.size()):
		var slot: Button = card_buttons[i]
		if i >= player["hand"].size():
			slot.text = "EMPTY"
			slot.disabled = true
			continue
		var card: Dictionary = player["hand"][i]
		slot.text = "%s #%d\nS%d  G%d  O%d" % [
			card["card_family"], i + 1,
			card["cost_sinew"], card["cost_sigil"], card["cost_oath"]]
		slot.disabled = in_setup or Rules.current_phase(state) != "Main" or (
			not Match.ALLOWED_DEPLOY.has(card["card_family"])) or (
			int(card["cost_sinew"]) > int(player["sinew"]) or
			int(card["cost_sigil"]) > int(player["sigil"]) or
			int(card["cost_oath"]) > int(player["oath"]))
