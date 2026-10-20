extends RefCounted
## Read-only preview of the 754-card imported catalog. No card is certified playable.
const PATH: String = "res://data/catalog_preview.json"

static func load_catalog() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {"ok": false, "error": "CATALOG_MISSING"}
	var decoded: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(decoded) != TYPE_DICTIONARY:
		return {"ok": false, "error": "INVALID_CATALOG_JSON"}
	var data: Dictionary = decoded
	if str(data.get("schema", "")) != "kudurru_catalog_preview_v1":
		return {"ok": false, "error": "BAD_SCHEMA"}
	var cards: Array = data.get("cards", [])
	if cards.size() != int(data.get("record_count", -1)):
		return {"ok": false, "error": "COUNT_MISMATCH"}
	if int(data.get("playable_count", -1)) != 0:
		return {"ok": false, "error": "UNAPPROVED_PLAYABILITY"}
	var ids: Dictionary = {}
	for record in cards:
		if typeof(record) != TYPE_DICTIONARY:
			return {"ok": false, "error": "BAD_CARD_RECORD"}
		var c: Dictionary = record
		var id: String = str(c.get("card_id", ""))
		if id.is_empty() or ids.has(id):
			return {"ok": false, "error": "NONUNIQUE_CARD_ID"}
		if bool(c.get("playable", true)):
			return {"ok": false, "error": "UNAPPROVED_PLAYABILITY"}
		ids[id] = true
	return {"ok": true, "data": data, "index_count": cards.size()}

static func find_by_id(catalog: Dictionary, card_id: String) -> Dictionary:
	if not bool(catalog.get("ok", false)):
		return {}
	for card in catalog["data"]["cards"]:
		if str(card.get("card_id", "")) == card_id:
			return card
	return {}
