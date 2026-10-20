extends RefCounted
## Shared input contract for live reducer, JSON transport and replay.
## Validate exact whole numbers BEFORE casting JSON floats to integers.
const MAX_EXACT_INTEGER := 9007199254740991
const NUMBERS := ["seat", "revision", "hand_index", "target_seat", "target_controller",
	"attacker_spend", "defender_spend"]
const STRINGS := ["type", "card_id", "field", "host_uid", "attacker", "defender", "axis",
	"attacker_supporter", "defender_supporter", "choice", "unit_uid", "target_uid",
	"target_kind", "target_card_id", "target_host_uid", "destination_field"]

static func whole(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return value >= -MAX_EXACT_INTEGER and value <= MAX_EXACT_INTEGER
	if typeof(value) != TYPE_FLOAT: return false
	return is_finite(value) and absf(value) <= float(MAX_EXACT_INTEGER) and value == floor(value)

static func normalize(action: Dictionary) -> Dictionary:
	var result: Dictionary = action.duplicate(true)
	for key in NUMBERS:
		if not action.has(key): continue
		if not whole(action[key]):
			return {"ok": false, "error": "DEFENSE_RESOURCE_TYPE_INVALID" if key == "defender_spend" else "INVALID_INTEGER_" + key.to_upper()}
		result[key] = int(action[key])
	for key in STRINGS:
		if action.has(key) and typeof(action[key]) != TYPE_STRING:
			return {"ok": false, "error": "DEFENSE_SUPPORTER_TYPE_INVALID" if key == "defender_supporter" else "INVALID_STRING_" + key.to_upper()}
	if action.has("target_uids"):
		if typeof(action["target_uids"]) != TYPE_ARRAY:
			return {"ok": false, "error": "INVALID_TARGET_UIDS"}
		for uid in action["target_uids"]:
			if typeof(uid) != TYPE_STRING: return {"ok": false, "error": "INVALID_TARGET_UIDS"}
	return {"ok": true, "action": result}
