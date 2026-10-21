extends RefCounted
## M9 source-pinned Field/Line/Geas runtime; explicit active-Field cap 2.
## Crossings are only allowed when actual source-backed Line records exist.
## This is a reusable subsystem, NOT a claim that all jurisdiction cards work.
const Source = preload("res://scripts/real_effects.gd")
const AXES := ["Sanctuary","Threshold","Wilds","Warfield"]
const EFFECTS := {
	"205": "891f3593d6c7300a2f2b69efa85e6755be84e81eaae5a73ab5de88e93ad642d8",
	"222": "d0ae04a693def77fdec48d92f369af1de98b82b9802dd895879e2c500f376da2",
	"232": "ec92b2a282cc50e99e17cbf69452bcbf0ff00dd4ec2dce0ad9ba9a828862acbf",
}

static func fail(code:String)->Dictionary: return {"ok":false,"error":code}

static func _source(id:String)->bool:
	if not EFFECTS.has(id): return false
	var c:Dictionary=Source.find_card(Source.catalog(),id)
	return not c.is_empty() and str(c.get("rules_sha256",""))==EFFECTS[id] and (
		str(c.get("rules_text","")).replace("\r\n","\n").sha256_text()==EFFECTS[id])

# Validate persisted source objects again before reducing a crossing. A stored hash
# is evidence to verify, never permission to execute an arbitrary source record.
static func _whole(value:Variant)->bool:
	return typeof(value)==TYPE_INT or (typeof(value)==TYPE_FLOAT and is_finite(value) and value==floor(value))

static func validate(state:Dictionary)->Dictionary:
	if state.get("mode")!="SOURCE_PINNED_JURISDICTION_LAB":return fail("WRONG_MODE")
	if not state.get("active_fields") is Array or not state.get("lines") is Array or not state.get("laws") is Array or not state.get("events") is Array:
		return fail("MALFORMED_JURISDICTION_STATE")
	if not _whole(state.get("revision")) or state["revision"]<0:return fail("MALFORMED_JURISDICTION_STATE")
	var fields:Array=state["active_fields"]
	if fields.size()!=2 or fields[0]==fields[1]:return fail("MALFORMED_JURISDICTION_STATE")
	for field in fields:
		if not AXES.has(field):return fail("MALFORMED_JURISDICTION_STATE")
	var ids:Dictionary={}
	for item in state["lines"]:
		if not item is Dictionary:return fail("INVALID_LINE_RECORD")
		var source_id:String=str(item.get("source_id",""))
		if not ["222","232"].has(source_id) or not _source(source_id) or item.get("source_sha256")!=EFFECTS[source_id]:return fail("UNVERIFIED_LINE_SOURCE")
		if not item.get("id") is String or item["id"].is_empty() or ids.has(item["id"]):return fail("INVALID_LINE_RECORD")
		ids[item["id"]]=true
		if not fields.has(item.get("from")) or not fields.has(item.get("to")) or item["from"]==item["to"]:return fail("INVALID_LINE_RECORD")
		if source_id=="222" and item["from"]!="Threshold" and item["to"]!="Threshold":return fail("INVALID_LINE_RECORD")
		if not _whole(item.get("controller")) or item["controller"]<0 or item["controller"]>3:return fail("INVALID_LINE_RECORD")
	for item in state["laws"]:
		if not item is Dictionary:return fail("INVALID_LAW_RECORD")
		if item.get("source_id")!="205" or not _source("205") or item.get("source_sha256")!=EFFECTS["205"]:return fail("UNVERIFIED_LAW_SOURCE")
		if not _whole(item.get("controller")) or item["controller"]<0 or item["controller"]>3:return fail("INVALID_LAW_RECORD")
	return {"ok":true}

static func setup(fields:Array)->Dictionary:
	if fields.size()!=2 or fields[0]==fields[1]:
		return fail("EXACTLY_TWO_DISTINCT_ACTIVE_FIELDS")
	for field in fields:
		if not AXES.has(str(field)): return fail("UNKNOWN_FIELD_TAG")
	return {"ok":true,"state":{"mode":"SOURCE_PINNED_JURISDICTION_LAB",
		"active_fields":fields.duplicate(),"lines":[],"laws":[],
		"revision":0,"events":[]}}

static func line(state:Dictionary,record:Dictionary)->Dictionary:
	var valid:Dictionary=validate(state)
	if not valid["ok"]:return valid
	var source_id:String=str(record.get("source_id",""))
	if not ["222","232"].has(source_id) or not _source(source_id):
		return fail("UNSUPPORTED_LINE_SOURCE")
	var a:String=str(record.get("from",""))
	var b:String=str(record.get("to",""))
	if not state["active_fields"].has(a) or not state["active_fields"].has(b) or a==b:
		return fail("LINE_ENDPOINTS_NOT_ACTIVE")
	if source_id=="222" and a!="Threshold" and b!="Threshold":
		return fail("THRESHOLD_STAIR_MUST_BORDER_THRESHOLD")
	if not _whole(record.get("controller")):return fail("LINE_OWNER_INVALID")
	var owner:int=int(record.get("controller",-1))
	if owner<0 or owner>3:return fail("LINE_OWNER_INVALID")
	var id:String=str(record.get("id",""))
	if id.is_empty():return fail("LINE_ID_REQUIRED")
	for other in state["lines"]:
		if other["id"]==id:return fail("DUPLICATE_LINE_ID")
	var s:Dictionary=state.duplicate(true)
	s["lines"].append({"id":id,"source_id":source_id,
		"from":a,"to":b,"controller":owner,"source_sha256":EFFECTS[source_id]})
	s["revision"]+=1
	return {"ok":true,"state":s}

