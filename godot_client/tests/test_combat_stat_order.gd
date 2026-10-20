extends SceneTree
const FX = preload("res://scripts/real_effects.gd")
const ORDER = preload("res://scripts/combat_stat_order.gd")
var passed: int = 0
var failed: int = 0

func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: " + label)

func _initialize() -> void:
	run()
	print("KUDURRU_M6_COMBAT_ORDER passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)

func run() -> void:
	var cards: Dictionary = FX.catalog()
	check(cards["record_count"] == 754, "unchanged real-card count")
	var seen: int = 0
	var by_rating: Dictionary = {}
	for c in cards["cards"]:
		if not ["Character", "Boss"].has(c["card_family"]):
			check(c["first_strike_rating"] == 0 and c["guard"] == 0 and not c["first_strike"], "noncombat values stay zero " + str(c["card_id"]))
			continue
		seen += 1
		check(int(c["guard"]) >= 1 and int(c["guard"]) <= 7, "positive Guard source " + str(c["card_id"]))
		check(bool(c["first_strike"]), "First Strike flag follows positive printed score " + str(c["card_id"]))
		check(int(c["first_strike_rating"]) >= 1 and int(c["first_strike_rating"]) <= 7, "full rating preserved " + str(c["card_id"]))
		check(int(c["initiative"]) > 0, "printed Initiative preserved " + str(c["card_id"]))
		check(c["combat_stat_provenance"] == "SOURCE_HASHED_PRINTED_V1", "print-authority provenance " + str(c["card_id"]))
		var value: int = int(c["first_strike_rating"])
		if not by_rating.has(value): by_rating[value] = c
	check(seen == 664, "all 664 Character and Boss stats normalized")
	check(by_rating.size() == 7, "First Strike ratings 1 through 7 represented")
	var weak: Dictionary = by_rating[1]
	var strong: Dictionary = by_rating[7]
	var strong_first: Dictionary = ORDER.order(str(strong["card_id"]), str(weak["card_id"]))
	check(strong_first["ok"] and strong_first["first_index"] == 0, "higher printed rating precedes lower")
	check(strong_first["reason"] == "FIRST_STRIKE_RATING", "ordering by First Strike, not raw axis")
	check(not strong_first["combat_results_resolved"] and not strong_first["production_match_certified"], "sequence not victory")
	check(strong_first["guard"] == [int(strong["guard"]), int(weak["guard"])], "Guard rating visible but not weapon bonus")
	var reverse: Dictionary = ORDER.order(str(weak["card_id"]), str(strong["card_id"]))
	check(reverse["first_index"] == 1, "ordering is symmetric under side reversal")
	var equal: Dictionary = ORDER.order(str(strong["card_id"]), str(strong["card_id"]))
	check(equal["reason"] == "SIMULTANEOUS" and equal["first_index"] == -1, "same card is not forced first")
	var by_same_rating: Dictionary = {}
	for c in cards["cards"]:
		if not ["Character", "Boss"].has(c["card_family"]): continue
		var rating: int = int(c["first_strike_rating"])
		var initiative: int = int(c["initiative"])
		if by_same_rating.has(rating) and int(by_same_rating[rating]["initiative"]) != initiative:
			var first: Dictionary = by_same_rating[rating]
			var outcome: Dictionary = ORDER.order(str(first["card_id"]), str(c["card_id"]))
			check(outcome["reason"] == "INITIATIVE", "equal First Strike rating uses Initiative")
			check(outcome["first_index"] == (0 if int(first["initiative"]) > initiative else 1), "higher Initiative precedes")
			break
		if not by_same_rating.has(rating): by_same_rating[rating] = c
	check(ORDER.order("180", str(weak["card_id"]))["error"] == "SOURCE_NOT_COMBAT_CAPABLE", "Edict is never fighter")
	check(ORDER.order("not-a-card", str(strong["card_id"]))["error"] == "UNKNOWN_REAL_CARD", "unknown card blocked")
