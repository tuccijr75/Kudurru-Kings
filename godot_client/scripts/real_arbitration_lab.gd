extends RefCounted
## Hidden Oath-bid arbitration of real persistent Names, isolated sandbox.
## Seize is the only fully specified outcome; Suppress and Corrupt fail closed.
const Combat = preload("res://scripts/real_combat_core.gd")
const FX = preload("res://scripts/real_effects.gd")

static func fail(code: String) -> Dictionary:
	return {"ok": false, "error": code}

static func open(real_state: Dictionary, name_uid: String, challenger: int) -> Dictionary:
	if real_state.get("mode") != "REAL_EFFECT_SANDBOX":
		return fail("REAL_EFFECT_SANDBOX_REQUIRED")
	var idx: int = FX._find_index(real_state, name_uid)
	if idx < 0: return fail("NAME_NOT_FOUND")
	var name: Dictionary = real_state["permanents"][idx]
	if name["family"] != "Name" or bool(name["exhausted"]):
		return fail("ACTIVE_NAME_REQUIRED")
	var defender: int = int(name["controller"])
	if challenger < 0 or challenger >= real_state["players"].size() or challenger == defender:
		return fail("INVALID_CHALLENGER")
	var s: Dictionary = real_state.duplicate(true)
	for player in s["players"]:
		if not player.has("marks"): player["marks"] = 0
	s["mode"] = "ARBITRATION_LAB"
	s["seed"] = 20261020
	s["arbitration"] = {
		"name_uid": name_uid, "challenger": challenger,
		"defender": defender, "hidden_bids": {},
		"status": "COLLECTING", "result": {},
	}
	s["revision"] = int(s["revision"]) + 1
	s["events"].append({"type": "ARBITRATION_OPEN", "name_uid": name_uid,
		"challenger": challenger, "defender": defender, "revision": s["revision"]})
	return {"ok": true, "state": s}

static func available_oath(state: Dictionary, seat: int) -> int:
	if seat < 0 or seat >= state["players"].size(): return -1
	var bid: Dictionary = state["arbitration"]["hidden_bids"]
	return int(state["players"][seat]["oath"]) - int(bid.get(str(seat), 0))

static func public_view(state: Dictionary) -> Dictionary:
	# NEVER expose raw state to another participant or spectator.
	var bids: Dictionary = state["arbitration"]["hidden_bids"]
	return {
		"revision": state["revision"],
		"name_uid": state["arbitration"]["name_uid"],
		"status": state["arbitration"]["status"],
		"ready": [bids.has(str(state["arbitration"]["challenger"])),
			bids.has(str(state["arbitration"]["defender"]))],
		"result": state["arbitration"].get("result", {}).duplicate(true),
	}

static func bid(state: Dictionary, actor: int, amount: int, revision: int) -> Dictionary:
	if state.get("mode") != "ARBITRATION_LAB": return fail("ARBITRATION_MODE_REQUIRED")
	if revision != int(state.get("revision", -1)): return fail("STALE_REVISION")
	var sess: Dictionary = state["arbitration"]
	if sess["status"] != "COLLECTING": return fail("BIDDING_CLOSED")
	if actor != int(sess["challenger"]) and actor != int(sess["defender"]):
		return fail("NOT_PARTICIPANT")
	if sess["hidden_bids"].has(str(actor)): return fail("BID_ALREADY_COMMITTED")
	if amount < 0 or amount > int(state["players"][actor]["oath"]):
		return fail("INSUFFICIENT_OATH_FOR_BID")
	var s: Dictionary = state.duplicate(true)
	s["arbitration"]["hidden_bids"][str(actor)] = amount
	s["revision"] = int(s["revision"]) + 1
	var e: Dictionary = {"type": "SEALED_OATH_BID_COMMITTED", "actor": actor,
		"revision": s["revision"]}
	s["events"].append(e)
	return {"ok": true, "state": s, "event": e}

static func resolve(state: Dictionary, choice: String, revision: int) -> Dictionary:
	if state.get("mode") != "ARBITRATION_LAB": return fail("ARBITRATION_MODE_REQUIRED")
	if revision != int(state.get("revision", -1)): return fail("STALE_REVISION")
	var sess: Dictionary = state["arbitration"]
	if sess["status"] != "COLLECTING": return fail("ARBITRATION_ALREADY_RESOLVED")
	var a: int = int(sess["challenger"])
	var b: int = int(sess["defender"])
	if not sess["hidden_bids"].has(str(a)) or not sess["hidden_bids"].has(str(b)):
		return fail("BOTH_SEALED_BIDS_REQUIRED")
	if choice != "Seize":
		return fail("UNRESOLVED_SUPPRESS_OR_CORRUPT_RULE")
	var first: int = int(sess["hidden_bids"][str(a)])
	var second: int = int(sess["hidden_bids"][str(b)])
	if first > int(state["players"][a]["oath"]) or second > int(state["players"][b]["oath"]):
		return fail("BID_ESCROW_CHANGED")
	var winner: int = a if first > second else b
	var tie_details: Array = []
	var face: Dictionary = {}
	if first == second:
		face = Combat.faceoff(state, a, b, "Authority")
		if not face.get("ok", false): return face
		winner = int(face["winner"])
		tie_details = face["chain"]
	var idx: int = FX._find_index(state, str(sess["name_uid"]))
	if idx < 0 or state["permanents"][idx]["controller"] != b:
		return fail("TARGET_NAME_CHANGED")
	var s: Dictionary = state.duplicate(true)
	s["players"][a]["oath"] = int(s["players"][a]["oath"]) - first
	s["players"][b]["oath"] = int(s["players"][b]["oath"]) - second
	if not face.is_empty():
		s["players"][a]["deck"] = face["deck_a"]
		s["players"][b]["deck"] = face["deck_b"]
	var seized: bool = winner == a
	if seized:
		s["permanents"][idx]["controller"] = a
		# Owner remains defender; ownership never permanently changes.
		s["players"][a]["marks"] = int(s["players"][a]["marks"]) + 1
	s["arbitration"]["status"] = "RESOLVED"
	s["arbitration"]["result"] = {
		"winner": winner, "seized": seized, "marks": 1 if seized else 0,
		"revealed_bids": [first, second], "faceoff": tie_details,
	}
	s["revision"] = int(s["revision"]) + 1
	var event: Dictionary = {"type": "ARBITRATION_RESULT", "revision": s["revision"],
		"winner": winner, "seized": seized, "marks": 1 if seized else 0,
		"revealed_bids": [first, second], "faceoff": tie_details}
	s["events"].append(event)
	return {"ok": true, "state": s, "event": event}
