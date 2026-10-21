extends RefCounted
## Canon-aligned real-card combat/lifecycle core for isolated 2–4 seat sandbox.
## Does not fabricate unsupported abilities, adjudicate captures or run a full match.
const FX = preload("res://scripts/real_effects.gd")
const Adj = preload("res://scripts/adjacency_rule.gd")
const AXES := ["Stone", "Veil", "Authority"]
const MATCHING_RESOURCES := {"Stone": "sinew", "Veil": "sigil", "Authority": "oath"}
const COMBAT_FAMILIES := ["Character", "Boss", "Pet"]
const FIELDS := ["Sanctuary", "Threshold", "Wilds", "Warfield"]

static func fail(code: String) -> Dictionary:
	return {"ok": false, "error": code}

static func card(id: String) -> Dictionary:
	return FX.find_card(FX.catalog(), id)

static func unit(uid: String, id: String, controller: int, slot: int, field: String = "Warfield") -> Dictionary:
	return {"uid": uid, "card_id": id, "controller": controller, "owner": controller,
		"slot": slot, "field": field, "wounds": 0, "downed": false, "bound": false,
		"defeated": false, "defeated_round": -1, "exhausted": false,
		"silenced": false, "staggered": false, "captured": false, "trials_won": []}

static func create(deck_ids: Array, units: Array, seed_value: int = 2112) -> Dictionary:
	if deck_ids.size() < 2 or deck_ids.size() > 4 or seed_value < 0:
		return fail("BAD_MATCH_SETUP")
	var ps: Array = []
	for i in range(deck_ids.size()):
		if typeof(deck_ids[i]) != TYPE_ARRAY: return fail("INVALID_DECK")
		var deck: Array = deck_ids[i]
		for ident in deck:
			if card(str(ident)).is_empty(): return fail("UNKNOWN_FACE_OFF_CARD")
		ps.append({"name": "Seat %d" % i, "sinew": 2, "sigil": 1, "oath": 1,
			"heat": 0, "marks": 0, "deck": deck.duplicate(), "hand": [],
			"collection_copy_events": []})
	var seen: Dictionary = {}
	var slots: Dictionary = {}
	var battle_units: Array = []
	for raw in units:
		if typeof(raw) != TYPE_DICTIONARY: return fail("INVALID_UNIT")
		var u: Dictionary = raw.duplicate(true)
		var id: String = str(u.get("card_id", ""))
		var uid: String = str(u.get("uid", ""))
		var c: Dictionary = card(id)
		var seat: int = int(u.get("controller", -1))
		var slot: int = int(u.get("slot", -1))
		var field: String = str(u.get("field", ""))
		if uid.is_empty() or seen.has(uid) or c.is_empty() or not COMBAT_FAMILIES.has(c["card_family"]):
			return fail("INVALID_UNIT_ID_OR_FAMILY")
		if seat < 0 or seat >= ps.size() or slot < 0 or not FIELDS.has(field):
			return fail("INVALID_SEAT_FIELD_OR_SLOT")
		var key: String = "%s|%d|%d" % [field, seat, slot]
		if slots.has(key): return fail("OCCUPIED_SLOT")
		slots[key] = true
		seen[uid] = true
		if not u.has("wounds") or not u.has("downed") or not u.has("bound") or not u.has("defeated"):
			return fail("MISSING_LIFECYCLE_STATE")
		battle_units.append(u)
	return {"ok": true, "state": {"mode": "REAL_COMBAT_LAB", "round": 1,
		"phase": "Battle", "active_seat": 0, "revision": 0, "seed": seed_value, "players": ps,
		"units": battle_units, "events": [], "winner": -1}}

static func find_unit(state: Dictionary, uid: String) -> int:
	for i in range(state.get("units", []).size()):
		if state["units"][i]["uid"] == uid: return i
	return -1

static func _ready(u: Dictionary) -> bool:
	return not bool(u.get("exhausted", false)) and not bool(u.get("downed", false)) and not bool(u.get("defeated", false))

