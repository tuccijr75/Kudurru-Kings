extends RefCounted
## Pure payment quote for *certified* cards. No state mutation, UI spend or rewards.
## The authoritative match reducer must still validate turn/zone/legal action first.
const RESOURCE_KEYS := ["sinew", "sigil", "oath"]
const CAPS := {"sinew": 5, "sigil": 2, "oath": 2}

static func _integer(raw: Variant) -> int:
	if typeof(raw) == TYPE_INT: return int(raw)
	if typeof(raw) == TYPE_STRING and str(raw).is_valid_int(): return int(raw)
	return -1

static func quote(card: Dictionary) -> Dictionary:
	if not bool(card.get("playable", false)):
		return {"ok": false, "error": "CARD_NOT_CERTIFIED"}
	var amounts: Dictionary = {}
	var total := 0
	for key in RESOURCE_KEYS:
		var field: String = "cost_" + str(key)
		if not card.has(field): return {"ok": false, "error": "MISSING_COST_" + key}
		var amount: int = _integer(card[field])
		if amount < 0 or amount > int(CAPS[key]):
			return {"ok": false, "error": "INVALID_COST_" + key}
		amounts[key] = amount
		total += amount
	if total == 0: return {"ok": false, "error": "UNAPPROVED_FREE_DEPLOYMENT"}
	return {"ok": true, "cost": amounts}

static func pay(player: Dictionary, card: Dictionary) -> Dictionary:
	var q: Dictionary = quote(card)
	if not q["ok"]: return q
	for key in RESOURCE_KEYS:
		if not player.has(key):
			return {"ok": false, "error": "MISSING_RESOURCE_" + key}
		var available: int = _integer(player[key])
		if available < 0:
			return {"ok": false, "error": "INVALID_RESOURCE_" + key}
		if available < int(q["cost"][key]):
			return {"ok": false, "error": "INSUFFICIENT_" + key}
	var updated: Dictionary = player.duplicate(true)
	for key in RESOURCE_KEYS:
		updated[key] = int(updated[key]) - int(q["cost"][key])
	return {"ok": true, "player": updated, "paid": q["cost"].duplicate(true)}
