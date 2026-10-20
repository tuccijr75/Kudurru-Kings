extends RefCounted
## M8 versioned local save and deterministic replay for source-backed candidate.
## No accounts, copy rewards, secrets, or production unlocks.
const Command = preload("res://scripts/match_command.gd")
const Match = preload("res://scripts/match_integrator.gd")
const Source = preload("res://scripts/real_effects.gd")
const VERSION := "KUDURRU_LOCAL_MATCH_V1"
const SLOT := "user://kudurru/solo_slot.json"
const SIZE_LIMIT := 4 * 1024 * 1024
const ACTION_LIMIT := 10000

static func _bad(message: String) -> Dictionary:
	return {"ok": false, "error": message}

static func _normalized(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value))

static func _hash(value: Variant) -> String:
	return JSON.stringify(_normalized(value)).sha256_text()

static func _validate(s: Dictionary) -> Dictionary:
	if s.get("mode") != Match.MODE or s.get("scenario") != Match.SCENARIO:
		return _bad("WRONG_MATCH_OR_SCENARIO")
	if typeof(s.get("release_certified")) != TYPE_BOOL or typeof(s.get("reward_enabled")) != TYPE_BOOL:
		return _bad("RELEASE_OR_REWARD_TAMPER")
	if s["release_certified"] or s["reward_enabled"]:
		return _bad("RELEASE_OR_REWARD_TAMPER")
	if typeof(s.get("players")) != TYPE_ARRAY: return _bad("INVALID_PLAYERS")
	if s["players"].size() != 2: return _bad("PLAYER_COUNT")
	if not Command.whole(s.get("seed")) or s["seed"] < 0:
		return _bad("INVALID_SEED")
	for key in ["phase", "revision", "round", "seat", "winner"]:
		if not Command.whole(s.get(key)):
			return _bad("INVALID_"+key)
	if int(s["phase"]) < 0 or int(s["phase"]) > 6 or int(s["seat"]) not in [0,1]:
		return _bad("BAD_PHASE_OR_ACTOR")
	if int(s["round"]) < 1 or int(s["revision"]) < 0: return _bad("NEGATIVE_REVISION")
	if int(s["winner"]) not in [-1,0,1]: return _bad("INVALID_WINNER")
	for key in ["action_log", "events", "initial_deck_ids"]:
		if s.has(key) and typeof(s[key]) != TYPE_ARRAY: return _bad("INVALID_"+key.to_upper())
	if not s.has("action_log") or not s.has("events"): return _bad("MISSING_ACTION_HISTORY")
	var log: Array = s["action_log"]
	if log.size() != int(s["revision"]) or log.size() > ACTION_LIMIT:
		return _bad("MISSING_OR_OVERSIZED_ACTION_LOG")
	if s.get("events", []).size() != log.size(): return _bad("EVENT_REVISION_MISMATCH")
	if typeof(s.get("units")) != TYPE_ARRAY or typeof(s.get("sites")) != TYPE_ARRAY:
		return _bad("INVALID_ZONES")
	if typeof(s.get("attachments")) != TYPE_ARRAY: return _bad("INVALID_ATTACHMENTS")
	for zone in ["units", "sites", "attachments"]:
		for item in s[zone]:
			if typeof(item) != TYPE_DICTIONARY: return _bad("INVALID_ZONE_ENTRY")
			var owner_key: String = "owner" if zone == "units" else "controller"
			if not Command.whole(item.get(owner_key)) or int(item[owner_key]) not in [0,1]:
				return _bad("INVALID_ZONE_OWNER")
	for i in range(2):
		if typeof(s["players"][i]) != TYPE_DICTIONARY: return _bad("INVALID_PLAYER")
		var p: Dictionary = s["players"][i]
		if not Command.whole(p.get("seat")) or p["seat"] != i: return _bad("PLAYER_SEAT_MISMATCH")
		if typeof(p.get("faction")) != TYPE_STRING: return _bad("INVALID_PLAYER_FACTION")
		for key in ["sinew","sigil","oath","marks","heat"]:
			if not Command.whole(p.get(key)) or p[key] < 0:
				return _bad("INVALID_BALANCE")
		for zone in ["hand","deck","discard"]:
			if typeof(p.get(zone)) != TYPE_ARRAY: return _bad("INVALID_CARD_ZONE")
		var total: int = p["hand"].size() + p["deck"].size() + p["discard"].size()
		for u in s["units"]:
			if int(u.get("owner",-1)) == i: total += 1
		for site in s["sites"]:
			if int(site.get("controller",-1)) == i: total += 1
		for attachment in s["attachments"]:
			if int(attachment.get("controller",-1)) == i: total += 1
		if total != 36: return _bad("CARD_CONSERVATION_FAILED")
	if int(s["winner"]) >= 0 and int(s["players"][int(s["winner"])]["marks"]) < 10:
		return _bad("FALSE_WINNER")
	return {"ok": true}