static func _adjacency(state: Dictionary, u: Dictionary) -> int:
	var count: int = 0
	for other in state["units"]:
		if other["uid"] == u["uid"]: continue
		if int(other["controller"]) != int(u["controller"]): continue
		if other["field"] != u["field"] or bool(other["downed"]) or bool(other["defeated"]): continue
		if absi(int(other["slot"]) - int(u["slot"])) == 1:
			count += 1
	return count

static func _support(state: Dictionary, primary: Dictionary, support_uid: String, axis: String) -> Dictionary:
	if support_uid.is_empty(): return {"ok": true, "bonus": 0, "index": -1}
	var idx: int = find_unit(state, support_uid)
	if idx < 0: return fail("SUPPORTER_UNKNOWN")
	var s: Dictionary = state["units"][idx]
	if s["uid"] == primary["uid"] or int(s["controller"]) != int(primary["controller"]):
		return fail("SUPPORTER_NOT_ALLIED")
	if s["field"] != primary["field"] or not _ready(s):
		return fail("SUPPORTER_NOT_READY_IN_FIELD")
	if int(s.get("cannot_support_round",-1)) == int(state.get("round",-2)):
		return fail("SUPPORT_RESTRICTED_THIS_ROUND")
	var c: Dictionary = card(str(s["card_id"]))
	# The master explicitly specifies HalfRoundedUp; printed special abilities
	# still require their own source-verified resolver.
	if c["card_family"] != "Character" or str(c.get("support_value_rule", "")) != "HalfRoundedUp" or str(c.get("heat_on_support", "")) != "-1" or not Adj.has_compiled_rule(str(c["card_id"])):
		return fail("SUPPORTER_EFFECT_UNCERTIFIED")
	var value: int = int(c[axis.to_lower()])
	return {"ok": true, "bonus": int(ceili(float(value) / 2.0)), "index": idx}

static func _fighter(state: Dictionary, u: Dictionary, axis: String) -> Dictionary:
	var c: Dictionary = card(str(u["card_id"]))
	if c["card_family"] != "Character":
		return fail("COMBAT_EFFECT_UNCERTIFIED")
	var modifier: Dictionary = Adj.combat_test_modifier(str(c["card_id"]),
		str(c["rules_text"]), axis, _adjacency(state, u))
	if not modifier.get("ok", false): return fail("COMBAT_EFFECT_UNCERTIFIED")
	return {"ok": true, "base": int(c[axis.to_lower()]),
		"adjacency": int(modifier["modifier"])}

static func _draw_valid(deck: Array) -> Dictionary:
	for i in range(deck.size() - 1, -1, -1):
		var c: Dictionary = card(str(deck[i]))
		if COMBAT_FAMILIES.has(str(c.get("card_family", ""))):
			var copy: Array = deck.duplicate()
			var id: String = str(copy[i])
			copy.remove_at(i)
			return {"valid": true, "deck": copy, "card_id": id, "card": c}
	return {"valid": false, "deck": deck.duplicate()}

static func _shuffle_back(deck: Array, revealed: Array, seed_value: int) -> Array:
	var mixed: Array = deck.duplicate()
	mixed.append_array(revealed)
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	for i in range(mixed.size() - 1, 0, -1):
		var j: int = random.randi_range(0, i)
		var temporary: Variant = mixed[i]
		mixed[i] = mixed[j]
		mixed[j] = temporary
	return mixed

