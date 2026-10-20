extends SceneTree
const FX = preload("res://scripts/real_effects.gd")
var passed: int = 0
var failed: int = 0

func _assert(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		printerr("FAIL: " + label)

func _state() -> Dictionary:
	return FX.sandbox()["state"]

func _cast(state: Dictionary, id: String, args: Dictionary = {}) -> Dictionary:
	return FX.cast(state, {"seat": 0, "revision": state["revision"], "card_id": id, "args": args})

func _phase(state: Dictionary, name: String) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	s["phase"] = name
	return s

func _entity(s: Dictionary, uid: String) -> Dictionary:
	for item in s["permanents"]:
		if item["uid"] == uid: return item
	return {}

func _initialize() -> void:
	_run()
	print("KUDURRU_REAL_EFFECTS passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _run() -> void:
	var cards: Dictionary = FX.catalog()
	_assert(cards.get("record_count", 0) == 754, "754 genuine source cards loaded")
	_assert(cards.get("sandbox_effect_count", 0) == 12, "12 pinned effects in catalog")
	_assert(cards.get("production_playable_count", -1) == 0, "no unreviewed production cards")
	_assert(FX.find_card(cards, "255")["card_name"] == "Adamu", "real Adamu identity")
	_assert(FX.find_card(cards, "16")["card_family"] == "Boss", "real boss identity")
	_assert(FX.find_card(cards, "686")["display_faction"] == "UnderwellKeepers", "EOE source priority")
	_assert(FX.find_card(cards, "686")["owner_faction"] == "FloodbornPact", "source original maintained")
	_assert(FX.find_card(cards, "181")["effect_status"] == "UNIMPLEMENTED", "unsupported effect quarantined")
	for id in FX.SUPPORTED:
		var c: Dictionary = FX.find_card(cards, id)
		_assert(FX._verified(c), "authentic effect signature " + id)
		var changed: Dictionary = c.duplicate(true)
		changed["rules_text"] = str(c["rules_text"]) + "."
		_assert(not FX._verified(changed), "source drift rejected " + id)
	var s: Dictionary = _state()
	_assert(s["players"][0]["hand"].size() == 12, "real sandbox cards present")
	_assert(s["players"][0]["hand"].all(func(id): return FX.SUPPORTED.has(id)), "no synthetic fixtures")
	var original: String = JSON.stringify(s)
	var reject: Dictionary = _cast(s, "181")
	_assert(reject["error"] == "UNIMPLEMENTED_OR_UNVERIFIED_EFFECT", "unimplemented effects fail closed")
	_assert(JSON.stringify(s) == original, "failure does not mutate source")
	reject = FX.cast(s, {"seat": 0, "revision": 1, "card_id": "180"})
	_assert(reject["error"] == "STALE_REVISION", "stale revision rejected")
	reject = FX.cast(s, {"seat": 1, "revision": 0, "card_id": "180"})
	_assert(reject["error"] == "WRONG_ACTOR", "wrong seat rejected")
	reject = _cast(s, "180", {"uid": "RELIC1"})
	_assert(reject["error"] == "FRIENDLY_BOSS_OR_NAME_REQUIRED", "Royal Pardon target rules")
	_assert(JSON.stringify(s) == original, "illegal target no spend or mutations")
	var result: Dictionary = _cast(s, "180", {"uid": "BOSS0"})
	_assert(result["ok"], "Royal Pardon resolved")
	_assert(_entity(result["state"], "BOSS0")["cracks"] == 0, "all friendly Boss Cracks cleared")
	_assert(result["state"]["players"][0]["heat"] == 2, "Royal Pardon lowers Heat exactly 2")
	_assert(result["state"]["players"][0]["discard"].has("180"), "used Edict is discarded")
	_assert(result["state"]["players"][0]["sigil"] == 8, "Royal Pardon Sigil payment")
	_assert(s["players"][0]["heat"] == 4, "original data immutable")
	s = _state()
	reject = _cast(s, "184", {"uid": "UNIT0"})
	_assert(reject["error"] == "DOWNED_UNIT_REQUIRED", "Condemnation requires Downed")
	result = _cast(s, "184", {"uid": "DOWNED1"})
	_assert(result["ok"], "Condemnation Seal resolved")
	_assert(not FX.can_save_or_ready(result["state"], "DOWNED1"), "cannot save or ready this round")
	var next_round: Dictionary = result["state"].duplicate(true)
	next_round["round"] = 2
	_assert(FX.can_save_or_ready(next_round, "DOWNED1"), "seal expires after round")
	s = _state()
	result = _cast(s, "185", {"uid": "SITE1"})
	_assert(result["ok"], "Writ of Seizure resolves against enemy Site")
	s = result["state"]
	_assert(_entity(s, "SITE1")["exhausted"], "Site exhausted")
	_assert(_entity(s, "SITE1")["ready_at_upkeep"] == 1, "ready at controller next Upkeep")
	result = FX.begin_upkeep(s, 0)
	_assert(_entity(result["state"], "SITE1")["exhausted"], "not ready at opponent Upkeep")
	result = FX.begin_upkeep(result["state"], 1)
	_assert(not _entity(result["state"], "SITE1")["exhausted"], "readies controller Upkeep")
	s = _phase(_state(), "End")
	reject = _cast(s, "187", {"discard_card_id": "999"})
	_assert(reject["error"] == "DISCARD_CHOICE_REQUIRED", "End Edict needs legal discard")
	result = _cast(s, "187", {"discard_card_id": "180"})
	_assert(result["ok"], "Night Market Clause End window honored over legacy play_timing")
	_assert(result["state"]["players"][0]["deck"].size() == 3, "draw exactly two")
	_assert(result["state"]["players"][0]["discard"].has("187") and result["state"]["players"][0]["discard"].has("180"), "Edict and chosen card discarded")
	_assert(result["state"]["players"][0]["heat"] == 5, "Night Market raises Heat by 1")
	_assert(result["state"]["players"][0]["hand"].size() == 12, "draw 2 discard 1 from post-cast hand")
	reject = _cast(_state(), "187", {"discard_card_id": "180"})
	_assert(reject["error"] == "WRONG_EFFECT_WINDOW", "night-market cannot play in Edicts")
	s = _state()
	result = _cast(s, "189")
	_assert(result["ok"], "Emergency Rationing resolves")
	_assert(FX.oath_upkeep_cost(result["state"], 0, 1) == 0, "next Oath upkeep costs 1 less")
	_assert(FX.oath_upkeep_cost(result["state"], 1, 1) == 1, "other player's upkeep unchanged")
	s = FX.begin_upkeep(result["state"], 0)["state"]
	_assert(FX.oath_upkeep_cost(s, 0, 1) == 1, "discount expires after upcoming Upkeep")
	s = _state()
	reject = _cast(s, "191", {"first_player": 1, "second_player": 1})
	_assert(reject["error"] == "TWO_DISTINCT_PLAYERS_REQUIRED", "Truce requires distinct players")
	result = _cast(s, "191", {"first_player": 0, "second_player": 1})
	_assert(result["ok"], "Festival Truce resolves")
	_assert(not FX.can_engage(result["state"], 0, 1), "Truce bars mutual engagements")
	_assert(result["state"]["players"][0]["heat"] == 3 and result["state"]["players"][1]["heat"] == 3, "both players relieve Heat 1")
	s = FX.begin_upkeep(result["state"], 1)["state"]
	_assert(not FX.can_engage(s, 0, 1), "Truce persists before caster's Upkeep")
	s = FX.begin_upkeep(s, 0)["state"]
	_assert(FX.can_engage(s, 0, 1), "Truce ends at caster's next Upkeep")
	s = _state()
	result = _cast(s, "193", {"uid": "BOSS0"})
	_assert(result["ok"], "Convoy Priority readies an exhausted Boss")
	_assert(not _entity(result["state"], "BOSS0")["exhausted"], "target readied")
	_assert(not FX.can_support(result["state"], "BOSS0"), "cannot support this round")
	s = result["state"].duplicate(true)
	s["round"] = 2
	_assert(FX.can_support(s, "BOSS0"), "support restriction expires after round")
	reject = _cast(_state(), "193", {"uid": "UNIT0"})
	_assert(reject["error"] == "EXHAUSTED_FRIENDLY_UNIT_REQUIRED", "Convoy requires exhausted unit")
	s = _state()
	result = _cast(s, "199")
	_assert(result["ok"], "Broken Oath Name installed")
	_assert(result["state"]["players"][0]["heat"] == 5, "Name installation adds 1 Heat")
	result = FX.upkeep_failed(result["state"], 1)
	_assert(result["state"]["players"][1]["heat"] == 5, "Broken Oath grants 1 Heat on failed upkeep")
	s = _state()
	result = _cast(s, "206")
	_assert(result["ok"], "Hearth Amnesty installed")
	_assert(result["state"]["players"][0]["heat"] == 4, "first install Heat reduced 1 by new law")
	result = FX.upkeep_failed(result["state"], 0)
	_assert(result["state"]["players"][0]["heat"] == 4, "no extra effect without Broken Oath")
	s = result["state"].duplicate(true)
	FX._gain_heat(s, 1, 2)
	_assert(s["players"][1]["heat"] == 5, "first Heat gain 2 becomes 1")
	FX._gain_heat(s, 1, 2)
	_assert(s["players"][1]["heat"] == 7, "second Heat gain not reduced")
	s["round"] = 2
	FX._gain_heat(s, 1, 1)
	_assert(s["players"][1]["heat"] == 7, "new round resets first-gain protection")
	s = _state()
	result = _cast(s, "207")
	_assert(result["ok"], "Glass Mercy installed")
	result = FX.apply_silence(result["state"], "DOWNED1")
	_assert(result["event"]["status"] == "Stagger", "first silence becomes Stagger")
	_assert(_entity(result["state"], "DOWNED1")["staggered"] and not _entity(result["state"], "DOWNED1")["silenced"], "replacement leaves no Silence")
	result = FX.apply_silence(result["state"], "UNIT0")
	_assert(result["event"]["status"] == "Silence", "second silence remains Silence")
	s = _state()
	reject = _cast(s, "214")
	_assert(reject["error"] == "WRONG_EFFECT_WINDOW", "Site cannot deploy in Edicts")
	s = _phase(s, "Main")
	result = _cast(s, "214")
	_assert(result["ok"], "Mirror Archive Site deployed")
	s = result["state"]
	var mirror_uid: String = s["permanents"][-1]["uid"]
	result = FX.peek(s, 0, mirror_uid, 1)
	_assert(result["ok"] and result["private_top_card_id"] == "187", "Mirror peeks actual enemy top card")
	_assert(JSON.stringify(result["event"]).find("187") == -1, "event does not leak private peek")
	reject = FX.peek(result["state"], 0, mirror_uid, 1)
	_assert(reject["error"] == "MIRROR_ALREADY_USED_THIS_TURN", "one peek each turn")
	s = FX.begin_upkeep(result["state"], 0)["state"]
	_assert(FX.peek(s, 0, mirror_uid, 1)["ok"], "peek available next turn")
	s = _phase(_state(), "Main")
	result = _cast(s, "216")
	_assert(result["ok"], "Bitumen Furnace Site deployed")
	s = result["state"]
	_assert(FX.stone_attack_modifier(s, 0, "Warfield", "Stone", true) == 1, "printed +1 Stone for friendly attack")
	_assert(FX.stone_attack_modifier(s, 0, "Warfield", "Veil", true) == 0, "no Veil bonus")
	_assert(FX.stone_attack_modifier(s, 0, "Warfield", "Stone", false) == 0, "no defensive bonus")
	_assert(FX.stone_attack_modifier(s, 1, "Warfield", "Stone", true) == 0, "enemy gets no bonus")
	s = _state()
	s["players"][0]["sigil"] = 0
	original = JSON.stringify(s)
	reject = _cast(s, "180", {"uid": "BOSS0"})
	_assert(reject["error"] == "INSUFFICIENT_sigil", "exact payment gate denies unaffordable real effect")
	_assert(JSON.stringify(s) == original, "unaffordable real effect makes zero changes")
	var bogus: Dictionary = _state()
	bogus["mode"] = "PRODUCTION"
	_assert(_cast(bogus, "180", {"uid": "BOSS0"})["error"] == "NOT_SANDBOX", "no effect injection into production")
