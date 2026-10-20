extends Control
## Browse all 754 REAL source cards. Only twelve source-pinned effects can be tested.
## This is NOT a match, a deck builder, or a card-acquisition interface.
const FX = preload("res://scripts/real_effects.gd")
const BG = Color("#120B20")
const GOLD = Color("#E6BD63")
const PANEL = Color("#211532")
var card_data: Dictionary = {}
var filtered: Array = []
var selected: Dictionary = {}
var lab_state: Dictionary = {}
var page: int = 0
var search: LineEdit
var list_container: VBoxContainer
var counter: Label
var headline: Label
var details: RichTextLabel
var outcome: RichTextLabel
var cast_button: Button
var prev_button: Button
var next_button: Button

func _label(parent: Node, value: String, font_size: int = 16, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l

func _button(parent: Node, title: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = title
	b.custom_minimum_size.y = 41
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _panel(parent: Node) -> VBoxContainer:
	var wrapper := PanelContainer.new()
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = Color("#74542A")
	style.set_border_width_all(1)
	style.set_content_margin_all(12)
	style.set_corner_radius_all(8)
	wrapper.add_theme_stylebox_override("panel", style)
	parent.add_child(wrapper)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	wrapper.add_child(box)
	return box

func _ready() -> void:
	card_data = FX.catalog()
	if card_data.is_empty():
		push_error("Real source catalog could not be validated")
		return
	var s: Dictionary = FX.sandbox()
	if not s["ok"]:
		push_error("Real effect bench cannot initialize")
		return
	lab_state = s["state"]
	_build()
	_filter("")

func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = BG
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 24
	root.offset_right = -24
	root.offset_top = 18
	root.offset_bottom = -18
	root.add_theme_constant_override("separation", 12)
	add_child(root)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 20)
	root.add_child(top)
	_button(top, "RETURN TO BOARD", func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	_label(top, "KUDURRU KINGS · REAL CARD LIBRARY", 25, GOLD)
	_label(top, "754 SOURCE CARDS  ·  12 EFFECTS IN SANDBOX  ·  0 IN RELEASE", 14)
	var main := HBoxContainer.new()
	main.add_theme_constant_override("separation", 16)
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(main)
	var left: VBoxContainer = _panel(main)
	left.get_parent().custom_minimum_size.x = 450
	left.get_parent().size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_label(left, "FILTER ACTUAL CARD DATA", 18, GOLD)
	search = LineEdit.new()
	search.placeholder_text = "Name, card ID, family or faction"
	search.text_changed.connect(_filter)
	left.add_child(search)
	counter = _label(left, "", 14)
	list_container = VBoxContainer.new()
	list_container.add_theme_constant_override("separation", 4)
	left.add_child(list_container)
	var pagination := HBoxContainer.new()
	left.add_child(pagination)
	prev_button = _button(pagination, "PREVIOUS", func(): _turn_page(-1))
	next_button = _button(pagination, "NEXT", func(): _turn_page(1))
	var right: VBoxContainer = _panel(main)
	_label(right, "CARD SOURCE / EFFECT IMPLEMENTATION", 18, GOLD)
	headline = _label(right, "", 23, GOLD)
	details = RichTextLabel.new()
	details.bbcode_enabled = false
	details.fit_content = false
	details.scroll_active = true
	details.custom_minimum_size.y = 260
	details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(details)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 14)
	right.add_child(actions)
	cast_button = _button(actions, "TEST VERIFIED SOURCE EFFECT", _on_test_effect)
	_button(actions, "RESET EFFECT TEST BENCH", _reset_bench)
	_label(right, "The effect bench provides fixed test targets. It does not run a Standard match.", 14)
	outcome = RichTextLabel.new()
	outcome.bbcode_enabled = false
	outcome.custom_minimum_size.y = 118
	right.add_child(outcome)
	outcome.text = "Select a card. Source-only effects remain explicitly unavailable."

func _filter(query: String) -> void:
	if card_data.is_empty(): return
	filtered.clear()
	var needle: String = query.strip_edges().to_lower()
	for c in card_data["cards"]:
		var text: String = "%s %s %s %s %s" % [
			c["card_id"], c["card_name"], c["card_family"], c["display_faction"], c["rarity"]]
		if needle.is_empty() or text.to_lower().contains(needle):
			filtered.append(c)
	page = 0
	_redraw_page()

func _turn_page(direction: int) -> void:
	page = clampi(page + direction, 0, maxi(0, int(ceili(float(filtered.size()) / 16.0)) - 1))
	_redraw_page()

func _redraw_page() -> void:
	for node in list_container.get_children(): node.queue_free()
	var pages: int = maxi(1, int(ceili(float(filtered.size()) / 16.0)))
	counter.text = "%d matches · page %d of %d" % [filtered.size(), page + 1, pages]
	prev_button.disabled = page == 0
	next_button.disabled = page >= pages - 1
	for i in range(page * 16, mini((page + 1) * 16, filtered.size())):
		var c: Dictionary = filtered[i]
		var label: String = "#%s %s  /  %s" % [
			str(c["card_id"]), str(c["card_name"]), str(c["card_family"])]
		var b := _button(list_container, label, _select.bind(c))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if filtered.size() > 0:
		_select(filtered[page * 16])
	else:
		selected = {}
		headline.text = "No matching cards"
		details.text = ""
		cast_button.disabled = true

func _select(card: Dictionary) -> void:
	selected = card
	headline.text = "%s — %s" % [str(card["card_id"]), str(card["card_name"])]
	var status: String = "SANDBOX EFFECT IMPLEMENTED" if bool(card["sandbox_effect_implemented"]) else "EFFECT NOT IMPLEMENTED"
	details.text = "%s / %s / %s\n" % [card["card_family"], card["rarity"], card["display_faction"]]
	details.text += "EOE provenance: %s\n" % card["faction_provenance"]
	details.text += "Deploy Sinew %d   Sigil %d   Oath %d\n" % [
		int(card["cost_sinew"]), int(card["cost_sigil"]), int(card["cost_oath"])]
	details.text += "Stone %d   Veil %d   Authority %d\n" % [
		int(card["stone"]), int(card["veil"]), int(card["authority"])]
	details.text += "Timing: %s   Runtime status: %s\n" % [card["play_timing"], status]
	details.text += "Production-playable: NO\n\n"
	details.text += "ORIGINAL RULES TEXT\n%s" % card["rules_text"]
	cast_button.disabled = not bool(card["sandbox_effect_implemented"])
	outcome.text = "Selected source card: " + str(card["card_name"])

func _reset_bench() -> void:
	var start: Dictionary = FX.sandbox()
	lab_state = start["state"]
	outcome.text = "Effect test state reset. Source records unchanged."

func _on_test_effect() -> void:
	if selected.is_empty() or not bool(selected["sandbox_effect_implemented"]): return
	var id: String = str(selected["card_id"])
	var args: Dictionary = {}
	match id:
		"180", "193": args = {"uid": "BOSS0"}
		"184": args = {"uid": "DOWNED1"}
		"185": args = {"uid": "SITE1"}
		"187":
			var hand: Array = lab_state["players"][0]["hand"]
			for value in hand:
				if value != id:
					args = {"discard_card_id": value}
					break
			if args.is_empty(): args = {"discard_card_id": lab_state["players"][0]["deck"][-1]}
		"191": args = {"first_player": 0, "second_player": 1}
	lab_state["phase"] = "End" if id == "187" else str(selected["play_timing"])
	var before_heat: int = int(lab_state["players"][0]["heat"])
	var result: Dictionary = FX.cast(lab_state, {"seat": 0, "revision": lab_state["revision"],
		"card_id": id, "args": args})
	if not result["ok"]:
		outcome.text = "Effect blocked: %s. Reset if already used." % str(result["error"])
		return
	lab_state = result["state"]
	var effect: String = "RESOLVED REAL CARD: %s\nPaid: %s\nHeat %d → %d" % [
		selected["card_name"], str(result["event"]["paid"]), before_heat,
		int(lab_state["players"][0]["heat"])]
	if id == "199":
		var extra: Dictionary = FX.upkeep_failed(lab_state, 1)
		lab_state = extra["state"]
		effect += "\nBroken Oath: opponent failed Oath upkeep, heat +1."
	if id == "207":
		var silence: Dictionary = FX.apply_silence(lab_state, "DOWNED1")
		lab_state = silence["state"]
		effect += "\nFirst Silence replaced with: " + str(silence["event"]["status"])
	if id == "214":
		var uid: String = lab_state["permanents"][-1]["uid"]
		var peek: Dictionary = FX.peek(lab_state, 0, uid, 1)
		if peek["ok"]:
			lab_state = peek["state"]
			effect += "\nPRIVATE ONLY — opponent top card ID: " + str(peek["private_top_card_id"])
	if id == "216":
		effect += "\nStone attack modifier in Warfield: +" + str(FX.stone_attack_modifier(lab_state, 0, "Warfield", "Stone", true))
	if id == "191":
		effect += "\nEngagement permitted between chosen pair: " + str(FX.can_engage(lab_state, 0, 1))
	outcome.text = effect