static func faceoff(state: Dictionary, seat_a: int, seat_b: int, axis: String) -> Dictionary:
	if not AXES.has(axis): return fail("INVALID_AXIS")
	if seat_a < 0 or seat_b < 0 or seat_a == seat_b or seat_a >= state["players"].size() or seat_b >= state["players"].size():
		return fail("BAD_FACE_OFF_SEATS")
	var deck_a: Array = state["players"][seat_a]["deck"].duplicate()
	var deck_b: Array = state["players"][seat_b]["deck"].duplicate()
	var revealed_a: Array = []
	var revealed_b: Array = []
	var chain: Array = []
	var winner: int = -1
	# Finite: a revealed combat card cannot be used again in the same chain.
	while true:
		var a: Dictionary = _draw_valid(deck_a)
		var b: Dictionary = _draw_valid(deck_b)
		if not bool(a["valid"]) and not bool(b["valid"]):
			return fail("FACE_OFF_UNRESOLVED_BOTH_EMPTY")
		if not bool(a["valid"]):
			winner = seat_b
			break
		if not bool(b["valid"]):
			winner = seat_a
			break
		deck_a = a["deck"]
		deck_b = b["deck"]
		revealed_a.append(a["card_id"])
		revealed_b.append(b["card_id"])
		var va: int = int(a["card"][axis.to_lower()])
		var vb: int = int(b["card"][axis.to_lower()])
		chain.append({"a": a["card_id"], "b": b["card_id"], "a_axis": va, "b_axis": vb})
		if va != vb:
			winner = seat_a if va > vb else seat_b
			break
	# Cards are returned and deterministic shuffled only once chain settles.
	return {"ok": true, "winner": winner, "chain": chain,
		"deck_a": _shuffle_back(deck_a, revealed_a, int(state["seed"]) + int(state["revision"]) * 17 + seat_a * 7 + 131),
		"deck_b": _shuffle_back(deck_b, revealed_b, int(state["seed"]) + int(state["revision"]) * 23 + seat_b * 13 + 353)}

static func _owned_passive_bonus(state: Dictionary, u: Dictionary, axis: String, attacking: bool) -> int:
	if axis != "Stone": return 0
	var bonus: int = 0
	if attacking and u["field"] == "Warfield":
		for site in state.get("sites", []):
			if str(site.get("card_id", "")) == "216" and int(site.get("controller", -1)) == int(u["controller"]) and str(site.get("field", "")) == "Warfield" and not bool(site.get("exhausted",false)):
				bonus += 1
				break
	for item in state.get("attachments", []):
		if str(item.get("host_uid", "")) != str(u["uid"]) or int(item.get("controller", -1)) != int(u["controller"]) or bool(item.get("exhausted",false)):
			continue
		if item["card_id"] == "239" and attacking:
			bonus += 1
		if item["card_id"] == "254":
			for site in state.get("sites", []):
				if int(site.get("controller", -1)) == int(u["controller"]) and site.get("field") == u["field"]:
					bonus += 1
					break
	return bonus

