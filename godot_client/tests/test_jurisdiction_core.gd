extends SceneTree
const Jur = preload("res://scripts/jurisdiction_core.gd")
var passed:int=0
var failed:int=0
func check(ok:bool,name:String)->void:
	if ok:passed+=1
	else:
		failed+=1
		printerr("FAIL: "+name)
func _initialize()->void:
	_run()
	print("KUDURRU_M9_JURISDICTION passed=%d failed=%d" % [passed,failed])
	quit(0 if failed==0 else 1)
func _run()->void:
	check(Jur.setup(["Warfield"])["error"]=="EXACTLY_TWO_DISTINCT_ACTIVE_FIELDS","two active field requirement")
	check(Jur.setup(["Warfield","Warfield"])["error"]=="EXACTLY_TWO_DISTINCT_ACTIVE_FIELDS","no duplicate field")
	check(Jur.setup(["Warfield","Skylight"])["error"]=="UNKNOWN_FIELD_TAG","only four printed field tags")
	var built:Dictionary=Jur.setup(["Threshold","Warfield"])
	check(built["ok"],"two canonical fields active")
	var s:Dictionary=built["state"]
	check(Jur.line(s,{"id":"L1","source_id":"222","from":"Warfield","to":"Warfield","controller":0})["error"]=="LINE_ENDPOINTS_NOT_ACTIVE","valid endpoints required")
	check(Jur.line(s,{"id":"L1","source_id":"999","from":"Threshold","to":"Warfield","controller":0})["error"]=="UNSUPPORTED_LINE_SOURCE","source hash required")
	var created:Dictionary=Jur.line(s,{"id":"L1","source_id":"222","from":"Threshold","to":"Warfield","controller":0})
	check(created["ok"],"real Threshold Stair source line")
	s=created["state"]
	check(Jur.line(s,{"id":"L1","source_id":"222","from":"Threshold","to":"Warfield","controller":0})["error"]=="DUPLICATE_LINE_ID","no duplicate line ID")
	var command:Dictionary={"controller":1,"revision":s["revision"],"line_id":"L1","from":"Warfield","to":"Threshold","pay_oath":0,"player":{"oath":2}}
	var reached:Dictionary=Jur.cross(s,command)
	check(reached["ok"],"valid source-line crossing")
	check(reached["statuses"]["staggered"],"Threshold Stair applies printed Stagger")
	check(not reached["statuses"]["silenced_until_turn_end"],"no fabricated Silence without Salt Covenant")
	check(reached["player"]["oath"]==2,"unpaid crossing leaves resource intact")
	command["pay_oath"]=1
	reached=Jur.cross(s,command)
	check(reached["ok"],"pay to avoid Threshold Stair")
	check(not reached["statuses"]["staggered"],"printed payment prevents Stagger")
	check(reached["player"]["oath"]==1,"exact one Oath paid")
	check(Jur.cross(s,command.merged({"revision":-1},true))["error"]=="STALE_REVISION","revision replay blocked")
	check(Jur.cross(s,command.merged({"player":{"oath":0}},true))["error"]=="UNPAYABLE_OR_EXCESS_TOLL","no negative resource")
	check(Jur.cross(s,command.merged({"line_id":"fake"},true))["error"]=="NO_VERIFIED_LINE","nonexistent Line denied")
	var law:Dictionary=Jur.covenant(s,0)
	check(law["ok"],"source-hashed Salt Covenant installed")
	s=law["state"]
	command["revision"]=s["revision"]
	command["pay_oath"]=1
	reached=Jur.cross(s,command)
	check(reached["ok"],"two source geasa compose")
	check(reached["statuses"]["staggered"]!=reached["statuses"]["silenced_until_turn_end"],"paying only 1 of 2 leaves an effect")
	command["pay_oath"]=2
	reached=Jur.cross(s,command)
	check(reached["ok"],"both geasa tolls can be paid")
	check(not reached["statuses"]["staggered"] and not reached["statuses"]["silenced_until_turn_end"],"payment satisfies both")
	check(reached["player"]["oath"]==0,"exact two Oath resources spent")
	command["pay_oath"]=0
	reached=Jur.cross(s,command)
	check(reached["statuses"]["staggered"] and reached["statuses"]["silenced_until_turn_end"],"unpaid geasa apply independently")
	var nails:Dictionary=Jur.setup(["Sanctuary","Warfield"])["state"]
	nails=Jur.line(nails,{"id":"N1","source_id":"232","from":"Sanctuary","to":"Warfield","controller":0})["state"]
	command={"controller":1,"revision":nails["revision"],"line_id":"N1","from":"Warfield","to":"Sanctuary","pay_oath":0,"player":{"oath":0}}
	check(Jur.cross(nails,command)["statuses"]["staggered"],"Kudurru Nail affects opposing crosser")
	command["controller"]=0
	check(not Jur.cross(nails,command)["statuses"]["staggered"],"friendly crosser immune to Nail")
	check(Jur.setup(["Threshold","Sanctuary"])["ok"],"other canonical active fields")
	check(not Jur._source("201"),"unsupported Line acceleration does not get invented")
