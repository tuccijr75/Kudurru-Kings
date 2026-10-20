extends SceneTree
const Match = preload("res://scripts/dev_match.gd")
const Deck = preload("res://scripts/deck_validator.gd")
const Fixtures = preload("res://scripts/lab_fixtures.gd")
const Rules = preload("res://scripts/game_rules.gd")
var passed: int = 0
var failed: int = 0

func _check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		printerr("FAIL: " + label)

func _act(s: Dictionary, op: String, fields: Dictionary = {}) -> Dictionary:
	var a: Dictionary = {"type": op, "seat": s["seat"], "revision": s["revision"]}
	for key in fields: a[key] = fields[key]
	return Match.apply(s, a)

func _advance(s: Dictionary, count: int) -> Dictionary:
	for i in range(count):
		var r: Dictionary = _act(s, "ADVANCE")
		_check(r.get("ok", false), "step " + str(i) + " advances")
		if not r.get("ok", false): return s
		s = r["state"]
	return s

func _initialize() -> void:
	_tests()
	print("KUDURRU_M3_DEV_MATCH passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _tests() -> void:
	_check(not Match.create(["Solo"], 1)["ok"], "reject one-seat lab")
	_check(not Match.create(["A","B","C","D","E"], 1)["ok"], "reject five seats")
	_check(not Match.create(["A","A"], 1)["ok"], "reject duplicate names")
	_check(not Match.create(["A","B"], -1)["ok"], "reject negative seed")
	for faction in Deck.FACTIONS:
		var all_cards: Array = Fixtures.deck(faction)
		_check(all_cards.size() == 36, "36 fixture cards: " + faction)
		_check(Deck.validate(all_cards)["legal"], "legal fixture deck: " + faction)
		_check(Deck.validate(all_cards)["composition"] == "pure", "pure faction: " + faction)
		_check(all_cards.all(func(c): return Fixtures.is_authentic(c)), "signed-by-factory fixtures: " + faction)
		var forged: Dictionary = all_cards[0].duplicate(true)
		forged["cost_sinew"] = 0
		_check(not Fixtures.is_authentic(forged), "cost forgery detected: " + faction)
	var a: Dictionary = Match.create(["A", "B", "C", "D"], 4217)
	_check(a["ok"], "create four seats")
	var b: Dictionary = Match.create(["A", "B", "C", "D"], 4217)
	_check(JSON.stringify(a["state"]) == JSON.stringify(b["state"]), "same seed deterministic setup")
	var state: Dictionary = a["state"]
	_check(state["mode"] == "DEV_ECONOMY_ONLY", "test-only mode")
	_check(state["players"][0]["hand"].size() == 6, "opening hand is six")
	_check(state["players"][0]["deck"].size() == 30, "remainder deck is thirty")
	_check(state["players"][3]["hand"].size() == 6, "all players receive six")
	_check(not Match.public_summary(state).has("hand"), "public summary hides hand details")
	_check(not Match.public_summary(state).has("seed"), "public summary hides seed")
	_check(not state["setup_complete"], "setup choices precede first turn")
	var before: String = JSON.stringify(state)
	var wrong: Dictionary = _act(state, "ADVANCE", {"seat": 2})
	_check(not wrong["ok"] and wrong["error"] == "SETUP_DECISION_REQUIRED", "setup must complete before turns")
	wrong = _act(state, "ADVANCE", {"revision": state["revision"] + 1})
	_check(not wrong["ok"] and wrong["error"] == "STALE_REVISION", "replay version rejected")
	wrong = _act(state, "DEPLOY", {"card_id": "fake"})
	_check(not wrong["ok"] and wrong["error"] == "SETUP_DECISION_REQUIRED", "early deployment blocked in setup")
	_check(JSON.stringify(state) == before, "rejected actions do not mutate state")
	var mulligan: Dictionary = _act(state, "MULLIGAN")
	_check(mulligan["ok"], "one free mulligan")
	var again: Dictionary = _act(state, "MULLIGAN")
	_check(JSON.stringify(mulligan["state"]) == JSON.stringify(again["state"]), "deterministic redraw")
	state = mulligan["state"]
	_check(state["players"][0]["hand"].size() == 6 and state["players"][0]["deck"].size() == 30, "mulligan preserves 36 cards")
	_check(not _act(state, "MULLIGAN")["ok"], "second mulligan rejected")
	_check(not _act(state, "KEEP")["ok"], "cannot keep after mulligan")
	_check(JSON.stringify(state["events"]).find("DEV_ECON_") == -1, "hidden hands never in public events")
	_check(not state["setup_complete"], "other seats still have pregame choices")
	for seat in range(1, 4):
		var kept: Dictionary = _act(state, "KEEP", {"seat": seat})
		_check(kept["ok"], "pregame keep for seat " + str(seat))
		state = kept["state"]
	_check(state["setup_complete"], "all seats decided before first Upkeep")
	_check(not _act(state, "ADVANCE", {"seat": 2})["ok"], "turn ownership checked after setup")
	state = _advance(state, 3)
	_check(Rules.current_phase(state) == "Main", "three steps reach Main")
	_check(not _act(state, "MULLIGAN")["ok"], "mulligan only opening Upkeep")
	_check(_act(state, "DEPLOY", {"card_id": "UNOWNED"})["error"] == "CARD_NOT_IN_HAND", "hand ownership required")
	var unallowed: String = ""
	for card in state["players"][0]["hand"]:
		if card["card_family"] not in ["Character", "Site"]:
			unallowed = str(card["card_id"])
			break
	if not unallowed.is_empty():
		_check(_act(state, "DEPLOY", {"card_id": unallowed})["error"] == "UNIMPLEMENTED_CARD_EFFECT", "unresolved family not deployed")
	# Find deterministic starting seed with a Character and Site in hand.
	var setup: Dictionary = {}
	for candidate in range(1, 150):
		var trial: Dictionary = Match.create(["A", "B"], candidate)["state"]
		var hand: Array = trial["players"][0]["hand"]
		var has_char: bool = hand.any(func(c): return c["card_family"] == "Character" and int(c["cost_sinew"]) <= 2)
		var has_site: bool = hand.any(func(c): return c["card_family"] == "Site")
		if has_char and has_site:
			setup = trial
			break
	_check(not setup.is_empty(), "find standard deck opening with unit and site")
	if setup.is_empty(): return
	for seat in range(2):
		var setup_keep: Dictionary = _act(setup, "KEEP", {"seat": seat})
		_check(setup_keep["ok"], "pregame setup keep")
		setup = setup_keep["state"]
	setup = _advance(setup, 3)
	var first: Dictionary = {}
	var second: Dictionary = {}
	for card in setup["players"][0]["hand"]:
		if first.is_empty() and card["card_family"] == "Character" and int(card["cost_sinew"]) <= 2:
			first = card
		if second.is_empty() and card["card_family"] == "Site":
			second = card
	var origin: String = JSON.stringify(setup)
	var paid: Dictionary = _act(setup, "DEPLOY", {"card_id": first["card_id"]})
	_check(paid["ok"], "Character deployment succeeds on Main")
	_check(JSON.stringify(setup) == origin, "successful reducer does not mutate input")
	var active: Dictionary = paid["state"]
	_check(active["players"][0]["hand"].size() == 5 and active["players"][0]["field"].size() == 1, "deployment moves exactly one card")
	_check(active["players"][0]["sinew"] == 2 - int(first["cost_sinew"]), "sinew paid exactly")
	_check(active["revision"] == setup["revision"] + 1, "revision increment exactly one")
	_check(paid["event"]["type"] == "DEV_DEPLOY", "event is deterministic")
	_check(not _act(active, "DEPLOY", {"card_id": first["card_id"]})["ok"], "same card cannot deploy twice")
	var paid_site: Dictionary = _act(active, "DEPLOY", {"card_id": second["card_id"]})
	_check(paid_site["ok"], "Site deployed after Character")
	active = paid_site["state"]
	_check(active["players"][0]["sigil"] == 0, "site consumes Sigil")
	_check(active["players"][0]["sites"] == 1 and active["players"][0]["ready_units"] == 1, "income control follows field")
	_check(active["players"][0]["hand"].size() == 4, "hand count after two deployments")
	# Main -> Battle -> Resolution -> End (income applied by existing phase reducer).
	active = _advance(active, 3)
	_check(Rules.current_phase(active) == "End", "End reached")
	_check(active["players"][0]["sinew"] == 2 - int(first["cost_sinew"]), "End income not yet applied")
	_check(active["players"][0]["sigil"] == 0, "Site income only after End closes")
	_check(active["players"][0]["oath"] == 1, "no fictional Oath objective income")
	# End seat0; seven phases for seat1; Upkeep -> Draw seat0.
	active = _advance(active, 1 + 7 + 1)
	_check(active["players"][0]["sinew"] == 3 - int(first["cost_sinew"]), "End credited one Sinew")
	_check(active["players"][0]["sigil"] == 1, "End credited one Sigil from Site")
	_check(active["seat"] == 0 and Rules.current_phase(active) == "Draw", "cycle back to player draw")
	_check(active["players"][0]["hand"].size() == 6, "refill hand to six")
	_check(active["players"][0]["deck"].size() == 28, "draw removes two from deck")
	_check(active["players"][0]["field"].size() == 2, "field survives full round")
	var total: int = active["players"][0]["deck"].size() + active["players"][0]["hand"].size() + active["players"][0]["field"].size() + active["players"][0]["discard"].size()
	_check(total == 36, "36-card conservation through two turns")
	var events: Array = active["events"]
	var last_revision: int = -1
	var ordered: bool = true
	for event in events:
		var rev: int = int(event.get("revision", -1))
		if rev < last_revision: ordered = false
		last_revision = rev
	_check(ordered, "replay log revision monotonic")
	var invalid_mode: Dictionary = active.duplicate(true)
	invalid_mode["mode"] = "PRODUCTION"
	_check(_act(invalid_mode, "ADVANCE")["error"] == "NOT_ECONOMY_LAB", "no accidental production execution")