static func attack(state: Dictionary, action: Dictionary) -> Dictionary:
	if state.get("mode") != "REAL_COMBAT_LAB" or state.get("phase") != "Battle":
		return fail("WRONG_PHASE_OR_MODE")
	if typeof(action.get("revision")) != TYPE_INT or action["revision"] != state["revision"]:
		return fail("STALE_REVISION")
	var ai: int = find_unit(state, str(action.get("attacker", "")))
	var di: int = find_unit(state, str(action.get("defender", "")))
	if ai < 0 or di < 0 or ai == di: return fail("INVALID_ATTACK_TARGET")
	var a: Dictionary = state["units"][ai]
	var b: Dictionary = state["units"][di]
	if int(a["controller"]) != int(state.get("active_seat", -1)):
		return fail("NOT_ACTIVE_SEAT_ATTACKER")
	if int(a["controller"]) == int(b["controller"]) or not _ready(a) or bool(b["downed"]) or bool(b["defeated"]):
		return fail("ILLEGAL_COMBATANTS")
	if a["field"] != b["field"]: return fail("NOT_IN_SAME_FIELD")
	var axis: String = str(action.get("axis", ""))
	if not AXES.has(axis): return fail("INVALID_AXIS")
	var fa: Dictionary = _fighter(state, a, axis)
	var fb: Dictionary = _fighter(state, b, axis)
	if not fa.get("ok", false) or not fb.get("ok", false):
		return fail("COMBAT_EFFECT_UNCERTIFIED")
	var sa_uid: String = str(action.get("attacker_supporter", ""))
	var sb_uid: String = str(action.get("defender_supporter", ""))
	var sa: Dictionary = _support(state, a, sa_uid, axis)
	var sb: Dictionary = _support(state, b, sb_uid, axis)
	if not sa.get("ok", false): return sa
	if not sb.get("ok", false): return sb
	if int(sa["index"]) >= 0 and int(sa["index"]) == int(sb["index"]):
		return fail("SAME_SUPPORTER_BOTH_SIDES")
	var spend_a: int = int(action.get("attacker_spend", 0))
	var spend_b: int = int(action.get("defender_spend", 0))
	if spend_a < 0 or spend_b < 0 or spend_a > 2 or spend_b > 2:
		return fail("COMBAT_SPEND_0_TO_2")
	# Mapping is an M5 implementation assumption, not canon-certified yet.
	var resource: String = str(MATCHING_RESOURCES[axis])
	var seat_a: int = int(a["controller"])
	var seat_b: int = int(b["controller"])
	if int(state["players"][seat_a][resource]) < spend_a or int(state["players"][seat_b][resource]) < spend_b:
		return fail("INSUFFICIENT_MATCHING_RESOURCE")
	var score_a: int = int(fa["base"]) + int(fa["adjacency"]) + int(sa["bonus"]) + spend_a + _owned_passive_bonus(state, a, axis, true)
	var score_b: int = int(fb["base"]) + int(fb["adjacency"]) + int(sb["bonus"]) + spend_b + _owned_passive_bonus(state, b, axis, false)
	var result_faceoff: Dictionary = {}
	var winner: int = seat_a if score_a > score_b else seat_b
	if score_a == score_b:
		result_faceoff = faceoff(state, seat_a, seat_b, axis)
		if not result_faceoff.get("ok", false): return result_faceoff
		winner = int(result_faceoff["winner"])
	var s: Dictionary = state.duplicate(true)
	s["players"][seat_a][resource] -= spend_a
	s["players"][seat_b][resource] -= spend_b
	s["units"][ai]["exhausted"] = true
	if int(sa["index"]) >= 0:
		s["units"][int(sa["index"])]["exhausted"] = true
		s["players"][seat_a]["heat"] = maxi(0, int(s["players"][seat_a]["heat"]) - 1)
	if int(sb["index"]) >= 0:
		s["units"][int(sb["index"])]["exhausted"] = true
		s["players"][seat_b]["heat"] = maxi(0, int(s["players"][seat_b]["heat"]) - 1)
	var wounds_applied: int = 0
	if winner == seat_a:
		s["units"][di]["wounds"] = int(s["units"][di]["wounds"]) + 1
		wounds_applied = 1
		var defender: Dictionary = card(str(b["card_id"]))
		var limit: int = int(defender.get("wound_threshold", 0))
		if limit <= 0: return fail("WOUND_THRESHOLD_UNCERTIFIED")
		if int(s["units"][di]["wounds"]) >= limit:
			s["units"][di]["downed"] = true
	if not result_faceoff.is_empty():
		s["players"][seat_a]["deck"] = result_faceoff["deck_a"]
		s["players"][seat_b]["deck"] = result_faceoff["deck_b"]
	s["revision"] = int(s["revision"]) + 1
	var event: Dictionary = {"type": "REAL_COMBAT_SANDBOX", "revision": s["revision"],
		"attacker": a["uid"], "defender": b["uid"], "axis": axis,
		"totals": [score_a, score_b], "spend": [spend_a, spend_b],
		"winner_seat": winner, "wounds_applied": wounds_applied,
		"face_off": result_faceoff.get("chain", [])}
	s["events"].append(event)
	return {"ok": true, "state": s, "event": event,
		"production_combat_certified": false}

static func mark_downed_bound(state: Dictionary, uid: String, evidence: String) -> Dictionary:
	# Test-only: does not claim the game has a certified universal Bind ability.
	if state.get("mode") != "REAL_COMBAT_LAB" or evidence != "TEST_SETUP_ONLY":
		return fail("NO_CERTIFIED_BIND_SOURCE")
	var idx: int = find_unit(state, uid)
	if idx < 0 or not bool(state["units"][idx]["downed"]) or bool(state["units"][idx]["defeated"]):
		return fail("BIND_REQUIRES_DOWNED")
	var s: Dictionary = state.duplicate(true)
	s["units"][idx]["bound"] = true
	s["revision"] = int(s["revision"]) + 1
	s["events"].append({"type": "TEST_BIND_INJECTION", "uid": uid, "revision": s["revision"]})
	return {"ok": true, "state": s}

