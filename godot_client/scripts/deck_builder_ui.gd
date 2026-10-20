extends Control
## Complete 754-card deck construction, source composition validation, no fake effect claims.
const Decks = preload("res://scripts/deck_registry.gd")
const Match = preload("res://scripts/match_integrator.gd")
const Source = preload("res://scripts/real_effects.gd")
var selected_ids:Array=[]
var shown_cards:Array=[]
var search_field:LineEdit
var family_filter:OptionButton
var faction_filter:OptionButton
var preview_only:CheckButton
var card_list:ItemList
var deck_list:ItemList
var deck_name:LineEdit
var saved_decks:OptionButton
var status:Label
var deck_status:Label
var details:RichTextLabel
var starter_faction:OptionButton

func _text(parent:Node,value:String,size:int=16)->Label:
	var label:=Label.new()
	label.text=value
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",size)
	parent.add_child(label)
	return label

func _button(parent:Node,value:String,callback:Callable)->Button:
	var button:=Button.new()
	button.text=value
	button.custom_minimum_size.y=40
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _ready()->void:
	var bg:=ColorRect.new()
	bg.color=Color("#111726")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root:=VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left=18
	root.offset_top=14
	root.offset_right=-18
	root.offset_bottom=-14
	root.add_theme_constant_override("separation",10)
	add_child(root)
	var top:=HBoxContainer.new()
	top.add_theme_constant_override("separation",14)
	root.add_child(top)
	_button(top,"RETURN TO BOARD",func():get_tree().change_scene_to_file("res://scenes/main.tscn"))
	_text(top,"KUDURRU KINGS — REAL 754-CARD DECK BUILDER",24)
	_text(top,"Standard composition • unimplemented effects clearly identified",13)
	var content:=HBoxContainer.new()
	content.size_flags_vertical=Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",18)
	root.add_child(content)
	var left:=VBoxContainer.new()
	left.custom_minimum_size.x=430
	content.add_child(left)
	_text(left,"SOURCE CARD CATALOG (754)",18)
	search_field=LineEdit.new()
	search_field.placeholder_text="Search title, effect text or printed card ID"
	search_field.text_changed.connect(func(_new_text:String):_refresh_catalog())
	left.add_child(search_field)
	family_filter=OptionButton.new()
	family_filter.add_item("All card families")
	for family in Decks.Rules.FAMILIES:family_filter.add_item(family)
	family_filter.item_selected.connect(func(_idx:int):_refresh_catalog())
	left.add_child(family_filter)
	faction_filter=OptionButton.new()
	faction_filter.add_item("All five factions")
	for faction in Match.FACTIONS:faction_filter.add_item(faction)
	faction_filter.item_selected.connect(func(_idx:int):_refresh_catalog())
	left.add_child(faction_filter)
	preview_only=CheckButton.new()
	preview_only.text="Only show card effects supported in playable preview"
	preview_only.toggled.connect(func(_on:bool):_refresh_catalog())
	left.add_child(preview_only)
	card_list=ItemList.new()
	card_list.size_flags_vertical=Control.SIZE_EXPAND_FILL
	card_list.custom_minimum_size=Vector2(395,320)
	card_list.item_selected.connect(func(_index:int):_describe())
	left.add_child(card_list)
	_button(left,"ADD SELECTED CARD TO DECK",_add)
	var middle:=VBoxContainer.new()
	middle.custom_minimum_size.x=390
	content.add_child(middle)
	_text(middle,"CONSTRUCTED DECK",18)
	deck_status=_text(middle,"0/36 cards",15)
	deck_list=ItemList.new()
	deck_list.size_flags_vertical=Control.SIZE_EXPAND_FILL
	deck_list.custom_minimum_size=Vector2(340,335)
	middle.add_child(deck_list)
	_button(middle,"REMOVE SELECTED DECK CARD",_remove)
	var right:=VBoxContainer.new()
	right.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.add_child(right)
	_text(right,"PRINTED CARD RULES AND SOURCE READINESS",17)
	details=RichTextLabel.new()
	details.custom_minimum_size=Vector2(300,250)
	details.size_flags_vertical=Control.SIZE_EXPAND_FILL
	right.add_child(details)
	_text(right,"DECK SAVE / RESTORE",17)
	deck_name=LineEdit.new()
	deck_name.placeholder_text="Deck name (letters, digits, underscore, hyphen)"
	right.add_child(deck_name)
	var buttons:=HBoxContainer.new()
	right.add_child(buttons)
	_button(buttons,"SAVE LEGAL DECK",_save)
	_button(buttons,"LOAD SELECTED",_load)
	saved_decks=OptionButton.new()
	right.add_child(saved_decks)
	_text(right,"LOAD SAMPLE VERIFIED PREVIEW DECK",14)
	starter_faction=OptionButton.new()
	for faction in Match.FACTIONS:starter_faction.add_item(faction)
	right.add_child(starter_faction)
	_button(right,"LOAD VERIFIED STARTER",_starter)
	status=_text(root,
		"All 754 are source-visible. Composition validation does not certify EOE faction crosswalk or unfinished effects; unsupported decks cannot enter playable matches.",14)
	_refresh_saved()
	_refresh_catalog()
	_refresh_deck()

