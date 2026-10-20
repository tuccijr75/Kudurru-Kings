extends RefCounted
## REAL Kudurru card text; source-pinned, narrow sandbox effects only.
## Not a production match reducer. All unsupported effects fail closed.
const Costs = preload("res://scripts/cost_rules.gd")
const PATH := "res://data/real_cards_v1.json"
const SUPPORTED := ["180", "184", "185", "187", "189", "191", "193", "199", "206", "207", "214", "216"]

static func _error(code: String) -> Dictionary:
	return {"ok": false, "error": code}

static func catalog() -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(raw) != TYPE_DICTIONARY: return {}
	if raw.get("schema") != "kudurru_real_cards_v1": return {}
	if int(raw.get("record_count", -1)) != 754 or int(raw.get("production_playable_count", -1)) != 0:
		return {}
	return raw

static func find_card(cards: Dictionary, id: String) -> Dictionary:
	for c in cards.get("cards", []):
		if c["card_id"] == id: return c
	return {}

static func _verified(c: Dictionary) -> bool:
	if c.is_empty(): return false
	var txt: String = str(c.get("rules_text", "")).replace("\r\n", "\n")
	return SUPPORTED.has(str(c.get("card_id", ""))) and c.get("effect_status") == "SANDBOX_TEST_REQUIRED" and (
		txt.sha256_text() == c.get("rules_sha256", "")) and bool(c.get("sandbox_effect_implemented", false))

static func _player(name: String, hand: Array, deck: Array) -> Dictionary:
	return {"name": name, "sinew": 10, "sigil": 10, "oath": 10, "heat": 4,
		"hand": hand.duplicate(), "deck": deck.duplicate(), "discard": [],
		"upkeeps": 0, "ration_until": 0, "first_heat_round": -1}

static func _entity(uid: String, id: String, family: String, seat: int, field: String = "Warfield") -> Dictionary:
	return {"uid": uid, "card_id": id, "family": family, "controller": seat, "owner": seat,
		"field": field, "cracks": 0, "downed": false, "exhausted": false,
		"staggered": false, "silenced": false, "cannot_save_ready_round": -1,
		"cannot_support_round": -1, "ready_at_upkeep": -1, "peek_turn": -1}

static func sandbox() -> Dictionary:
	var c: Dictionary = catalog()
	if c.is_empty(): return _error("CATALOG_INVALID")
	var ids: Array = SUPPORTED.duplicate()
	var state := {"mode": "REAL_EFFECT_SANDBOX", "revision": 0, "round": 1,
		"phase": "Edicts", "actor": 0, "turn": 1, "silence_replacement_round": -1,
		"players": [_player("Player", ids, ["193", "214", "180", "185", "206"]),
			_player("Opponent", ["180"], ["216", "191", "184", "187"])],
		"permanents": [], "truce": [], "events": [], "next_uid": 1}
	var boss: Dictionary = _entity("BOSS0", "16", "Boss", 0)
	boss["cracks"] = 3
	boss["exhausted"] = true
	state["permanents"].append(boss)
	state["permanents"].append(_entity("UNIT0", "255", "Character", 0))
	var other: Dictionary = _entity("DOWNED1", "240", "Pet", 1)
	other["downed"] = true
	state["permanents"].append(other)
	state["permanents"].append(_entity("RELIC1", "225", "Relic", 1))
	state["permanents"].append(_entity("SITE1", "215", "Site", 1))
	return {"ok": true, "state": state}

static func _find_index(s: Dictionary, uid: String) -> int:
	for i in range(s["permanents"].size()):
		if s["permanents"][i]["uid"] == uid: return i
	return -1

static func _law_active(s: Dictionary, id: String) -> bool:
	for item in s["permanents"]:
		if item["card_id"] == id and item["family"] == "Name" and not bool(item["exhausted"]):
			return true
	return false

