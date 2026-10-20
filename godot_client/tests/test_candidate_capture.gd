extends SceneTree
const Core=preload("res://scripts/real_combat_core.gd")
const Capture=preload("res://scripts/candidate_capture.gd")
var passed:int=0
var failed:int=0
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:
		failed+=1
		printerr("FAIL: "+label)
func fixture(card_id:String,boss:bool=false,winner:bool=true)->Dictionary:
	var source_decks:Array=[["255"],["180"]] if winner else [["180"],["255"]]
	var u:Dictionary=Core.unit("victim",card_id,1,0)
	u["downed"]=true
	u["bound"]=true
	if boss:u["trials_won"]=["Stone","Veil","Authority"]
	var made:Dictionary=Core.create(source_decks,[u],8001)
	var s:Dictionary=made["state"]
	s["phase"]="Resolution"
	return s
func _initialize()->void:
	_run()
	print("KUDURRU_M9_CANDIDATE_CAPTURE passed=%d failed=%d" % [passed,failed])
	quit(0 if failed==0 else 1)
func _run()->void:
	var normal:Dictionary=fixture("273")
	check(Capture.eligible(normal,0,"victim")["ok"],"Bound Downed normal Character legal")
	check(Capture.resolve(normal,0,"victim","UNSPECIFIED")["error"]=="CAPTURE_OUTCOME_NOT_CANON_APPROVED","no silent canon assertion")
	var p:Dictionary=Capture.resolve(normal,0,"victim","AUTHORITY_FACE_OFF_CANDIDATE")
	check(p["ok"],"deterministic contest adjudicated")
	if not p["ok"]:return
	check(p["event"]["success"],"candidate Authority victory")
	check(p["event"]["marks"]==1,"Character capture exactly 1 Mark")
	check(p["state"]["units"][0]["captured"],"target marked captured")
	check(p["state"]["units"][0]["owner"]==1,"original owner unchanged")
	check(p["state"]["units"][0]["defeated"],"captured card no longer active")
	check(p["event"]["account_reward"]=="PENDING_EXTERNAL_CERTIFIED_MATCH_AUTHORITY","no unsanctioned item grant")
	check(not p["receipt_issued"] and not p["production_ready"],"no fake production receipts")
	check(Capture.resolve(p["state"],0,"victim","AUTHORITY_FACE_OFF_CANDIDATE")["error"]=="CAPTURE_NOT_ELIGIBLE","cannot replay reward")
	var failure:Dictionary=fixture("273",false,false)
	p=Capture.resolve(failure,0,"victim","AUTHORITY_FACE_OFF_CANDIDATE")
	check(p["ok"] and not p["event"]["success"],"source Face-off can fail")
	check(p["state"]["units"][0]["defeated"],"failure causes Defeated")
	check(p["event"]["marks"]==1,"ordinary failed capture plain defeat gives 1 Mark")
	check(p["event"]["account_reward"]=="NONE","failed attempt grants no collectible")
	var boss:Dictionary=fixture("16",true)
	check(Capture.eligible(boss,0,"victim")["ok"],"distinct 3 Boss Trials eligible")
	boss["units"][0]["trials_won"]=["Stone","Stone","Veil"]
	check(Capture.eligible(boss,0,"victim")["error"]=="BOSS_TRIALS_INCOMPLETE","repeated Trial axis never counts")
	boss["units"][0]["trials_won"]=["Stone","Veil","Authority"]
	p=Capture.resolve(boss,0,"victim","AUTHORITY_FACE_OFF_CANDIDATE")
	check(p["ok"] and p["event"]["success"],"trial-complete Boss source contest")
	check(p["event"]["marks"]==2,"Boss capture exactly 2 Marks")
	check(p["state"]["units"][0]["owner"]==1,"Boss remains loser-owned")
	check(Capture.resolve(boss,1,"victim","AUTHORITY_FACE_OFF_CANDIDATE")["error"]=="NOT_ACTIVE_SEAT","wrong seat cannot try")
	var premature:Dictionary=boss.duplicate(true)
	premature["phase"]="Battle"
	check(Capture.eligible(premature,0,"victim")["error"]=="RESOLUTION_LAB_ONLY","cannot attempt in Battle phase")
	var not_bound:Dictionary=boss.duplicate(true)
	not_bound["units"][0]["bound"]=false
	check(Capture.eligible(not_bound,0,"victim")["error"]=="CAPTURE_NOT_ELIGIBLE","Binding mandatory")
