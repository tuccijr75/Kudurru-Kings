extends SceneTree
const Rules = preload("res://scripts/game_rules.gd")
const Capture = preload("res://scripts/capture_rules.gd")
const Deck = preload("res://scripts/deck_validator.gd")
const Costs = preload("res://scripts/cost_rules.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	_test_all()
	print("KUDURRU_M1_HEADLESS passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _check(ok: bool, reason: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		printerr("FAIL: " + reason)

func _card(i: int, family: String = "Character", faction: String = "BorderstoneGuild") -> Dictionary:
	return {"card_id": "DEV_%d" % i, "card_name": "DEV_%d" % i, "card_family": family, "owner_faction": faction, "rarity": "Common", "is_standard_legal": true, "scenario_only": false, "requires_faction_lock": false, "deck_copy_limit": 2, "playable": true}

func _test_all() -> void:
	_check(Rules.PHASES == ["Upkeep", "Draw", "Edicts", "Main", "Battle", "Resolution", "End"], "canonical seven phases")
	var state: Dictionary = Rules.new_state(["Player", "Kira", "Vex", "Nael"])
	_check(state["players"].size() == 4, "four seats")
	_check(state["players"][0]["sinew"] == 2 and state["players"][0]["sigil"] == 1 and state["players"][0]["oath"] == 1, "initial resources")
	_check(Rules.heat_tier(0) == "Clear" and Rules.heat_tier(3) == "Watched" and Rules.heat_tier(5) == "Censor Wraith" and Rules.heat_tier(7) == "Tribunal" and Rules.heat_tier(9) == "Lawbroke Candidate", "heat thresholds")
	for i in range(5):
		var r: Dictionary = Rules.step(state)
		_check(r["ok"], "phase %d advances" % i)
		state = r["state"]
	_check(Rules.current_phase(state) == "Resolution", "resolution is phase six")
	var target: Dictionary = {"card_family": "Character", "downed": true, "bound": true, "defeated": false}
	_check(Capture.eligibility("Battle", target)["eligible"] == false, "capture not legal in Battle")
	_check(Capture.eligibility("Resolution", target)["eligible"], "eligible character may be captured")
	var no_bound: Dictionary = target.duplicate(true)
	no_bound["bound"] = false
	_check(not Capture.eligibility("Resolution", no_bound)["eligible"], "Bound required")
	var boss: Dictionary = {"card_family": "Boss", "downed": true, "bound": true, "defeated": false, "trials_won": ["stone", "veil"]}
	_check(not Capture.eligibility("Resolution", boss)["eligible"], "Boss requires three distinct trials")
	boss["trials_won"] = ["stone", "veil", "authority"]
	_check(Capture.eligibility("Resolution", boss)["eligible"], "three unique Boss trials")
	_check(Capture.choose("Resolution", target, "decline")["defeated"], "decline results in Defeated")
	var attempt: Dictionary = Capture.choose("Resolution", target, "attempt")
	_check(attempt["ok"] and not attempt["collection_awarded"], "attempt does not invent success or reward")
	_check(Capture.capture_marks("Boss") == 2 and Capture.capture_marks("Character") == 1, "Marks by family")
	var pending: Dictionary = state.duplicate(true)
	pending["pending_captures"].append(target)
	_check(not Rules.step(pending)["ok"], "pending choice blocks phase transition")
	var s: Dictionary = Rules.step(state)
	_check(s["ok"] and Rules.current_phase(s["state"]) == "End", "Resolution to End")
	state = s["state"]
	_check(state["players"][0]["sinew"] == 2, "no income before End actually closes")
	s = Rules.step(state)
	_check(s["state"]["seat"] == 1 and s["state"]["phase"] == 0, "turn advances to seat two")
	_check(s["state"]["players"][0]["sinew"] == 3, "fallback Sinew credited at End")
	var income: Dictionary = Rules.new_state(["A", "B"])
	income["players"][0]["ready_units"] = 3
	income["players"][0]["sites"] = 1
	income["players"][0]["objective_control"] = true
	var gain: Dictionary = Rules.end_income(income, 0)
	_check(gain["sinew"] == 1 and gain["sigil"] == 1 and gain["oath"] == 1, "all conditional income")
	_check(Rules.threshold_candidates([9, 10, 11, 0]).size() == 2, "simultaneous threshold candidates")
	var deck: Array = []
	for i in range(36):
		var family: String = "Character" if i < 24 else ("Site" if i < 28 else ("Pet" if i < 32 else "Edict"))
		deck.append(_card(i, family))
	_check(Deck.validate(deck)["legal"], "pure 36-card deck structurally legal")
	deck[35]["owner_faction"] = "FloodbornPact"
	_check(Deck.validate(deck)["legal"] and Deck.validate(deck)["composition"] == "mixed", "mixed decks supported")
	deck[35]["requires_faction_lock"] = true
	_check(not Deck.validate(deck)["legal"], "lock blocks unreviewed splash")
	deck[35]["requires_faction_lock"] = false
	deck[35]["owner_faction"] = "Neutral"
	_check(not Deck.validate(deck)["legal"], "neutral cards excluded")
	_check(not Deck.validate(deck.slice(0, 35))["legal"], "deck size exact")
	var invalid_ultra: Dictionary = _card(100)
	invalid_ultra["rarity"] = "Ultra"
	_check(Deck.validate([invalid_ultra])["errors"].has("ULTRA_IDENTITY"), "only Anu/Adamu Ultra")
	var main: PackedScene = load("res://scenes/main.tscn")
	_check(main != null and main.can_instantiate(), "main board scene loads")

	var catalog_script: Script = load("res://scripts/catalog_reader.gd")
	var indexed: Dictionary = catalog_script.load_catalog()
	_check(indexed["ok"], "source-derived catalog readable")
	if indexed["ok"]:
		_check(indexed["index_count"] == 754, "all 754 source records imported")
		_check(int(indexed["data"]["playable_count"]) == 0, "uncertified cards cannot be played")
		_check(indexed["data"]["source_slug_collisions"].size() == 2, "two inherited slug collisions tracked")
		_check(indexed["data"]["faction_conflicts_corrected_for_display"].size() == 4, "four explicit EOE conflicts displayed")
		var drowning: Dictionary = catalog_script.find_by_id(indexed, "686")
		_check(drowning.get("display_faction") == "UnderwellKeepers", "EOE authority wins display alignment")
		_check(drowning.get("source_faction") == "FloodbornPact", "original migrated record preserved")

	var sample_card: Dictionary = {"playable": true, "cost_sinew": 2, "cost_sigil": 1, "cost_oath": 0}
	var original_player: Dictionary = Rules.new_state(["P"])["players"][0]
	var payment: Dictionary = Costs.pay(original_player, sample_card)
	_check(payment["ok"], "certified sample may pay valid resource cost")
	_check(payment["player"]["sinew"] == 0 and payment["player"]["sigil"] == 0 and payment["player"]["oath"] == 1, "three-resource deductions exact")
	_check(original_player["sinew"] == 2 and original_player["sigil"] == 1, "payment never mutates original state")
	var unaffordable: Dictionary = sample_card.duplicate(true)
	unaffordable["cost_sinew"] = 3
	_check(not Costs.pay(original_player, unaffordable)["ok"], "insufficient resource blocks action")
	var untrusted: Dictionary = sample_card.duplicate(true)
	untrusted["playable"] = false
	_check(Costs.quote(untrusted)["error"] == "CARD_NOT_CERTIFIED", "uncertified cost action rejected")
	var invalid_cost: Dictionary = sample_card.duplicate(true)
	invalid_cost["cost_sigil"] = -1
	_check(not Costs.quote(invalid_cost)["ok"], "negative resource cost rejected")
	var free_cost: Dictionary = sample_card.duplicate(true)
	free_cost["cost_sinew"] = 0
	free_cost["cost_sigil"] = 0
	_check(Costs.quote(free_cost)["error"] == "UNAPPROVED_FREE_DEPLOYMENT", "zero total cost rejected")
	var untrusted_deck: Array = []
	for i in range(36):
		var family: String = "Character" if i < 24 else ("Site" if i < 28 else ("Pet" if i < 32 else "Edict"))
		untrusted_deck.append(_card(1000 + i, family))
	untrusted_deck[0]["playable"] = false
	_check(Deck.validate(untrusted_deck)["errors"].has("UNCERTIFIED_CARD"), "uncertified cards rejected in deck validator")
