extends SceneTree
const Match = preload("res://scripts/match_integrator.gd")
const Core = preload("res://scripts/real_combat_core.gd")
var pass_count := 0
var fail_count := 0
func check(ok: bool, label: String) -> void:
	if ok: pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL: " + label)
func _initialize() -> void:
	run()
	print("KUDURRU_M7_REAL_PASSIVES passed=%d failed=%d" % [pass_count,fail_count])
	quit(0 if fail_count==0 else 1)
func run() -> void:
	var s: Dictionary = Match.create(73)["state"]
	var preview: Dictionary = {"sites":[],"attachments":[]}
	var unit: Dictionary = Core.unit("HOST","421",0,0,"Warfield")
	check(Core._owned_passive_bonus(preview,unit,"Stone",true)==0,"no phantom passive modifiers")
	check(Core._owned_passive_bonus(preview,unit,"Veil",true)==0,"no unrelated Veil bonus")
	preview["sites"].append({"card_id":"216","controller":0,"field":"Warfield"})
	check(Core._owned_passive_bonus(preview,unit,"Stone",true)==1,"Bitumen Furnace friendly Warfield attack +1")
	check(Core._owned_passive_bonus(preview,unit,"Stone",false)==0,"Furnace not defensive")
	preview["attachments"].append({"card_id":"239","controller":0,"host_uid":"HOST"})
	check(Core._owned_passive_bonus(preview,unit,"Stone",true)==2,"Bitumen Harness attack +1 stacks with Site")
	check(Core._owned_passive_bonus(preview,unit,"Stone",false)==0,"Harness does not aid defense")
	preview["attachments"].append({"card_id":"254","controller":0,"host_uid":"HOST"})
	check(Core._owned_passive_bonus(preview,unit,"Stone",true)==3,"Dust Mite active in controlled Field")
	check(Core._owned_passive_bonus(preview,unit,"Stone",false)==1,"Dust Mite defends; other passives attack only")
	preview["sites"].clear()
	check(Core._owned_passive_bonus(preview,unit,"Stone",false)==0,"Mite requires own Field control")
	var enemy: Dictionary = Core.unit("ENEMY","421",1,0,"Warfield")
	check(Core._owned_passive_bonus(preview,enemy,"Stone",true)==0,"no opponent's passive leaks")
	var main: Dictionary = Match.create(73)["state"]
	main["players"][0]["setup_ready"]=true
	main["players"][1]["setup_ready"]=true
	main["setup_complete"]=true
	main["phase"]=3
	main["sites"].append({"card_id":"214","controller":0,"field":"Sanctuary"})
	var peek: Dictionary = Match.apply(main,{
		"seat":0,"revision":main["revision"],"type":"PEEK","target_seat":1})
	check(peek["ok"],"Mirror Archive top deck peek source executes")
	if peek["ok"]:
		check(peek["private_for_seat"]==0, "private recipient is controller")
		check(str(peek["private_card_id"]) == str(main["players"][1]["deck"][-1]["card_id"]),"actual target deck identity only")
		check(not peek["event"].has("private_card_id"),"no hidden card in shared event stream")
		check(not peek["state"]["events"][-1].has("private_card_id"),"no card leak in event state")
		check(Match.apply(peek["state"],{
			"seat":0,"revision":peek["state"]["revision"],"type":"PEEK","target_seat":1})["error"]=="MIRROR_ALREADY_USED","once a turn limit")
		var t: Dictionary = peek["state"].duplicate(true)
		t["round"] += 1
		check(Match.apply(t,{"seat":0,"revision":t["revision"],"type":"PEEK","target_seat":1})["ok"],"next round reuse allowed")
	var rejected: Dictionary = main.duplicate(true)
	rejected["sites"].clear()
	check(Match.apply(rejected,{"seat":0,"revision":rejected["revision"],"type":"PEEK","target_seat":1})["error"]=="MIRROR_ARCHIVE_REQUIRED","unauthorized peek denied")
	check(Match.apply(main,{"seat":1,"revision":main["revision"],"type":"PEEK","target_seat":1})["error"]=="NOT_ACTIVE_SEAT","opponent can't peek outside turn")
