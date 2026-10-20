extends RefCounted
## Source-owned Standard deck composition vs match-runtime effect readiness.
## All 754 source cards may be deck-designed. The live match *only* accepts
## the small effect-verified preview whitelist and never silently no-ops cards.
const Source = preload("res://scripts/real_effects.gd")
const Adj = preload("res://scripts/adjacency_rule.gd")
const Edicts = preload("res://scripts/match_edicts.gd")
const Rules = preload("res://scripts/deck_validator.gd")
const SCHEMA := "KUDURRU_SOURCE_DECK_V1"
const FOLDER := "user://kudurru/decks"
const SANDBOX_SITES := {
	"214":"d36bef97289a48543ead3b18f7744f44bd03afcec75a97fd0b84dd27bb9b8c7b",
	"216":"8a8db6ddd60bb781e6af42f2e028fde3303b919abb1be9dc59bc491a2b32fb44"
}
const SANDBOX_SUPPORT := {
	"239":"62ce231bc67c47e99832c4d8c18da701c04ecce102799bfad21eb295613f18dd",
	"241":"9d8b1b4b296c74bcd2ce75bf3c18cb49671e25728cf8cd1cb7e486a6ccd554d1",
	"254":"4d02f398201e108e7dfb95441a182f7c050564499229a1d03cbb76cf70264af4"
}
const APPROVED_ULTRA_IDS := ["36","255"]

static func _fail(code:String)->Dictionary:
	return {"ok":false,"error":code}

static func candidate_effect_ready(c:Dictionary)->bool:
	if c.is_empty() or not bool(c.get("is_standard_legal",false)):return false
	var id:String=str(c.get("card_id",""))
	if c.get("card_family")=="Character":
		return Adj.has_compiled_rule(id)
	if c.get("card_family")=="Edict":
		return Edicts.verified(id)
	var expected:String=""
	if SANDBOX_SITES.has(id): expected=SANDBOX_SITES[id]
	elif SANDBOX_SUPPORT.has(id):expected=SANDBOX_SUPPORT[id]
	if expected.is_empty():return false
	return str(c.get("rules_sha256",""))==expected and (
		str(c.get("rules_text","")).replace("\r\n","\n").sha256_text()==expected)

static func validate_ids(ids:Array,require_effect_ready:bool=false)->Dictionary:
	var catalog:Dictionary=Source.catalog()
	if catalog.is_empty():return _fail("CANONICAL_CATALOG_UNAVAILABLE")
	if ids.size()!=36:return {"ok":false,"errors":["DECK_SIZE_36"],"count":ids.size()}
	var by_id:Dictionary={}
	var by_name:Dictionary={}
	var families:Dictionary={}
	var factions:Dictionary={}
	var errors:Array=[]
	var contains_lock:bool=false
	var decoded:Array=[]
	for raw in ids:
		if typeof(raw)!=TYPE_STRING and typeof(raw)!=TYPE_INT:
			errors.append("INVALID_CARD_ID")
			continue
		var id:String=str(raw)
		var card:Dictionary=Source.find_card(catalog,id)
		if card.is_empty():
			errors.append("UNKNOWN_SOURCE_CARD")
			continue
		if not bool(card.get("is_standard_legal",false)) or bool(card.get("scenario_only",false)):
			errors.append("NOT_STANDARD_LEGAL")
		if card["card_family"] not in Rules.FAMILIES or card["rarity"] not in Rules.RARITIES:
			errors.append("UNKNOWN_CARD_CLASS")
		if card["owner_faction"] not in Rules.FACTIONS:
			errors.append("UNKNOWN_FACTION")
		if card["rarity"]=="Ultra" and id not in APPROVED_ULTRA_IDS:
			errors.append("ULTRA_IDENTITY")
		if require_effect_ready and not candidate_effect_ready(card):
			errors.append("EFFECT_NOT_IMPLEMENTED_FOR_CANDIDATE")
		var name:String=str(card["card_name"])
		by_id[id]=int(by_id.get(id,0))+1
		by_name[name]=int(by_name.get(name,0))+1
		families[card["card_family"]]=int(families.get(card["card_family"],0))+1
		factions[card["owner_faction"]]=true
		if bool(card.get("requires_faction_lock",false)):
			contains_lock=true
		var cap:int=mini(2,int(card.get("deck_copy_limit",2)))
		if card["rarity"]=="SuperRare":cap=mini(cap,1)
		if by_id[id]>cap or by_name[name]>cap:
			errors.append("COPY_LIMIT")
		var owned:Dictionary=card.duplicate(true)
		owned["playable"]=candidate_effect_ready(card)
		decoded.append(owned)
	if int(families.get("Character",0))<12:errors.append("MIN_12_CHARACTERS")
	if int(families.get("Site",0))<2:errors.append("MIN_2_SITES")
	if int(families.get("Pet",0))+int(families.get("Relic",0))<4:errors.append("MIN_4_SUPPORT")
	if int(families.get("Boss",0))>3:errors.append("MAX_3_BOSSES")
	if int(families.get("Name",0))>3:errors.append("MAX_3_NAMES")
	if int(families.get("HostSigil",0))>1:errors.append("MAX_1_HOST_SIGIL")
	if contains_lock and factions.size()>1:errors.append("FACTION_LOCK_REQUIRES_CARD_SPECIFIC_REVIEW")
	if factions.size()>1:
		for card in decoded:
			if not bool(card.get("allowed_splash",false)):
				errors.append("FACTION_SPLASH_NOT_ALLOWED")
				break
	var unique:Array=[]
	for e in errors:
		if not unique.has(e):unique.append(e)
	return {
		"ok":unique.is_empty(),"errors":unique,
		"count":ids.size(),"families":families,
		"factions":factions.keys(),
		"composition":"pure" if factions.size()==1 else "mixed",
		"pure_faction_bonus_active":false,
		"effect_ready":decoded.size()==36 and decoded.all(func(c):return bool(c["playable"])),
		"cards":decoded,
		"source_master_sha256":str(catalog["source_sha256"])
	}