static func replay(saved_state: Dictionary) -> Dictionary:
	var validation: Dictionary = _validate(saved_state)
	if not validation["ok"]: return validation
	var custom_decks: Array = saved_state.get("initial_deck_ids", [])
	if not custom_decks.is_empty():
		if custom_decks.size()!=2 or typeof(custom_decks[0])!=TYPE_ARRAY or typeof(custom_decks[1])!=TYPE_ARRAY:
			return _bad("SAVE_INITIAL_DECKS_INVALID")
		for deck in custom_decks:
			for card_id in deck:
				if typeof(card_id) != TYPE_STRING: return _bad("SAVE_INITIAL_DECKS_INVALID")
	var setup: Dictionary = Match.create(int(saved_state["seed"]),
		str(saved_state["players"][0]["faction"]), str(saved_state["players"][1]["faction"]),
		custom_decks)
	if not setup.get("ok",false): return _bad("REPLAY_SETUP_FAILED")
	var current: Dictionary = setup["state"]
	var actions: Array = saved_state["action_log"]
	for ix in range(actions.size()):
		if typeof(actions[ix]) != TYPE_DICTIONARY: return _bad("INVALID_ACTION")
		if str(actions[ix].get("type",""))=="ATTACK":
			return _bad("LEGACY_ATTACK_SAVE_UNSUPPORTED_DEFENDER_CHOICE_MISSING")
		var action: Dictionary = actions[ix].duplicate(true)
		if not Command.whole(action.get("seat")) or not Command.whole(action.get("revision")):
			return _bad("REPLAY_ACTION_MALFORMED")
		action["seat"] = int(action["seat"])
		action["revision"] = int(action["revision"])
		if action["revision"] != int(current["revision"]):
			return _bad("REPLAY_SEQUENCE_BROKEN")
		var response: Dictionary = Match.apply(current,action)
		if not response.get("ok",false): return _bad("REPLAY_ACTION_INVALID_AT_"+str(ix))
		current = response["state"]
	var expected:Dictionary=saved_state.duplicate(true)
	if not expected.has("priority_queue"):expected["priority_queue"]=[]
	if not expected.has("pending_attack"):expected["pending_attack"]={}
	if _hash(current) != _hash(expected):
		return _bad("REPLAY_STATE_DIVERGENCE")
	return {"ok": true, "state": current}

static func pack(s: Dictionary) -> Dictionary:
	var validation: Dictionary = _validate(s)
	if not validation["ok"]: return validation
	var proof: Dictionary = replay(s)
	if not proof["ok"]: return proof
	var catalog: Dictionary = Source.catalog()
	if catalog.is_empty(): return _bad("MISSING_SOURCE_CATALOG")
	var payload: String = JSON.stringify(_normalized(s))
	var wrapper: Dictionary = {
		"schema": VERSION, "catalog_sha256": str(catalog["source_sha256"]),
		"payload_sha256": payload.sha256_text(),
		"payload": payload
	}
	return {"ok": true,"serialized":JSON.stringify(wrapper)}

static func unpack(raw: String) -> Dictionary:
	if raw.length() < 20 or raw.to_utf8_buffer().size() > SIZE_LIMIT:
		return _bad("SAVE_SIZE_INVALID")
	var wrapper: Variant = JSON.parse_string(raw)
	if typeof(wrapper) != TYPE_DICTIONARY: return _bad("INVALID_SAVE_JSON")
	if wrapper.get("schema") != VERSION: return _bad("UNSUPPORTED_SAVE_VERSION")
	var catalog: Dictionary = Source.catalog()
	if str(wrapper.get("catalog_sha256","")) != str(catalog.get("source_sha256","")):
		return _bad("CANONICAL_CARD_DATA_CHANGED")
	for key in ["payload", "payload_sha256", "catalog_sha256"]:
		if typeof(wrapper.get(key)) != TYPE_STRING: return _bad("INVALID_SAVE_WRAPPER")
	var payload: String = wrapper["payload"]
	if payload.sha256_text() != str(wrapper.get("payload_sha256","")):
		return _bad("SAVE_CHECKSUM_MISMATCH")
	var s: Variant = JSON.parse_string(payload)
	if typeof(s) != TYPE_DICTIONARY: return _bad("INVALID_SAVE_STATE")
	return replay(s)

static func _allowed_path(path: String) -> bool:
	var prefix := "user://kudurru/"
	return path.begins_with(prefix) and path.simplify_path().begins_with(prefix) and not path.get_file().is_empty()

static func save(s: Dictionary, path: String = SLOT) -> Dictionary:
	if not _allowed_path(path): return _bad("OUTSIDE_ALLOWED_SAVE_FOLDER")
	var packed: Dictionary = pack(s)
	if not packed["ok"]: return packed
	var folder: String = path.get_base_dir()
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder)) != OK:
		return _bad("SAVE_DIRECTORY_CREATION_FAILED")
	var temp: String = path + ".tmp"
	var file := FileAccess.open(temp,FileAccess.WRITE)
	if file == null: return _bad("SAVE_WRITE_OPEN_FAILED")
	file.store_string(packed["serialized"])
	file.flush()
	file.close()
	var absolute: String = ProjectSettings.globalize_path(path)
	var temp_abs: String = ProjectSettings.globalize_path(temp)
	var backup_abs: String = absolute + ".bak"
	if FileAccess.file_exists(path):
		var copy_error: Error = DirAccess.copy_absolute(absolute, backup_abs)
		if copy_error != OK: return _bad("SAVE_BACKUP_FAILED")
		var del_error: Error = DirAccess.remove_absolute(absolute)
		if del_error != OK: return _bad("SAVE_REPLACE_BLOCKED")
	var rename_error: Error = DirAccess.rename_absolute(temp_abs,absolute)
	if rename_error != OK: return _bad("SAVE_ATOMIC_RENAME_FAILED")
	return {"ok": true,"path":path,"revision":s["revision"]}

static func load(path: String = SLOT) -> Dictionary:
	if not _allowed_path(path): return _bad("OUTSIDE_ALLOWED_SAVE_FOLDER")
	if not FileAccess.file_exists(path): return _bad("SAVE_NOT_FOUND")
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null: return _bad("SAVE_UNREADABLE")
	if file.get_length() > SIZE_LIMIT:
		file.close()
		return _bad("SAVE_TOO_LARGE")
	var content: String = file.get_as_text()
	file.close()
	return unpack(content)