static func _gain_heat(s: Dictionary, seat: int, amount: int) -> void:
	var p: Dictionary = s["players"][seat]
	if amount > 0 and _law_active(s, "206") and int(p["first_heat_round"]) != int(s["round"]):
		amount = maxi(0, amount - 1)
		p["first_heat_round"] = int(s["round"])
	p["heat"] = maxi(0, int(p["heat"]) + amount)
	s["players"][seat] = p

static func _commit(s: Dictionary, kind: String, seat: int, card_id: String, details: Dictionary = {}) -> Dictionary:
	s["revision"] = int(s["revision"]) + 1
	var event: Dictionary = {"type": kind, "actor": seat, "card_id": card_id, "revision": s["revision"]}
	for key in details:
		event[key] = details[key]
	s["events"].append(event)
	return {"ok": true, "state": s, "event": event}

static func cast(state: Dictionary, action: Dictionary) -> Dictionary:
	if state.get("mode") != "REAL_EFFECT_SANDBOX": return _error("NOT_SANDBOX")
	if typeof(action.get("revision")) != TYPE_INT or action["revision"] != state["revision"]:
		return _error("STALE_REVISION")
	if typeof(action.get("seat")) != TYPE_INT or action["seat"] != state["actor"]:
		return _error("WRONG_ACTOR")
	var seat: int = int(action["seat"])
	if seat < 0 or seat >= state["players"].size(): return _error("INVALID_ACTOR")
	var id: String = str(action.get("card_id", ""))
	var cards: Dictionary = catalog()
	var card: Dictionary = find_card(cards, id)
	if not _verified(card): return _error("UNIMPLEMENTED_OR_UNVERIFIED_EFFECT")
	var phase: String = str(state["phase"])
	var expected: String = "End" if id == "187" else str(card["play_timing"])
	if phase != expected: return _error("WRONG_EFFECT_WINDOW")
	if not state["players"][seat]["hand"].has(id): return _error("CARD_NOT_IN_HAND")
	var s: Dictionary = state.duplicate(true)
	var p: Dictionary = s["players"][seat]
	var shadow: Dictionary = card.duplicate(true)
	shadow["playable"] = true # ONLY source-pinned economic sandbox operation
	var cost: Dictionary = Costs.pay(p, shadow)
	if not cost["ok"]: return cost
	var args: Dictionary = action.get("args", {})
	if typeof(args) != TYPE_DICTIONARY: return _error("BAD_TARGETS")
	var target: int = _find_index(s, str(args.get("uid", "")))
	var target_card: Dictionary = {} if target < 0 else s["permanents"][target]
	var other_seat: int = int(args.get("player", -1))
	match id:
		"180":
			if target < 0 or target_card["controller"] != seat or not ["Boss", "Name"].has(target_card["family"]):
				return _error("FRIENDLY_BOSS_OR_NAME_REQUIRED")
			target_card["cracks"] = 0
			s["permanents"][target] = target_card
			_gain_heat(s, seat, -2)
		"184":
			if target < 0 or not ["Character", "Boss", "Pet"].has(target_card["family"]) or not target_card["downed"]:
				return _error("DOWNED_UNIT_REQUIRED")
			target_card["cannot_save_ready_round"] = s["round"]
			s["permanents"][target] = target_card
		"185":
			if target < 0 or not ["Relic", "Site"].has(target_card["family"]):
				return _error("RELIC_OR_SITE_REQUIRED")
			target_card["exhausted"] = true
			target_card["ready_at_upkeep"] = int(s["players"][target_card["controller"]]["upkeeps"]) + 1
			s["permanents"][target] = target_card
		"187":
			if p["deck"].size() < 2: return _error("INSUFFICIENT_DECK_TO_DRAW_TWO")
			var chosen: String = str(args.get("discard_card_id", ""))
			var possible: Array = p["hand"].duplicate()
			possible.erase(id)
			possible.append(p["deck"][-1])
			possible.append(p["deck"][-2])
			if not possible.has(chosen): return _error("DISCARD_CHOICE_REQUIRED")
			# Draw after cast leaves hand, then discard one precisely selected ID.
			p["hand"].erase(id)
			for i in range(2):
				p["hand"].append(p["deck"].pop_back())
			p["hand"].erase(chosen)
			p["discard"].append(id)
			p["discard"].append(chosen)
			s["players"][seat] = p
			_gain_heat(s, seat, 1)
		"189":
			p["ration_until"] = int(p["upkeeps"]) + 1
			s["players"][seat] = p
		"191":
			var first: int = int(args.get("first_player", -1))
			var second: int = int(args.get("second_player", -1))
			if first < 0 or second < 0 or first == second or first >= s["players"].size() or second >= s["players"].size():
				return _error("TWO_DISTINCT_PLAYERS_REQUIRED")
			s["truce"].append({"a": first, "b": second, "caster": seat,
				"expires_at_upkeep": int(s["players"][seat]["upkeeps"]) + 1})
			_gain_heat(s, first, -1)
			_gain_heat(s, second, -1)
		"193":
			if target < 0 or target_card["controller"] != seat or not ["Character", "Boss", "Pet"].has(target_card["family"]) or not target_card["exhausted"]:
				return _error("EXHAUSTED_FRIENDLY_UNIT_REQUIRED")
			target_card["exhausted"] = false
			target_card["cannot_support_round"] = s["round"]
			s["permanents"][target] = target_card
		"199", "206", "207", "214", "216":
			var perm: Dictionary = _entity("REAL_%d" % int(s["next_uid"]), id, card["card_family"], seat)
			s["next_uid"] = int(s["next_uid"]) + 1
			if id == "214": perm["field"] = "Sanctuary"
			if id == "216": perm["field"] = "Warfield"
			s["permanents"].append(perm)
			if card["card_family"] == "Name": _gain_heat(s, seat, int(card["heat_on_install"]))
		_:
			return _error("NOT_IMPLEMENTED")
	var paid: Dictionary = cost["paid"]
	var after: Dictionary = s["players"][seat]
	for resource in Costs.RESOURCE_KEYS: after[resource] = cost["player"][resource]
	if id != "187":
		after["hand"].erase(id)
		if card["card_family"] == "Edict": after["discard"].append(id)
	s["players"][seat] = after
	return _commit(s, "REAL_EFFECT_CAST", seat, id, {"paid": paid})

