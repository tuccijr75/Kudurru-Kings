extends Control
## Explicitly sandbox-only real-card combat demo; no collectible rewards.
const Core = preload("res://scripts/real_combat_core.gd")
const FX = preload("res://scripts/real_effects.gd")
const AXES := ["Stone", "Veil", "Authority"]
var state: Dictionary = {}
var header: Label
var actor_label: Label
var target_label: Label
var message: Label
var event_log: RichTextLabel
var axis: OptionButton
var attacker_spend: SpinBox
var defender_spend: SpinBox
var use_supporter: CheckBox
var buttons: Dictionary = {}

func _label(parent: Node, value: String, font_size: int = 16) -> Label:
	var result := Label.new()
	result.text = value
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size", font_size)
	parent.add_child(result)
	return result

func _button(parent: Node, label_text: String, callback: Callable) -> Button:
	var control := Button.new()
	control.text = label_text
	control.custom_minimum_size = Vector2(180, 48)
	control.pressed.connect(callback)
	parent.add_child(control)
	return control

func _ready() -> void:
	var built: Dictionary = Core.create([["180","255"],["181","16"]], [
		Core.unit("ATTACKER", "421", 0, 0),
		Core.unit("DEFENDER", "273", 1, 0),
		Core.unit("ALLY", "407", 0, 1)], 20261020)
	if not built["ok"]:
		push_error("Combat sandbox could not initialize")
		return
	state = built["state"]
	_build()
	_refresh()

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#120A1F")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 28
	root.offset_right = -28
	root.offset_top = 16
	root.offset_bottom = -16
	root.add_theme_constant_override("separation", 12)
	add_child(root)
	var nav := HBoxContainer.new()
	root.add_child(nav)
	_button(nav, "RETURN TO BOARD", func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	_label(nav, "KUDURRU KINGS · REAL COMBAT LAB", 25)
	_label(root, "DEVELOPMENT ONLY · real Character stats, no unsupported effects, rewards, Boss combat or final outcome", 14)
	header = _label(root, "", 20)
	actor_label = _label(root, "", 16)
	target_label = _label(root, "", 16)
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 15)
	root.add_child(controls)
	axis = OptionButton.new()
	for choice in AXES: axis.add_item(choice)
	controls.add_child(axis)
	_label(controls, "Attack spend:", 14)
	attacker_spend = SpinBox.new()
	attacker_spend.min_value = 0
	attacker_spend.max_value = 2
	controls.add_child(attacker_spend)
	_label(controls, "Defend spend:", 14)
	defender_spend = SpinBox.new()
	defender_spend.min_value = 0
	defender_spend.max_value = 2
	controls.add_child(defender_spend)
	use_supporter = CheckBox.new()
	use_supporter.text = "Assign adjacent real-card supporter"
	controls.add_child(use_supporter)
	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", 11)
	actions.add_theme_constant_override("v_separation", 11)
	root.add_child(actions)
	buttons["attack"] = _button(actions, "ATTACK", _attack)
	buttons["ready"] = _button(actions, "READY (test only)", _ready_fixture)
	buttons["resolution"] = _button(actions, "ENTER RESOLUTION", _resolution)
	buttons["bind"] = _button(actions, "BIND (test evidence)", _bind)
	buttons["attempt"] = _button(actions, "ATTEMPT CAPTURE", _attempt_capture)
	buttons["decline"] = _button(actions, "DECLINE CAPTURE", _decline)
	buttons["round"] = _button(actions, "NEXT ROUND (test)", _round)
	message = _label(root, "Real-card engine ready. Test actions do not persist match progress.", 15)
	event_log = RichTextLabel.new()
	event_log.bbcode_enabled = false
	event_log.custom_minimum_size.y = 220
	event_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(event_log)

func _u(uid: String) -> Dictionary:
	var index: int = Core.find_unit(state, uid)
	if index < 0: return {}
	return state["units"][index]

func _attack() -> void:
	var chosen: String = AXES[axis.selected]
	var command: Dictionary = {"revision": int(state["revision"]), "axis": chosen,
		"attacker": "ATTACKER", "defender": "DEFENDER",
		"attacker_spend": int(attacker_spend.value),
		"defender_spend": int(defender_spend.value),
		"attacker_supporter": "ALLY" if use_supporter.button_pressed else ""}
	_accept(Core.attack(state, command), "ATTACK")

func _ready_fixture() -> void:
	if state["phase"] != "Battle": return
	var i: int = Core.find_unit(state, "ATTACKER")
	if i < 0: return
	state["units"][i]["exhausted"] = false
	var other: int = Core.find_unit(state, "ALLY")
	if other >= 0: state["units"][other]["exhausted"] = false
	message.text = "TEST SETUP ONLY: attacker and support unit readied."
	_refresh()

func _resolution() -> void:
	state["phase"] = "Resolution"
	message.text = "Resolution opened in test sandbox; capture is optional."
	_refresh()

func _bind() -> void:
	_accept(Core.mark_downed_bound(state, "DEFENDER", "TEST_SETUP_ONLY"), "BIND")

func _attempt_capture() -> void:
	_accept(Core.capture_attempt(state, 0, "DEFENDER"), "ATTEMPT")

func _decline() -> void:
	_accept(Core.decline_capture(state, 0, "DEFENDER"), "DECLINE")

func _round() -> void:
	_accept(Core.restore_defeated(state), "ROUND")

func _accept(result: Dictionary, title: String) -> void:
	if not result.get("ok", false):
		message.text = "BLOCKED: " + str(result.get("error", "UNKNOWN"))
		return
	state = result["state"]
	message.text = title + " accepted (revision %d)" % int(state["revision"])
	_refresh()

func _refresh() -> void:
	header.text = "Round %d  •  %s  •  Revision %d  •  Player Marks %d" % [
		state["round"], state["phase"], state["revision"], state["players"][0]["marks"]]
	var attacker: Dictionary = _u("ATTACKER")
	var defender: Dictionary = _u("DEFENDER")
	if not attacker.is_empty():
		var c: Dictionary = Core.card(str(attacker["card_id"]))
		actor_label.text = "Attacker: %s • Stone %d / Veil %d / Authority %d • Exhausted %s • Sinew %d" % [
			c["card_name"], c["stone"], c["veil"], c["authority"], attacker["exhausted"], state["players"][0]["sinew"]]
	else:
		actor_label.text = "Attacker restored or not on field"
	if not defender.is_empty():
		var c: Dictionary = Core.card(str(defender["card_id"]))
		target_label.text = "Defender: %s • Stone %d / Veil %d / Authority %d • Wounds %d / %s • Downed %s • Bound %s • Defeated %s" % [
			c["card_name"], c["stone"], c["veil"], c["authority"], defender["wounds"],
			c["wound_threshold"], defender["downed"], defender["bound"], defender["defeated"]]
	else:
		target_label.text = "Defeated defender returned to owner's Hand/Deck"
	buttons["attack"].disabled = state["phase"] != "Battle" or attacker.is_empty() or defender.is_empty()
	buttons["ready"].disabled = state["phase"] != "Battle"
	buttons["resolution"].disabled = state["phase"] != "Battle"
	buttons["bind"].disabled = defender.is_empty() or not bool(defender.get("downed", false))
	buttons["decline"].disabled = state["phase"] != "Resolution" or defender.is_empty() or not bool(defender.get("bound", false))
	buttons["attempt"].disabled = buttons["decline"].disabled
	var messages: Array = []
	for event in state["events"].slice(maxi(0, state["events"].size() - 8)):
		messages.append(str(event))
	event_log.text = "\n".join(messages)
