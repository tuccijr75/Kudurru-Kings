extends RefCounted
## Deterministic, test-only match reducer: setup, mulligan, draw, field deployment.
## No combat, legal effect resolution, Boss upkeep, Marks, rewards or networking.
const Rules = preload("res://scripts/game_rules.gd")
const Deck = preload("res://scripts/deck_validator.gd")
const Costs = preload("res://scripts/cost_rules.gd")
const Fixtures = preload("res://scripts/lab_fixtures.gd")
const MODE := "DEV_ECONOMY_ONLY"
const ALLOWED_DEPLOY := ["Character", "Site"]
const MAX_EVENTS := 10000

static func _error(code: String) -> Dictionary:
	return {"ok": false, "error": code}

static func _shuffle(cards: Array, seed_value: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var result: Array = cards.duplicate(true)
	# Fisher-Yates using local generator; no global random state.
	for i in range(result.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var v: Variant = result[i]
		result[i] = result[j]
		result[j] = v
	return result

static func _draw_to_six(player: Dictionary) -> Dictionary:
	var p: Dictionary = player.duplicate(true)
	while p["hand"].size() < 6 and not p["deck"].is_empty():
		p["hand"].append(p["deck"].pop_back())
	return p

static func create(names: Array, seed_value: int) -> Dictionary:
	if names.size() < 2 or names.size() > 4:
		return _error("SEATS_2_TO_4_REQUIRED")
	if seed_value < 0:
		return _error("INVALID_SEED")
	var normalized: Array = []
	for name in names:
		var n: String = str(name).strip_edges()
		if n.is_empty() or n.length() > 30 or normalized.has(n):
			return _error("INVALID_PLAYER_NAMES")
		normalized.append(n)
	var state: Dictionary = Rules.new_state(normalized)
	state["mode"] = MODE
	state["seed"] = seed_value
	state["fixture_version"] = 1
	state["setup_complete"] = false
	state["setup_ready"] = []
	for i in range(state["players"].size()):
		var p: Dictionary = state["players"][i]
		var faction: String = Deck.FACTIONS[i]
		var card_list: Array = Fixtures.deck(faction)
		if not Deck.validate(card_list)["legal"]:
			return _error("FIXTURE_DECK_INVALID")
		p["faction"] = faction
		p["deck"] = _shuffle(card_list, seed_value + i * 7919)
		p["hand"] = []
		p["field"] = []
		p["law"] = []
		p["discard"] = []
		p["mulligan_available"] = true
		p = _draw_to_six(p)
		state["players"][i] = p
		state["setup_ready"].append(false)
	state["events"].append({"type": "DEV_MATCH_CREATED", "seat_count": names.size(),
			"revision": 0}) # Deliberately excludes hidden deck/hand details
	return {"ok": true, "state": state}

static func _counts(state: Dictionary) -> void:
	for i in range(state["players"].size()):
		var p: Dictionary = state["players"][i]
		var ready: int = 0
		var sites: int = 0
		for c in p["field"]:
			if c["card_family"] == "Character":
				ready += 1 # Only synthetic combat-ready fixture Characters
			if c["card_family"] == "Site":
				sites += 1
		p["ready_units"] = ready
		p["sites"] = sites
		p["host_sigils"] = 0
		state["players"][i] = p

static func _setup_decision(state: Dictionary, action: Dictionary) -> Dictionary:
	if typeof(action.get("seat")) != TYPE_INT:
		return _error("INVALID_SETUP_SEAT")
	var seat: int = int(action["seat"])
	if seat < 0 or seat >= state["players"].size():
		return _error("INVALID_SETUP_SEAT")
	if bool(state["setup_ready"][seat]):
		return _error("SETUP_ALREADY_RESOLVED")
	var op: String = str(action.get("type", ""))
	if op != "MULLIGAN" and op != "KEEP":
		return _error("SETUP_DECISION_REQUIRED")
	var next: Dictionary = state.duplicate(true)
	var person: Dictionary = next["players"][seat]
	if op == "MULLIGAN":
		var full: Array = person["deck"] + person["hand"]
		if full.size() != 36:
			return _error("INVALID_MULLIGAN_CONSERVATION")
		person["deck"] = _shuffle(full, int(state["seed"]) + seat * 7919 + 919)
		person["hand"] = []
		person = _draw_to_six(person)
	person["mulligan_available"] = false
	next["players"][seat] = person
	next["setup_ready"][seat] = true
	next["setup_complete"] = next["setup_ready"].all(func(value): return value)
	next["revision"] = int(next["revision"]) + 1
	var event: Dictionary = {"type": "SETUP_" + op, "seat": seat,
			"revision": next["revision"]}
	next["events"].append(event)
	return {"ok": true, "state": next, "event": event}

static func apply(state: Dictionary, action: Dictionary) -> Dictionary:
	if state.get("mode") != MODE or int(state.get("fixture_version", 0)) != 1:
		return _error("NOT_ECONOMY_LAB")
	if state.get("events", []).size() >= MAX_EVENTS:
		return _error("EVENT_LIMIT")
	if typeof(action.get("revision")) != TYPE_INT or int(action["revision"]) != int(state.get("revision", -1)):
		return _error("STALE_REVISION")
	if not bool(state.get("setup_complete", false)):
		return _setup_decision(state, action)
	if typeof(action.get("seat")) != TYPE_INT or int(action["seat"]) != int(state.get("seat", -1)):
		return _error("WRONG_SEAT")
	var seat: int = int(state["seat"])
	var players: Array = state["players"]
	if seat < 0 or seat >= players.size():
		return _error("INVALID_SEAT")
	var p: Dictionary = players[seat]
	var operation: String = str(action.get("type", ""))
	if operation == "ADVANCE":
		var next_state: Dictionary = state.duplicate(true)
		_counts(next_state)
		var prior_phase: String = Rules.current_phase(next_state)
		var moved: Dictionary = Rules.step(next_state)
		if not moved["ok"]:
			return moved
		next_state = moved["state"]
		if prior_phase == "Upkeep":
			var old: Dictionary = next_state["players"][seat]
			old["mulligan_available"] = false
			next_state["players"][seat] = old
		if Rules.current_phase(next_state) == "Draw":
			var fresh: Dictionary = next_state["players"][seat]
			fresh = _draw_to_six(fresh)
			next_state["players"][seat] = fresh
		return {"ok": true, "state": next_state, "event": moved["event"]}
	if operation == "MULLIGAN" or operation == "KEEP":
		return _error("MULLIGAN_WINDOW_CLOSED")
	if operation == "DEPLOY":
		if Rules.current_phase(state) != "Main":
			return _error("NOT_MAIN_PHASE")
		var id: String = str(action.get("card_id", ""))
		var index: int = -1
		for i in range(p["hand"].size()):
			if str(p["hand"][i]["card_id"]) == id:
				index = i
				break
		if index < 0:
			return _error("CARD_NOT_IN_HAND")
		var card: Dictionary = p["hand"][index]
		if not Fixtures.is_authentic(card):
			return _error("UNTRUSTED_CARD")
		if not ALLOWED_DEPLOY.has(card["card_family"]):
			return _error("UNIMPLEMENTED_CARD_EFFECT")
		var payment: Dictionary = Costs.pay(p, card)
		if not payment["ok"]:
			return payment
		var updated: Dictionary = state.duplicate(true)
		var actor: Dictionary = updated["players"][seat]
		for resource in Costs.RESOURCE_KEYS:
			actor[resource] = int(payment["player"][resource])
		actor["hand"].remove_at(index)
		actor["field"].append(card.duplicate(true))
		updated["players"][seat] = actor
		_counts(updated)
		updated["revision"] = int(updated["revision"]) + 1
		var event: Dictionary = {"type": "DEV_DEPLOY", "seat": seat, "card_id": id,
				"family": card["card_family"], "paid": payment["paid"].duplicate(true),
				"revision": updated["revision"]}
		updated["events"].append(event)
		return {"ok": true, "state": updated, "event": event}
	return _error("UNKNOWN_ACTION")

static func public_summary(state: Dictionary) -> Dictionary:
	var ps: Array = []
	for p in state.get("players", []):
		ps.append({"name": p["name"], "faction": p["faction"],
			"hand_count": p["hand"].size(), "deck_count": p["deck"].size(),
			"field_ids": p["field"].map(func(c): return c["card_id"]),
			"sinew": p["sinew"], "sigil": p["sigil"], "oath": p["oath"]})
	return {"mode": state.get("mode"), "revision": state.get("revision"),
		"setup_complete": state.get("setup_complete", false),
		"setup_ready": state.get("setup_ready", []).duplicate(),
		"phase": Rules.current_phase(state), "seat": state["seat"],
		"round": state["round"], "players": ps}