static func peek(state: Dictionary, seat: int, site_uid: String, deck_seat: int) -> Dictionary:
	if state.get("mode") != "REAL_EFFECT_SANDBOX" or seat != int(state.get("actor", -1)):
		return _error("NOT_YOUR_TURN")
	if deck_seat < 0 or deck_seat >= state["players"].size(): return _error("INVALID_DECK")
	var index: int = _find_index(state, site_uid)
	if index < 0: return _error("UNKNOWN_SITE")
	var site: Dictionary = state["permanents"][index]
	if site["card_id"] != "214" or site["controller"] != seat or site["exhausted"]:
		return _error("ACTIVE_MIRROR_ARCHIVE_REQUIRED")
	if int(site["peek_turn"]) == int(state["turn"]): return _error("MIRROR_ALREADY_USED_THIS_TURN")
	if state["players"][deck_seat]["deck"].is_empty(): return _error("EMPTY_TARGET_DECK")
	var s: Dictionary = state.duplicate(true)
	var item: Dictionary = s["permanents"][index]
	item["peek_turn"] = int(s["turn"])
	s["permanents"][index] = item
	var private_card_id: String = str(s["players"][deck_seat]["deck"][-1])
	var result: Dictionary = _commit(s, "MIRROR_PEEK_USED", seat, "214", {"site_uid": site_uid, "target_seat": deck_seat})
	result["private_reveal_to_seat"] = seat
	result["private_top_card_id"] = private_card_id
	return result