static func file_path(deck_name:String)->String:
	if deck_name.length()<1 or deck_name.length()>50:return ""
	for letter in deck_name:
		if not ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_" as String).contains(letter):
			return ""
	return FOLDER+"/"+deck_name+".json"

static func save(deck_name:String,ids:Array)->Dictionary:
	var path:String=file_path(deck_name)
	if path.is_empty():return _fail("INVALID_DECK_NAME")
	var report:Dictionary=validate_ids(ids,false)
	if not report.get("ok",false):
		return {"ok":false,"error":"INVALID_STANDARD_DECK","errors":report.get("errors",[])}
	var payload:Dictionary={
		"schema":SCHEMA,
		"name":deck_name,
		"source_master_sha256":report["source_master_sha256"],
		"card_ids":ids.duplicate()
	}
	var json:String=JSON.stringify(payload)
	payload["digest_sha256"]=json.sha256_text()
	var directory:String=ProjectSettings.globalize_path(FOLDER)
	if DirAccess.make_dir_recursive_absolute(directory)!=OK:return _fail("SAVE_DIR_FAILED")
	var temp:String=path+".tmp"
	var f:=FileAccess.open(temp,FileAccess.WRITE)
	if f==null:return _fail("WRITE_FAILED")
	f.store_string(JSON.stringify(payload))
	f.flush()
	f.close()
	var dest_abs:String=ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		var backup:Error=DirAccess.copy_absolute(dest_abs,dest_abs+".bak")
		if backup!=OK:return _fail("SAVE_BACKUP_FAILED")
		if DirAccess.remove_absolute(dest_abs)!=OK:return _fail("SAVE_REPLACE_FAILED")
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temp),dest_abs)!=OK:
		return _fail("SAVE_ATOMIC_RENAME_FAILED")
	return {"ok":true,"path":path,"effect_ready":report["effect_ready"],
		"composition":report["composition"]}

static func load(deck_name:String)->Dictionary:
	var path:String=file_path(deck_name)
	if path.is_empty():return _fail("INVALID_DECK_NAME")
	if not FileAccess.file_exists(path):return _fail("DECK_NOT_FOUND")
	var f:=FileAccess.open(path,FileAccess.READ)
	if f==null:return _fail("DECK_READ_FAILED")
	if f.get_length()>32768:
		f.close()
		return _fail("DECK_TOO_LARGE")
	var obj:Variant=JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(obj)!=TYPE_DICTIONARY or obj.get("schema")!=SCHEMA:
		return _fail("DECK_SCHEMA_MISMATCH")
	var signed:Dictionary=obj.duplicate(true)
	var digest:String=str(signed.get("digest_sha256",""))
	signed.erase("digest_sha256")
	if JSON.stringify(signed).sha256_text()!=digest:
		return _fail("DECK_CHECKSUM_MISMATCH")
	if signed.get("name")!=deck_name:return _fail("DECK_IDENTITY_MISMATCH")
	var catalog:Dictionary=Source.catalog()
	if signed.get("source_master_sha256")!=catalog.get("source_sha256"):
		return _fail("DECK_SOURCE_VERSION_STALE")
	if typeof(signed.get("card_ids"))!=TYPE_ARRAY:return _fail("DECKLIST_MISSING")
	var report:Dictionary=validate_ids(signed["card_ids"])
	if not report.get("ok",false):return _fail("DECK_BECAME_ILLEGAL")
	return {"ok":true,"ids":signed["card_ids"],"report":report,"name":deck_name}

static func names()->Array:
	var directory:=DirAccess.open(FOLDER)
	if directory==null:return []
	var found:Array=[]
	directory.list_dir_begin()
	while true:
		var file:String=directory.get_next()
		if file.is_empty():break
		if file.ends_with(".json") and not directory.current_is_dir():
			var name:String=file.get_basename()
			if not file_path(name).is_empty():found.append(name)
	directory.list_dir_end()
	found.sort()
	return found
