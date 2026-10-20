extends RefCounted
## Capture is an optional eligible action INSIDE Resolution, not a phase.
## A capture attempt cannot award cards until deterministic adjudication is implemented.
static func eligibility(phase: String, target: Dictionary) -> Dictionary:
	if phase != "Resolution": return {"eligible": false, "reason": "NOT_RESOLUTION"}
	if bool(target.get("defeated", false)): return {"eligible": false, "reason": "ALREADY_DEFEATED"}
	if not bool(target.get("downed", false)): return {"eligible": false, "reason": "NOT_DOWNED"}
	if not bool(target.get("bound", false)): return {"eligible": false, "reason": "NOT_BOUND"}
	if str(target.get("card_family", "")) == "Boss":
		var trials: Array = target.get("trials_won", [])
		for axis in ["stone", "veil", "authority"]:
			if not trials.has(axis): return {"eligible": false, "reason": "TRIALS_INCOMPLETE"}
	return {"eligible": true, "reason": "PLAYER_CHOICE"}

static func choose(phase: String, target: Dictionary, choice: String) -> Dictionary:
	var check: Dictionary = eligibility(phase, target)
	if not check["eligible"]: return {"ok": false, "error": check["reason"]}
	if choice == "decline":
		return {"ok": true, "defeated": true, "result": "DECLINED", "collection_awarded": false}
	if choice == "attempt":
		return {"ok": true, "defeated": false, "result": "AWAITING_ADJUDICATION", "collection_awarded": false}
	return {"ok": false, "error": "BAD_CHOICE"}

static func capture_marks(family: String) -> int:
	if family == "Boss": return 2
	if family == "Character": return 1
	return 0
