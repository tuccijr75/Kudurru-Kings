extends RefCounted
## M12 source-hashed *response choice* reducer for Public Reckoning and Censor Audit.
## A card demanding opponent choice must never let the active player decide it.
const Source = preload("res://scripts/real_effects.gd")
const RECKONING := "182"
const AUDIT := "190"
const SOURCE_HASHES := {
	"182":"ee0e5131090e0778e9b1c4bf3bf4e239c8cadb9f902bce4e52d986bb1386f18b",
	"190":"686af0b43daf3b4d991e7e8d53c4c2f8e2da65d2e505d68089c441b8d79c60a6"
}
const CHOICE_ACTION := "CHOOSE_CONSEQUENCE"

static func fail(code:String)->Dictionary:
	return {"ok":false,"error":code}

static func verified(id:String)->bool:
	if not SOURCE_HASHES.has(id):return false
	var card:Dictionary=Source.find_card(Source.catalog(),id)
	return card.get("card_family")=="Edict" and (
		card.get("rules_sha256","")==SOURCE_HASHES[id]) and (
		str(card.get("rules_text","")).replace("\r\n","\n").sha256_text()==SOURCE_HASHES[id])

static func legal_options(state:Dictionary,seat:int,id:String)->Array:
	var out:Array=[]
	if seat<0 or seat>=state["players"].size():return out
	var p:Dictionary=state["players"][seat]
	if id==RECKONING:
		if not p["hand"].is_empty():out.append("DISCARD_CARD")
		for u in state["units"]:
			if int(u["controller"])==seat and not u["exhausted"] and not u["downed"] and not u["defeated"]:
				out.append("EXHAUST_UNIT")
				break
		if int(p["oath"])>=2:out.append("LOSE_OATH")
	elif id==AUDIT:
		for card in p["hand"]:
			if card["card_family"]=="Name":
				out.append("DISCARD_NAME")
				break
		for u in state["units"]:
			if int(u["controller"])==seat and not u["defeated"] and not bool(u["silenced"]):
				out.append("SILENCE_UNIT")
				break
	return out

static func issue(state:Dictionary,caster:int,id:String,action:Dictionary)->Dictionary:
	if not verified(id):return fail("UNVERIFIED_CHOICE_EDICT")
	if state.get("mode")!="M7_REAL_MATCH_CANDIDATE" or int(state["phase"])!=2:
		return fail("EDICTS_WINDOW_REQUIRED")
	if caster!=int(state["seat"]):return fail("NOT_ACTIVE_SEAT")
	if not state.get("priority_queue",[]).is_empty():return fail("PRIORITY_ALREADY_PENDING")
	var s:Dictionary=state.duplicate(true)
	var targeted:Array=[]
	if id==RECKONING:
		for other in range(s["players"].size()):
			if other==caster or int(s["players"][other]["heat"])<4:continue
			var options:Array=legal_options(s,other,id)
			if options.is_empty():continue
			s["priority_queue"].append({"seat":other,"caster":caster,
				"source_id":id,"options":options})
			targeted.append(other)
	elif id==AUDIT:
		var target:int=int(action.get("target_seat",-1))
		if target<0 or target>=s["players"].size():return fail("INVALID_AUDIT_TARGET")
		if int(s["players"][target]["heat"])<3:return fail("AUDIT_HEAT_BELOW_THREE")
		var options:Array=legal_options(s,target,id)
		if options.is_empty():return fail("AUDIT_NO_LEGAL_CONSEQUENCE")
		s["priority_queue"].append({"seat":target,"caster":caster,
			"source_id":id,"options":options})
		targeted.append(target)
	else:
		return fail("UNSUPPORTED_PRIORITY_SOURCE")
	return {"ok":true,"state":s,"effect":{"source_id":id,
		"pending_for_seats":targeted,"awaits_opponent_choice":not targeted.is_empty()}}