static func apply_silence(state: Dictionary, uid: String) -> Dictionary:
	var index: int = _find_index(state, uid)
	if index < 0: return _error("MISSING_UNIT")
	var s: Dictionary = state.duplicate(true)
	var item: Dictionary = s["permanents"][index]
	var outcome: String = "Silence"
	if _law_active(s, "207") and int(s["silence_replacement_round"]) != int(s["round"]):
		item["staggered"] = true
		s["silence_replacement_round"] = s["round"]
		outcome = "Stagger"
	else:
		item["silenced"] = true
	s["permanents"][index] = item
	return _commit(s, "STATUS_APPLIED", -1, "207" if outcome == "Stagger" else "", {"status": outcome, "uid": uid})

static func upkeep_failed(state: Dictionary, seat: int) -> Dictionary:
	# External test trigger ONLY; a full Boss failure resolver is still pending.
	if seat < 0 or seat >= state["players"].size(): return _error("INVALID_SEAT")
	var s: Dictionary = state.duplicate(true)
	if _law_active(s, "199"): _gain_heat(s, seat, 1)
	return _commit(s, "OATH_UPKEEP_FAILED_SANDBOX", seat, "199")

static func begin_upkeep(state: Dictionary, seat: int) -> Dictionary:
	if seat < 0 or seat >= state["players"].size(): return _error("INVALID_SEAT")
	var s: Dictionary = state.duplicate(true)
	var p: Dictionary = s["players"][seat]
	p["upkeeps"] = int(p["upkeeps"]) + 1
	p["ration_until"] = 0 if int(p["ration_until"]) <= int(p["upkeeps"]) else int(p["ration_until"])
	s["players"][seat] = p
	for i in range(s["permanents"].size()):
		var item: Dictionary = s["permanents"][i]
		if int(item["controller"]) == seat and int(item["ready_at_upkeep"]) > 0 and int(item["ready_at_upkeep"]) <= int(p["upkeeps"]):
			item["exhausted"] = false
			item["ready_at_upkeep"] = -1
			s["permanents"][i] = item
	var continuing: Array = []
	for truce in s["truce"]:
		if not (int(truce["caster"]) == seat and int(truce["expires_at_upkeep"]) <= int(p["upkeeps"])):
			continuing.append(truce)
	s["truce"] = continuing
	s["turn"] = int(s["turn"]) + 1
	return _commit(s, "UPKEEP_STARTED_SANDBOX", seat, "")

static func oath_upkeep_cost(state: Dictionary, seat: int, base_cost: int) -> int:
	if seat < 0 or seat >= state["players"].size() or base_cost < 0: return -1
	var p: Dictionary = state["players"][seat]
	return maxi(0, base_cost - int(int(p["ration_until"]) == int(p["upkeeps"]) + 1))

static func can_engage(state: Dictionary, first: int, second: int) -> bool:
	for entry in state.get("truce", []):
		if (entry["a"] == first and entry["b"] == second) or (entry["a"] == second and entry["b"] == first):
			return false
	return true

static func can_support(state: Dictionary, uid: String) -> bool:
	var index: int = _find_index(state, uid)
	if index < 0: return false
	var p: Dictionary = state["permanents"][index]
	return not p["exhausted"] and int(p["cannot_support_round"]) != int(state["round"])

static func can_save_or_ready(state: Dictionary, uid: String) -> bool:
	var index: int = _find_index(state, uid)
	return index >= 0 and int(state["permanents"][index]["cannot_save_ready_round"]) != int(state["round"])

static func stone_attack_modifier(state: Dictionary, seat: int, field: String, axis: String, attacking: bool) -> int:
	if axis != "Stone" or not attacking or field != "Warfield": return 0
	for item in state.get("permanents", []):
		if item["card_id"] == "216" and item["controller"] == seat and item["field"] == field and not item["exhausted"]:
			return 1
	return 0
