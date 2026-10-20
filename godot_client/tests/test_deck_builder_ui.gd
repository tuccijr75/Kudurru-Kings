extends SceneTree
const Match=preload("res://scripts/match_integrator.gd")
const Decks=preload("res://scripts/deck_registry.gd")
const Storage=preload("res://scripts/match_storage.gd")
const Editor=preload("res://scripts/deck_builder_ui.gd")
const UI=preload("res://scripts/real_match_ui.gd")
var passed:int=0
var failed:int=0
const NAME:="M10_UI_Save_Test"
func check(condition:bool,label:String)->void:
	if condition:passed+=1
	else:
		failed+=1
		printerr("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
	var editor:Control=Editor.new()
	root.add_child(editor)
	check(editor.card_list.item_count==754,"all 754 cards discoverable in source deck builder")
	check(editor.selected_ids.is_empty(),"initial deck empty")
	editor.search_field.text="421"
	editor._refresh_catalog()
	check(editor.card_list.item_count>0,"source ID filter")
	editor.search_field.text=""
	editor._refresh_catalog()
	editor.preview_only.button_pressed=true
	editor._refresh_catalog()
	check(editor.card_list.item_count>420 and editor.card_list.item_count<754,
		"real implemented-only filter distinguishes unsupported cards")
	editor.preview_only.button_pressed=false
	editor._refresh_catalog()
	editor.starter_faction.select(2)
	editor._starter()
	check(editor.selected_ids.size()==36,"source-verified starter deck constructed")
	check(Decks.validate_ids(editor.selected_ids,true)["ok"],"starter can enter match")
	editor.deck_name.text=NAME
	editor._save()
	check(editor.status.text.begins_with("SAVED"),"valid deck persisted")
	check(Decks.names().has(NAME),"custom saved deck is discoverable")
	editor.selected_ids.clear()
	editor._refresh_deck()
	editor._refresh_saved()
	check(editor.saved_decks.item_count>0,"UI lists saved decks")
	var saved_idx:int=-1
	for i in range(editor.saved_decks.item_count):
		if editor.saved_decks.get_item_text(i)==NAME:saved_idx=i
	check(saved_idx>=0,"saved deck name is exact")
	if saved_idx>=0:
		editor.saved_decks.select(saved_idx)
		editor._load()
		check(editor.selected_ids.size()==36,"UI can load same exact 36-card IDs")
	var ids:Array=editor.selected_ids.duplicate()
	editor.deck_list.select(0)
	editor._remove()
	check(editor.selected_ids.size()==35,"UI removes selected card")
	editor._refresh_catalog()
	editor.card_list.select(0)
	editor._add()
	check(editor.selected_ids.size()==36,"UI can add a card after removal")
	editor.free()
	var game:Dictionary=Match.create(9191,"SkyloomTemple","BorderstoneGuild",[ids,[]])
	check(game["ok"],"saved custom deck playable against an opponent")
	if game["ok"]:
		var s:Dictionary=game["state"]
		check(s["initial_deck_ids"][0]==ids,"exact saved identity vector preserved for replay")
		check(s["initial_deck_ids"][1].size()==36,"opponent default source deck preserved")
		var snap:Dictionary=Storage.pack(s)
		check(snap["ok"],"custom match save replays independently")
		if snap["ok"]:
			check(Storage.unpack(snap["serialized"])["ok"],"custom match save restored")
		for i in range(2):
			var step:Dictionary=Match.apply(s,{"type":"KEEP","seat":i,"revision":s["revision"]})
			check(step["ok"],"setup with custom deck")
			s=step["state"]
		var step:Dictionary=Match.apply(s,{"type":"ADVANCE","seat":0,"revision":s["revision"]})
		check(step["ok"],"custom deck match advances turn")
		s=step["state"]
		check(Storage.replay(s)["ok"],"custom deck game state deterministic")
	var game_ui:Control=UI.new()
	root.add_child(game_ui)
	game_ui._refresh_saved_decks()
	check(game_ui.saved_deck_names.has(NAME),"match UI exposes saved custom deck")
	var idx:int=game_ui.saved_deck_names.find(NAME)
	if idx>0:
		game_ui.saved_deck_pick.select(idx)
		game_ui.player_faction_pick.select(2)
		game_ui.enemy_faction_pick.select(0)
		game_ui._restart()
		check(game_ui.state["initial_deck_ids"][0]==ids,"match UI launches exact source-backed saved deck")
		check(game_ui.state["players"][0]["faction"]=="SkyloomTemple","human faction selection respected")
	game_ui.free()
	var file:String=Decks.file_path(NAME)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(file+".bak"))
	print("KUDURRU_M10_DECK_UI_MATCH passed=%d failed=%d" % [passed,failed])
	quit(0 if failed==0 else 1)