static func _capture_gate(state: Dictionary, actor: int, uid: String) -> Dictionary:
	# Shared fail-closed prerequisite gate; this does not adjudicate Bind or capture.
	if state.get("mode") != "REAL_COMBAT_LAB" or state.get("phase") != "Resolution":
		return fail("NOT_RESOLUTION")
	if actor < 0 or actor >= state["players"].size(): return fail("ACTOR_INVALID")
	if actor != int(state.get("active_seat", -1)): return fail("NOT_ACTIVE_SEAT")
	var idx: int = find_unit(state, uid)
	if idx < 0: return fail("TARGET_MISSING")
	var target: Dictionary = state["units"][idx]
	if not target["downed"] or not target["bound"] or target["defeated"] or bool(target.get("captured", false)) or actor == target["controller"]:
		return fail("CAPTURE_NOT_ELIGIBLE")
	var c: Dictionary = card(str(target["card_id"]))
	if c.is_empty(): return fail("UNKNOWN_CAPTURE_SOURCE")
	if not ["Character", "Boss"].has(c.get("card_family", "")):
		return fail("NO_CAPTURE_FAMILY")
	if c["card_family"] == "Boss":
		var trials: Variant = target.get("trials_won", [])
		if typeof(trials) != TYPE_ARRAY: return fail("INVALID_BOSS_TRIAL_RECORD")
		for required in AXES:
			if not trials.has(required): return fail("BOSS_TRIALS_INCOMPLETE")
		if trials.size() != AXES.size(): return fail("INVALID_BOSS_TRIAL_RECORD")
	return {"ok": true, "unit_index": idx, "source": c}

static func decline_capture(state: Dictionary, actor: int, uid: String) -> Dictionary:
	var gate: Dictionary = _capture_gate(state, actor, uid)
	if not gate.get("ok", false): return gate
	var idx: int = gate["unit_index"]
	var c: Dictionary = gate["source"]
	var s: Dictionary = state.duplicate(true)
	s["units"][idx]["defeated"] = true
	s["units"][idx]["defeated_round"] = int(s["round"])
	s["units"][idx]["bound"] = false
	var marks: int = 1 if c["card_family"] == "Character" else 0
	s["players"][actor]["marks"] = int(s["players"][actor]["marks"]) + marks
	s["revision"] = int(s["revision"]) + 1
	var event := {"type": "CAPTURE_DECLINED_DEFEATED", "uid": uid, "actor": actor,
		"marks": marks, "revision": s["revision"]}
	s["events"].append(event)
	if int(s["players"][actor]["marks"]) >= 10: s["winner"] = actor
	return {"ok": true, "state": s, "event": event}

static func capture_attempt(state: Dictionary, actor: int, uid: String) -> Dictionary:
	var gate: Dictionary = _capture_gate(state, actor, uid)
	if not gate.get("ok", false): return gate
	return fail("CAPTURE_SUCCESS_RULE_NOT_SPECIFIED")

static func restore_defeated(state: Dictionary) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	s["round"] = int(s["round"]) + 1
	var restored: Array = []
	var surviving: Array = []
	for u in s["units"]:
		if bool(u["defeated"]) and int(u["defeated_round"]) >= 0 and int(s["round"]) >= int(u["defeated_round"]) + 3:
			var owner: int = int(u["owner"])
			if owner < 0 or owner >= s["players"].size(): return fail("INVALID_OWNER")
			if s["players"][owner]["hand"].size() < 6:
				s["players"][owner]["hand"].append(u["card_id"])
				restored.append({"uid": u["uid"], "to": "Hand"})
			else:
				s["players"][owner]["deck"].append(u["card_id"])
				restored.append({"uid": u["uid"], "to": "Deck"})
		else:
			surviving.append(u)
	s["units"] = surviving
	s["revision"] = int(s["revision"]) + 1
	var event := {"type": "ROUND_ADVANCED_RESTORE", "round": s["round"],
		"restored": restored, "revision": s["revision"]}
	s["events"].append(event)
	return {"ok": true, "state": s, "event": event}
