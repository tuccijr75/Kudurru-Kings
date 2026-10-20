extends RefCounted
## M1 deterministic development-state model. No match/capture rewards.
const PHASES = ["Upkeep", "Draw", "Edicts", "Main", "Battle", "Resolution", "End"]
const WIN_MARKS: int = 10

static func new_state(names: Array) -> Dictionary:
	var players: Array = []
	for name in names:
		players.append({"name": str(name), "sinew": 2, "sigil": 1, "oath": 1, "heat": 0, "marks": 0, "ready_units": 0, "sites": 0, "host_sigils": 0, "objective_control": false})
	return {"players": players, "seat": 0, "phase": 0, "round": 1, "revision": 0, "pending_captures": [], "events": [], "mode": "M1_PREVIEW"}

static func current_phase(state: Dictionary) -> String:
	return PHASES[int(state["phase"])]

static func heat_tier(heat: int) -> String:
	if heat >= 9: return "Lawbroke Candidate"
	if heat >= 7: return "Tribunal"
	if heat >= 5: return "Censor Wraith"
	if heat >= 3: return "Watched"
	return "Clear"

static func end_income(state: Dictionary, seat: int) -> Dictionary:
	var players: Array = state["players"]
	if seat < 0 or seat >= players.size(): return {"ok": false, "error": "INVALID_SEAT"}
	var best: int = 0
	var best_count: int = 0
	for p in players:
		var ready: int = int(p["ready_units"])
		if ready > best:
			best = ready
			best_count = 1
		elif ready == best:
			best_count += 1
	var active: Dictionary = players[seat]
	var sinew: int = 1 if best > 0 and best_count == 1 and int(active["ready_units"]) == best else 0
	var sigil: int = 1 if int(active["sites"]) > 0 or int(active["host_sigils"]) > 0 else 0
	var oath: int = 1 if bool(active["objective_control"]) else 0
	var fallback: bool = sinew == 0 and sigil == 0 and oath == 0
	if fallback: sinew = 1
	return {"ok": true, "sinew": sinew, "sigil": sigil, "oath": oath, "fallback": fallback}

static func step(state: Dictionary) -> Dictionary:
	var seats: int = state.get("players", []).size()
	var seat: int = int(state.get("seat", -1))
	var phase: int = int(state.get("phase", -1))
	if seats < 1 or seats > 4 or seat < 0 or seat >= seats or phase < 0 or phase > 6:
		return {"ok": false, "error": "BAD_STATE"}
	if phase == 5 and not state.get("pending_captures", []).is_empty():
		return {"ok": false, "error": "CAPTURE_DECISION_PENDING"}
	var s: Dictionary = state.duplicate(true)
	# End-phase income executes as End closes, not when Resolution closes.
	if phase == 6:
		var gain: Dictionary = end_income(s, seat)
		var ps: Array = s["players"]
		var p: Dictionary = ps[seat]
		for key in ["sinew", "sigil", "oath"]:
			p[key] = int(p[key]) + int(gain[key])
		ps[seat] = p
		s["players"] = ps
		s["seat"] = (seat + 1) % seats
		if s["seat"] == 0: s["round"] = int(s["round"]) + 1
	s["phase"] = (phase + 1) % 7
	s["revision"] = int(s["revision"]) + 1
	var e: Dictionary = {"type": "PHASE", "seat": s["seat"], "phase": current_phase(s), "revision": s["revision"]}
	s["events"].append(e)
	return {"ok": true, "state": s, "event": e}

static func threshold_candidates(scores: Array) -> Array:
	var candidates: Array = []
	for i in range(scores.size()):
		if int(scores[i]) >= WIN_MARKS: candidates.append(i)
	return candidates
