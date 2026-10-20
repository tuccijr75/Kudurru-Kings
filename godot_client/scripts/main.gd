extends Control
## Standalone M1 development board. Buttons exercise only the verified shell controller.
## No live matches, AI, purchases, collection grants, or fabricated card stats.
const Rules = preload("res://scripts/game_rules.gd")
const GOLD = Color("#E5BC59")
const WHITE = Color("#EAE1F2")
const DIM = Color("#B9A9C4")
const BACK = Color("#100A1D")
const PANEL = Color("#1E1530")
const LINE = Color("#725028")
var state: Dictionary
var phase_labels: Array = []
var status_label: Label
var turn_label: Label
var stats_label: Label
var income_label: Label
var heat_label: Label
var north_label: Label
var west_label: Label
var east_label: Label

func _ready() -> void:
	state = Rules.new_state(["Player", "Kira", "Vex", "Nael"])
	_build_screen()
	_refresh()

func _label(value: String, size: int = 16, tint: Color = WHITE) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_color_override("font_color", tint)
	label.add_theme_font_size_override("font_size", size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _box(title: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = LINE
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	panel.add_child(body)
	body.add_child(_label(title, 18, GOLD))
	return body

func _build_screen() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = BACK
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 18
	root.offset_right = -18
	root.offset_top = 14
	root.offset_bottom = -14
	root.add_theme_constant_override("separation", 12)
	add_child(root)
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 70
	header.add_theme_constant_override("separation", 8)
	root.add_child(header)
	var logo := VBoxContainer.new()
	logo.custom_minimum_size.x = 250
	header.add_child(logo)
	logo.add_child(_label("KUDURRU KINGS", 27, GOLD))
	logo.add_child(_label("STRATEGY  •  LAW  •  LEGACY", 12, DIM))
	var phase_row := HBoxContainer.new()
	phase_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(phase_row)
	for phase_name in Rules.PHASES:
		var chip := _label(str(phase_name).to_upper(), 14, DIM)
		chip.custom_minimum_size.x = 110 if phase_name != "Resolution" else 125
		phase_row.add_child(chip)
		phase_labels.append(chip)
	var next_button := Button.new()
	next_button.text = "NEXT PHASE"
	next_button.custom_minimum_size = Vector2(155, 52)
	next_button.pressed.connect(_on_next)
	header.add_child(next_button)
	var north := _box("NORTH GATE — KIRA")
	root.add_child(north.get_parent())
	north_label = _label("")
	north.add_child(north_label)
	var board_row := HBoxContainer.new()
	board_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_row.add_theme_constant_override("separation", 12)
	root.add_child(board_row)
	var west := _box("WEST GATE — NAEL")
	west.get_parent().custom_minimum_size.x = 245
	board_row.add_child(west.get_parent())
	west_label = _label("")
	west.add_child(west_label)
	var plaza := _box("KUDURRU PLAZA")
	plaza.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_row.add_child(plaza.get_parent())
	plaza.add_child(_label("Scenario / objective data: NOT YET CERTIFIED", 19, WHITE))
	plaza.add_child(_label("Field • Lines • Geasa • Raids: planned for M4–M5", 15, DIM))
	turn_label = _label("", 22, GOLD)
	plaza.add_child(turn_label)
	status_label = _label("M1: engine foundation, not a playable match", 16, DIM)
	plaza.add_child(status_label)
	var east := _box("EAST GATE — VEX")
	east.get_parent().custom_minimum_size.x = 245
	board_row.add_child(east.get_parent())
	east_label = _label("")
	east.add_child(east_label)
	var hand := _box("YOUR HAND — CARDS LOCKED UNTIL CERTIFICATION")
	root.add_child(hand.get_parent())
	var cards := HBoxContainer.new()
	cards.custom_minimum_size.y = 160
	cards.add_theme_constant_override("separation", 12)
	hand.add_child(cards)
	for i in range(6):
		var slot := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#25103F")
		style.border_color = GOLD
		style.set_border_width_all(1)
		style.set_corner_radius_all(8)
		slot.add_theme_stylebox_override("panel", style)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cards.add_child(slot)
		var card_text := _label("KUDURRU\nKINGS\n\nSLOT %d" % (i + 1), 17, GOLD)
		card_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_child(card_text)
	var footer := HBoxContainer.new()
	footer.custom_minimum_size.y = 142
	footer.add_theme_constant_override("separation", 12)
	root.add_child(footer)
	var resources := _box("RESOURCES / END INCOME")
	footer.add_child(resources.get_parent())
	stats_label = _label("")
	resources.add_child(stats_label)
	income_label = _label("", 13, DIM)
	resources.add_child(income_label)
	var heat_panel := _box("MARKS / GLOBAL AUDIT HEAT")
	footer.add_child(heat_panel.get_parent())
	heat_label = _label("")
	heat_panel.add_child(heat_label)
	var legend := _box("BUILD GATE")
	footer.add_child(legend.get_parent())
	legend.add_child(_label("Capture: optional in Resolution", 14))
	legend.add_child(_label("No rewards or uncertified cards", 13, DIM))

func _seat_text(index: int) -> String:
	var p: Dictionary = state["players"][index]
	return "Marks %d/10  •  Heat %d\nSinew %d  /  Sigil %d  /  Oath %d\nNo field units" % [int(p["marks"]), int(p["heat"]), int(p["sinew"]), int(p["sigil"]), int(p["oath"])]

func _refresh() -> void:
	for i in range(phase_labels.size()):
		phase_labels[i].add_theme_color_override("font_color", GOLD if i == int(state["phase"]) else DIM)
	north_label.text = _seat_text(1)
	east_label.text = _seat_text(2)
	west_label.text = _seat_text(3)
	var seat: int = int(state["seat"])
	var p: Dictionary = state["players"][seat]
	turn_label.text = "Round %d  •  Seat %d (%s)\nPhase: %s" % [int(state["round"]), seat + 1, str(p["name"]), Rules.current_phase(state)]
	stats_label.text = "Sinew %d    Sigil %d    Oath %d" % [int(p["sinew"]), int(p["sigil"]), int(p["oath"])]
	var gain: Dictionary = Rules.end_income(state, seat)
	income_label.text = "Next End: +%d Sinew / +%d Sigil / +%d Oath%s" % [int(gain["sinew"]), int(gain["sigil"]), int(gain["oath"]), " (fallback)" if gain["fallback"] else ""]
	heat_label.text = "Marks: %d / 10\nAudit Heat: %d — %s" % [int(p["marks"]), int(p["heat"]), Rules.heat_tier(int(p["heat"]))]

func _on_next() -> void:
	var result: Dictionary = Rules.step(state)
	if not result["ok"]:
		status_label.text = "BLOCKED: " + str(result["error"])
		return
	state = result["state"]
	status_label.text = "M1 development shell — revision %d (no match rewards)" % int(state["revision"])
	_refresh()