static func choose(state:Dictionary,seat:int,action:Dictionary)->Dictionary:
	var queued:Array=state.get("priority_queue",[])
	if queued.is_empty():return fail("NO_PENDING_PRIORITY_CHOICE")
	var prompt:Dictionary=queued[0]
	if int(prompt["seat"])!=seat:return fail("NOT_CHOICE_OWNER")
	var operation:String=str(action.get("choice",""))
	if not prompt["options"].has(operation):return fail("UNAVAILABLE_CHOICE")
	var s:Dictionary=state.duplicate(true)
	var p:Dictionary=s["players"][seat]
	var effect:Dictionary={"seat":seat,"source_id":prompt["source_id"],
		"choice":operation}
	match operation:
		"LOSE_OATH":
			if int(p["oath"])<2:return fail("INSUFFICIENT_OATH")
			p["oath"]=int(p["oath"])-2
			effect["oath_lost"]=2
		"DISCARD_CARD","DISCARD_NAME":
			var index:int=int(action.get("hand_index",-1))
			if index<0 or index>=p["hand"].size():return fail("INVALID_CHOSEN_CARD")
			var card:Dictionary=p["hand"][index]
			if operation=="DISCARD_NAME" and card["card_family"]!="Name":
				return fail("NAME_CARD_REQUIRED")
			p["discard"].append(p["hand"].pop_at(index))
			effect["discarded_card_id"]=str(card["card_id"])
		"EXHAUST_UNIT","SILENCE_UNIT":
			var uid:String=str(action.get("unit_uid",""))
			var target:Dictionary={}
			for unit in s["units"]:
				if str(unit["uid"])==uid:
					target=unit
					break
			if target.is_empty() or int(target["controller"])!=seat or target["defeated"]:
				return fail("FRIENDLY_UNIT_REQUIRED")
			if operation=="EXHAUST_UNIT":
				if target["exhausted"] or target["downed"]:return fail("READY_UNIT_REQUIRED")
				target["exhausted"]=true
			else:
				if target["silenced"]:return fail("UNIT_ALREADY_SILENCED")
				target["silenced"]=true
			effect["affected_uid"]=uid
		_:
			return fail("CHOICE_HANDLER_UNAVAILABLE")
	s["players"][seat]=p
	s["priority_queue"].pop_front()
	effect["remaining_responses"]=s["priority_queue"].size()
	return {"ok":true,"state":s,"effect":effect}

static func deterministic_response(state:Dictionary,seat:int)->Dictionary:
	if state.get("priority_queue",[]).is_empty():return {}
	var prompt:Dictionary=state["priority_queue"][0]
	if int(prompt["seat"])!=seat:return {}
	var options:Array=prompt["options"]
	var action:Dictionary={"type":CHOICE_ACTION,"seat":seat,
		"revision":int(state["revision"])}
	# Responding AI chooses a legal option; it cannot choose for a human.
	if options.has("DISCARD_NAME"):
		for i in range(state["players"][seat]["hand"].size()):
			if state["players"][seat]["hand"][i]["card_family"]=="Name":
				action["choice"]="DISCARD_NAME"
				action["hand_index"]=i
				return action
	if options.has("DISCARD_CARD"):
		action["choice"]="DISCARD_CARD"
		action["hand_index"]=state["players"][seat]["hand"].size()-1
		return action
	if options.has("LOSE_OATH"):
		action["choice"]="LOSE_OATH"
		return action
	for op in ["EXHAUST_UNIT","SILENCE_UNIT"]:
		if not options.has(op):continue
		for u in state["units"]:
			if int(u["controller"])!=seat or u["defeated"]:continue
			if op=="EXHAUST_UNIT" and (u["exhausted"] or u["downed"]):continue
			if op=="SILENCE_UNIT" and u["silenced"]:continue
			action["choice"]=op
			action["unit_uid"]=u["uid"]
			return action
	return {}
