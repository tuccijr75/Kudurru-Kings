extends RefCounted
## Deterministic optional capture adjudicator candidate for isolated M5 sandbox.
## Authority Face-off is an explicit proposed fallback, NOT shipping canon.
## It NEVER grants account inventory; server must confirm signed match receipt.
const Combat = preload("res://scripts/real_combat_core.gd")
const Source = preload("res://scripts/real_effects.gd")
const TRIALS := ["Stone","Veil","Authority"]

static func error(code:String)->Dictionary:return {"ok":false,"error":code}

static func eligible(s:Dictionary,seat:int,uid:String)->Dictionary:
	if s.get("mode")!="REAL_COMBAT_LAB" or s.get("phase")!="Resolution":
		return error("RESOLUTION_LAB_ONLY")
	if seat!=int(s.get("active_seat",-1)):return error("NOT_ACTIVE_SEAT")
	var idx:int=Combat.find_unit(s,uid)
	if idx<0:return error("UNKNOWN_TARGET")
	var unit:Dictionary=s["units"][idx]
	if int(unit["controller"])==seat or not unit["downed"] or not unit["bound"] or unit["defeated"]:
		return error("CAPTURE_NOT_ELIGIBLE")
	var source:Dictionary=Source.find_card(Source.catalog(),str(unit["card_id"]))
	if source.get("card_family")!="Character" and source.get("card_family")!="Boss":
		return error("NO_CAPTURE_FAMILY")
	if source["card_family"]=="Boss":
		var axes:Array=unit.get("trials_won",[])
		for axis in TRIALS:
			if not axes.has(axis):return error("BOSS_TRIALS_INCOMPLETE")
		if axes.size()!=3:return error("REPEATED_OR_UNVERIFIED_TRIALS")
	return {"ok":true,"unit_index":idx,"source":source}

static func resolve(s:Dictionary,seat:int,uid:String,mode:String)->Dictionary:
	var gate:Dictionary=eligible(s,seat,uid)
	if not gate.get("ok",false):return gate
	if mode!="AUTHORITY_FACE_OFF_CANDIDATE":
		return error("CAPTURE_OUTCOME_NOT_CANON_APPROVED")
	var idx:int=gate["unit_index"]
	var unit:Dictionary=s["units"][idx]
	var card:Dictionary=gate["source"]
	var loser:int=int(unit["controller"])
	var faceoff:Dictionary=Combat.faceoff(s,seat,loser,"Authority")
	if not faceoff.get("ok",false):return faceoff
	var success:bool=int(faceoff["winner"])==seat
	var value:int=2 if card["card_family"]=="Boss" else 1
	var marks:int=value if success else (1 if card["card_family"]=="Character" else 0)
	var next:Dictionary=s.duplicate(true)
	next["units"][idx]["defeated"]=true
	next["units"][idx]["defeated_round"]=int(next["round"])
	next["units"][idx]["bound"]=false
	next["units"][idx]["captured"]=success
	next["units"][idx]["capture_status"]="CAPTURED_CANDIDATE" if success else "FAILED_TO_CAPTURE"
	next["players"][seat]["marks"]=int(next["players"][seat].get("marks",0))+marks
	next["players"][seat]["deck"]=faceoff["deck_a"]
	next["players"][loser]["deck"]=faceoff["deck_b"]
	next["revision"]=int(next["revision"])+1
	var event:Dictionary={
		"type":"CANDIDATE_CAPTURE_ADJUDICATION",
		"event_id":"%s:%s:%d" % [str(next["seed"]),uid,int(next["revision"])],
		"uid":uid,"card_id":str(unit["card_id"]),
		"capturer":seat,"original_owner":int(unit["owner"]),
		"success":success,"marks":marks,"authority_faceoff":faceoff["chain"],
		"account_reward":"PENDING_EXTERNAL_CERTIFIED_MATCH_AUTHORITY" if success else "NONE",
		"canon_production_ready":false}
	next["events"].append(event)
	return {"ok":true,"state":next,"event":event,
		"production_ready":false,"receipt_issued":false}
