extends SceneTree
const Decks = preload("res://scripts/deck_registry.gd")
const Match = preload("res://scripts/match_integrator.gd")
const Source = preload("res://scripts/real_effects.gd")
const TEMP_NAME := "M10_Test_Deck"
var passed: int=0
var failed: int=0
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:
		failed+=1
		printerr("FAIL: "+label)
func ids_from(cards:Array)->Array:
	var ids:Array=[]
	for c in cards:ids.append(str(c["card_id"]))
	return ids
func pure(faction:String)->Array:
	var catalog:Dictionary=Source.catalog()
	var groups:Dictionary={"Character":[],"Site":[],"Pet":[],"Relic":[],"Edict":[]}
	for c in catalog["cards"]:
		if c["owner_faction"]!=faction:continue
		var family:String=str(c["card_family"])
		if not groups.has(family):continue
		if family=="Character" and c["rarity"] not in ["Common","Uncommon","Rare"]:continue
		groups[family].append(str(c["card_id"]))
	var out:Array=[]
	for id in groups["Character"].slice(0,27):out.append(id)
	for id in groups["Site"].slice(0,2):out.append(id)
	for id in groups["Pet"].slice(0,2):out.append(id)
	for id in groups["Relic"].slice(0,2):out.append(id)
	for id in groups["Edict"].slice(0,3):out.append(id)
	return out
func _initialize()->void:
	run()
	print("KUDURRU_M10_DECK_REGISTRY passed=%d failed=%d" % [passed,failed])
	quit(0 if failed==0 else 1)
func run()->void:
	var catalog:Dictionary=Source.catalog()
	check(catalog["record_count"]==754,"full 754 real card source")
	check(Decks.APPROVED_ULTRA_IDS==["36","255"],"actual Ultra identities retained")
	for faction in Match.FACTIONS:
		var sample:Array=ids_from(Match._deck(faction))
		var report:Dictionary=Decks.validate_ids(sample,true)
		check(report["ok"],"legal candidate deck in "+faction)
		check(report["effect_ready"],"every candidate effect source verified "+faction)
		check(report["count"]==36,"36 cards "+faction)
		check(report["composition"]=="mixed","source legal faction splashes "+faction)
		var single:Array=pure(faction)
		check(single.size()==36,"construct exact pure deck "+faction)
		report=Decks.validate_ids(single)
		check(report["ok"],"pure Standard composition "+faction)
		check(report["composition"]=="pure","pure faction recognized "+faction)
		check(not report["pure_faction_bonus_active"],"unapproved pure faction bonus absent "+faction)
		check(not Decks.validate_ids(single,true)["ok"],"unsupported effect not secretly playable "+faction)
	var card:Dictionary=Source.find_card(catalog,"255")
	check(card["rarity"]=="Ultra" and card["card_name"]=="Adamu","Ultra Adamu source")
	var ultra:Array=ids_from(Match._deck(Match.FACTIONS[0]))
	ultra[0]="255"
	check(Decks.validate_ids(ultra)["ok"],"legal source Ultra by canonical identity")
	check(not Decks.validate_ids(ultra,true)["ok"],"Ultra effects excluded from preview")
	var base:Array=ids_from(Match._deck(Match.FACTIONS[0]))
	check(Decks.validate_ids(base.slice(1))["errors"].has("DECK_SIZE_36"),"wrong count")
	var bad:Array=base.duplicate()
	bad[0]="DOES-NOT-EXIST"
	check(Decks.validate_ids(bad)["errors"].has("UNKNOWN_SOURCE_CARD"),"unknown card refused")
	bad=base.duplicate()
	bad[0]=base[1]
	check(Decks.validate_ids(bad)["errors"].has("COPY_LIMIT") or Decks.validate_ids(bad)["ok"],"copy limits bounded")
	bad=base.duplicate()
	for i in range(36):bad[i]=base[0]
	check(Decks.validate_ids(bad)["errors"].has("COPY_LIMIT"),"thirty-six copies denied")
	check(not Decks.file_path("../stolen").length()>0,"path traversal rejected")
	check(Decks.file_path("Deck_01")=="user://kudurru/decks/Deck_01.json","safe local deck path")
	var saved:Dictionary=Decks.save(TEMP_NAME,base)
	check(saved.get("ok",false),"legal deck saved")
	var loaded:Dictionary=Decks.load(TEMP_NAME)
	check(loaded.get("ok",false),"deck reloaded with source SHA")
	if loaded["ok"]:
		check(loaded["ids"]==base,"identity-preserving decklist roundtrip")
		check(loaded["report"]["effect_ready"],"candidate readiness retained")
	check(Decks.names().has(TEMP_NAME),"saved decks discoverable")
	check(Decks.save("../escape",base)["error"]=="INVALID_DECK_NAME","save traversal blocked")
	var location:String=Decks.file_path(TEMP_NAME)
	var obj:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(location))
	obj["card_ids"][0]="another-card"
	var f:=FileAccess.open(location,FileAccess.WRITE)
	f.store_string(JSON.stringify(obj))
	f.close()
	check(Decks.load(TEMP_NAME)["error"]=="DECK_CHECKSUM_MISMATCH","tampered deck file rejected")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(location))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(location+".bak"))