static func covenant(state:Dictionary,owner:int)->Dictionary:
	var valid:Dictionary=validate(state)
	if not valid["ok"]:return valid
	if owner<0 or owner>3:return fail("BAD_OWNER")
	if not _source("205"):return fail("SOURCE_TEXT_DRIFT")
	var s:Dictionary=state.duplicate(true)
	s["laws"].append({"source_id":"205","controller":owner,"source_sha256":EFFECTS["205"]})
	s["revision"]+=1
	return {"ok":true,"state":s}

static func cross(state:Dictionary,cmd:Dictionary)->Dictionary:
	var valid:Dictionary=validate(state)
	if not valid["ok"]:return valid
	if not _whole(cmd.get("revision")):return fail("STALE_REVISION")
	if int(cmd.get("revision",-1))!=int(state["revision"]):return fail("STALE_REVISION")
	if not _whole(cmd.get("controller")):return fail("BAD_SEAT")
	var seat:int=int(cmd.get("controller",-1))
	if seat<0 or seat>3:return fail("BAD_SEAT")
	var line_id:String=str(cmd.get("line_id",""))
	var direction:String=str(cmd.get("from",""))
	var destination:String=str(cmd.get("to",""))
	if not state["active_fields"].has(direction) or not state["active_fields"].has(destination) or direction==destination:
		return fail("BAD_ACTIVE_FIELD_CROSSING")
	var record:Dictionary={}
	for candidate in state["lines"]:
		if candidate["id"]==line_id:
			record=candidate
			break
	if record.is_empty():return fail("NO_VERIFIED_LINE")
	if not ((record["from"]==direction and record["to"]==destination) or
		(record["from"]==destination and record["to"]==direction)):
		return fail("LINE_NOT_ON_TRAVERSAL_PATH")
	if not cmd.get("player") is Dictionary:return fail("INVALID_RESOURCE_BALANCE")
	var player:Dictionary=cmd.get("player",{})
	if not _whole(player.get("oath")):return fail("INVALID_RESOURCE_BALANCE")
	if not _whole(cmd.get("pay_oath",0)):return fail("BAD_TOLL_PAYMENT")
	if int(player.get("oath",-1))<0:return fail("INVALID_RESOURCE_BALANCE")
	var pay:int=int(cmd.get("pay_oath",0))
	if pay<0 or pay>2:return fail("BAD_TOLL_PAYMENT")
	var needed:int=0
	var geasa:Array=[]
	# Salt Covenant imposes one Oath or Silence on *each* Line crossing.
	for law in state["laws"]:
		if law["source_id"]=="205":
			if not _source("205"):return fail("SOURCE_TEXT_DRIFT")
			needed+=1
			geasa.append("SALT_COVENANT")
	# Threshold Stair: Stagger unless paid 1 Oath.
	if record["source_id"]=="222":
		needed+=1
		geasa.append("THRESHOLD_STAIR")
	# Kudurru Nail: enemies crossing owner Line become Staggered.
	if record["source_id"]=="232" and int(record["controller"])!=seat:
		geasa.append("KUDURRU_NAIL")
	if pay>int(player["oath"]) or pay>needed:
		return fail("UNPAYABLE_OR_EXCESS_TOLL")
	var balance:int=int(player["oath"])-pay
	var remaining:int=pay
	var silence:bool=false
	var stagger:bool=false
	for effect in geasa:
		if effect=="SALT_COVENANT":
			if remaining>0:remaining-=1
			else:silence=true
		if effect=="THRESHOLD_STAIR":
			if remaining>0:remaining-=1
			else:stagger=true
		if effect=="KUDURRU_NAIL":stagger=true
	if remaining!=0:return fail("UNUSED_TOLL_NOT_ALLOWED")
	var s:Dictionary=state.duplicate(true)
	s["revision"]+=1
	var event:Dictionary={"type":"SOURCE_PINNED_LINE_CROSS",
		"line_id":line_id,"seat":seat,"from":direction,"to":destination,
		"paid_oath":pay,"silenced":silence,"staggered":stagger}
	s["events"].append(event)
	return {"ok":true,"state":s,"player":{"oath":balance},
		"statuses":{"silenced_until_turn_end":silence,"staggered":stagger},
		"event":event,"production_ready":false}
