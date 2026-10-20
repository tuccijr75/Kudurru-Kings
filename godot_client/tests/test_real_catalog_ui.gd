extends SceneTree
const FX = preload("res://scripts/real_effects.gd")
var passed := 0
var failed := 0

func _check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		printerr("FAIL: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var source: PackedScene = load("res://scenes/real_catalog.tscn")
	_check(source != null and source.can_instantiate(), "catalog scene available")
	var view: Control = source.instantiate()
	root.add_child(view)
	_check(view.filtered.size() == 754, "all 754 cards browsable")
	_check(view.selected["card_id"] == "1", "first real record")
	_check(view.cast_button.disabled, "unsupported Host Sigil blocked")
	view._filter("Royal Pardon")
	_check(view.filtered.size() == 1 and view.selected["card_id"] == "180", "source name search")
	_check(not view.cast_button.disabled, "implemented effect enabled")
	view._on_test_effect()
	_check(view.lab_state["players"][0]["heat"] == 2, "Royal Pardon lowered Heat")
	_check(view.lab_state["permanents"][0]["cracks"] == 0, "Royal Pardon cleared cracks")
	view._on_test_effect()
	_check(view.lab_state["revision"] == 1, "cannot play same card twice")
	view._filter("Sun-Script Overload")
	_check(view.cast_button.disabled, "unsupported effect fails closed")
	_check(view.details.text.contains("Deal 1 Wound"), "original unimplemented text displayed")
	view._reset_bench()
	_check(view.lab_state["revision"] == 0, "bench resets")
	view._select(FX.find_card(view.card_data, "207"))
	view._on_test_effect()
	_check(view.outcome.text.contains("Stagger"), "Glass Mercy executed")
	view._reset_bench()
	view._select(FX.find_card(view.card_data, "214"))
	view._on_test_effect()
	_check(view.outcome.text.contains("PRIVATE ONLY"), "Mirror peek private result")
	view._reset_bench()
	view._select(FX.find_card(view.card_data, "216"))
	view._on_test_effect()
	_check(view.outcome.text.contains("Stone attack modifier"), "Bitumen Furnace tested")
	view._filter("nonsense_no_card_103084")
	_check(view.filtered.is_empty() and view.cast_button.disabled, "empty search handled")
	view.free()
	print("KUDURRU_REAL_CATALOG_UI passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)