func _refresh_catalog()->void:
	shown_cards=[]
	card_list.clear()
	var catalog:Dictionary=Source.catalog()
	if catalog.is_empty():
		status.text="Source catalog unavailable."
		return
	var query:String=search_field.text.strip_edges().to_lower()
	for card in catalog["cards"]:
		if family_filter.selected>0 and card["card_family"]!=Decks.Rules.FAMILIES[family_filter.selected-1]:continue
		if faction_filter.selected>0 and card["owner_faction"]!=Match.FACTIONS[faction_filter.selected-1]:continue
		var allowed:bool=Decks.candidate_effect_ready(card)
		if preview_only.button_pressed and not allowed:continue
		if not query.is_empty():
			if not (str(card["card_name"]).to_lower().contains(query) or
				str(card["card_id"]).contains(query) or
				str(card["rules_text"]).to_lower().contains(query)):continue
		shown_cards.append(card)
		card_list.add_item(("● " if allowed else "○ ")+str(card["card_name"])+
			" / "+str(card["card_family"])+" / "+str(card["owner_faction"]))
	if card_list.item_count>0:card_list.select(0)
	_describe()

func _describe()->void:
	var selected:PackedInt32Array=card_list.get_selected_items()
	if selected.is_empty() or selected[0]<0 or selected[0]>=shown_cards.size():
		details.text="Select a card to inspect its printed rules."
		return
	var c:Dictionary=shown_cards[selected[0]]
	var ready:bool=Decks.candidate_effect_ready(c)
	details.text=("%s (#%s)\n%s — %s\n%s\n\nDeployment: Sinew %d / Sigil %d / Oath %d\n"
		+"Copy limit: %d\nStandard source legal: %s\nLocal preview effect: %s\n\nOriginal printed rules:\n%s") % [
		c["card_name"],c["card_id"],c["owner_faction"],c["card_family"],c["rarity"],
		int(c["cost_sinew"]),int(c["cost_sigil"]),int(c["cost_oath"]),int(c["deck_copy_limit"]),
		str(c["is_standard_legal"]),"IMPLEMENTED" if ready else "NOT YET IMPLEMENTED",
		c["rules_text"]]

func _add()->void:
	var selected:PackedInt32Array=card_list.get_selected_items()
	if selected.is_empty() or selected[0]>=shown_cards.size():return
	if selected_ids.size()>=36:
		status.text="DECK FULL: Remove a card first."
		return
	var card:Dictionary=shown_cards[selected[0]]
	var copies:int=0
	for id in selected_ids:
		if id==card["card_id"]:copies+=1
	var limit:int=mini(2,int(card["deck_copy_limit"]))
	if card["rarity"]=="SuperRare":limit=mini(limit,1)
	if copies>=limit:
		status.text="COPY LIMIT: "+str(card["card_name"])
		return
	selected_ids.append(str(card["card_id"]))
	_refresh_deck()

func _remove()->void:
	var selected:PackedInt32Array=deck_list.get_selected_items()
	if selected.is_empty() or selected[0]>=selected_ids.size():return
	selected_ids.remove_at(selected[0])
	_refresh_deck()

func _refresh_deck()->void:
	deck_list.clear()
	var catalog:Dictionary=Source.catalog()
	var supports:int=0
	var unsupported:int=0
	var counts:Dictionary={}
	for id in selected_ids:
		var c:Dictionary=Source.find_card(catalog,str(id))
		deck_list.add_item(str(c["card_name"])+" — "+str(c["card_family"]))
		counts[c["card_family"]]=int(counts.get(c["card_family"],0))+1
		if c["card_family"]=="Pet" or c["card_family"]=="Relic":supports+=1
		if not Decks.candidate_effect_ready(c):unsupported+=1
	var base:String="%d/36 | Characters %d | Sites %d | Pet+Relic %d | Unimplemented %d" % [
		selected_ids.size(),counts.get("Character",0),counts.get("Site",0),supports,unsupported]
	if selected_ids.size()!=36:
		deck_status.text=base+" | Incomplete"
		return
	var report:Dictionary=Decks.validate_ids(selected_ids)
	deck_status.text=base+" | "+(
		"LEGAL • MATCH PREVIEW READY" if report["ok"] and report["effect_ready"] else
		"LEGAL • DESIGN ONLY (effects incomplete)" if report["ok"] else
		"INVALID: "+", ".join(report["errors"]))

func _refresh_saved()->void:
	saved_decks.clear()
	for name in Decks.names():saved_decks.add_item(str(name))

func _save()->void:
	var response:Dictionary=Decks.save(deck_name.text.strip_edges(),selected_ids)
	status.text="SAVED "+deck_name.text if response.get("ok",false) else (
		"SAVE FAILED: "+str(response.get("error"))+" "+str(response.get("errors",[])))
	if response.get("ok",false):_refresh_saved()

func _load()->void:
	if saved_decks.item_count==0:return
	var response:Dictionary=Decks.load(saved_decks.get_item_text(saved_decks.selected))
	if not response.get("ok",false):
		status.text="LOAD FAILED: "+str(response.get("error"))
		return
	selected_ids=response["ids"].duplicate()
	deck_name.text=response["name"]
	status.text="LOADED: "+response["name"]
	_refresh_deck()

func _starter()->void:
	selected_ids=[]
	var cards:Array=Match._deck(Match.FACTIONS[starter_faction.selected])
	for c in cards:selected_ids.append(str(c["card_id"]))
	deck_name.text="Starter_"+Match.FACTIONS[starter_faction.selected]
	status.text="Source-verified starter: modify or save this preview-playable deck."
	_refresh_deck()
