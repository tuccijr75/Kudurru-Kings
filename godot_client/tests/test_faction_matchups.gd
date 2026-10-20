extends SceneTree
const Match = preload("res://scripts/match_integrator.gd")
const Store = preload("res://scripts/match_storage.gd")
var passed := 0
var failed := 0
func check(ok: bool,text_value: String) -> void:
	if ok: passed+=1
	else:
		failed+=1
		printerr("FAIL: "+text_value)
func _initialize() -> void:
	_run()
	print("KUDURRU_M8_FACTION_MATCHUPS passed=%d failed=%d" % [passed,failed])
	quit(0 if failed==0 else 1)
func _run() -> void:
	check(Match.FACTIONS.size()==5, "five lore factions")
	for a in Match.FACTIONS:
		for b in Match.FACTIONS:
			var result: Dictionary = Match.create(881,str(a),str(b))
			check(result["ok"],"legal 36-card decks "+str(a)+" vs "+str(b))
			if not result["ok"]: continue
			var s: Dictionary = result["state"]
			check(s["players"][0]["faction"]==a and s["players"][1]["faction"]==b,"chosen identities persist")
			check(s["players"][0]["hand"].size()==6,"first player opening hand six")
			check(s["players"][1]["hand"].size()==6,"other opening hand six")
			var saved: Dictionary=Store.pack(s)
			check(saved["ok"],"replay valid for "+str(a)+"/"+str(b))
			if saved["ok"]:
				var unwrapped: Dictionary=Store.unpack(saved["serialized"])
				check(unwrapped["ok"],"roundtrip faction pair "+str(a)+"/"+str(b))
	check(Match.create(1,"FakeFaction","BorderstoneGuild")["error"]=="UNKNOWN_FACTION","unknown player faction denied")
	check(Match.create(1,"BorderstoneGuild","FakeFaction")["error"]=="UNKNOWN_FACTION","unknown opponent denied")
