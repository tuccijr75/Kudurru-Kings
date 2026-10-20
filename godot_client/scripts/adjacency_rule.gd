extends RefCounted
## Exact printed condition for 423 real Characters. Context-only: no full combat.
const PATH := "res://data/adjacency_descriptors_v1.json"
static var _cache: Dictionary = {}

static func _data() -> Dictionary:
	if not _cache.is_empty(): return _cache
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) != TYPE_DICTIONARY: return {}
	if parsed.get("schema") != "kudurru_exact_adjacency_v1" or int(parsed.get("descriptor_count", -1)) != 423:
		return {}
	if bool(parsed.get("full_match_ready", true)): return {}
	_cache = parsed
	return _cache

static func has_compiled_rule(card_id: String) -> bool:
	var data: Dictionary = _data()
	for r in data.get("source_card_effects", []):
		if r["card_id"] == card_id: return true
	return false

static func combat_test_modifier(card_id: String, rules_text: String, axis: String, adjacent_allies: int) -> Dictionary:
	if not ["Stone", "Veil", "Authority"].has(axis): return {"ok": false, "error": "INVALID_COMBAT_AXIS"}
	if adjacent_allies < 0: return {"ok": false, "error": "INVALID_SPATIAL_EVIDENCE"}
	var data: Dictionary = _data()
	if data.is_empty(): return {"ok": false, "error": "DESCRIPTOR_CATALOG_INVALID"}
	for r in data["source_card_effects"]:
		if str(r["card_id"]) != card_id: continue
		var digest: String = rules_text.replace("\r\n", "\n").sha256_text()
		if digest != str(r["source_sha256"]):
			return {"ok": false, "error": "PRINTED_ABILITY_SOURCE_DRIFT"}
		if str(r["trigger"]) != "ON_COMBAT_TEST" or bool(r.get("sandbox_descriptor_only", false)) == false:
			return {"ok": false, "error": "UNTRUSTED_DESCRIPTOR"}
		var value: int = 1 if adjacent_allies >= 1 else 0
		return {"ok": true, "modifier": value, "reason": "ADJACENT_ALLY_PRINTED_ABILITY",
			"production_combat_certified": false}
	return {"ok": false, "error": "NO_EXACT_PRINTED_ADJACENCY_ABILITY"}
