extends RefCounted
## Verified printed M8 Edicts for the integrated local match candidate.
## All changes are deterministic, source-hashed and confined to the copy of match
## state supplied by the caller; legality is checked before caller pays costs.
const Source = preload("res://scripts/real_effects.gd")
const CORE = preload("res://scripts/real_combat_core.gd")
const Priority = preload("res://scripts/match_priority.gd")
const HASHES := {
	"181": "8d478dc00c08a015756632a75ab6615de0f67dff5fc6df183da41a845797bc95",
	"184": "d621bcd0a495f80999dcc4dc3e791f040f970e4186a2b8c57495e00bbcfccc94",
	"185": "27397efb602eda36d49fcb9d83b768ee3491672c00aa9921bf0fc5e56e16e7f3",
	"187": "9c6964e87975c030d3f2d161334c66973974d73c00b9edef9227b30efbe1dc40",
	"188": "bd82cf6f866c313b83f5415a2ae8d5c502d17347a823f26cc704ea0c113e5e26",
	"191": "01a059adfba723ec3e22b6e8be4ffa27946b778e6e4797fb0c6f39670f4b377f",
	"193": "c0a3917b78511bf01bf64fe0f39e9c9a065dac4e65adb2e4cd39569100935278",
}

static func _fail(message: String) -> Dictionary:
	return {"ok":false,"error":message}

static func verified(id: String) -> bool:
	if Priority.SOURCE_HASHES.has(id):return Priority.verified(id)
	if not HASHES.has(id): return false
	var c: Dictionary = Source.find_card(Source.catalog(),id)
	if c.is_empty() or c["card_family"] != "Edict": return false
	return c["rules_sha256"] == HASHES[id] and str(c["rules_text"]).replace("\r\n","\n").sha256_text() == HASHES[id]

static func resolve(current: Dictionary, seat: int, id: String, action: Dictionary) -> Dictionary:
	if current.get("mode") != "M7_REAL_MATCH_CANDIDATE": return _fail("WRONG_GAME_MODE")
	if not verified(id): return _fail("UNKNOWN_OR_UNVERIFIED_EDICT")
	if int(current.get("phase",-1)) != 2: return _fail("EDICTS_WINDOW_REQUIRED")
	if seat != int(current.get("seat",-1)): return _fail("NOT_ACTIVE_SEAT")
	var s: Dictionary = current.duplicate(true)
	var details: Dictionary = {"card_id":id}
	match id:
		"182","190":
			return Priority.issue(s,seat,id,action)
		"181":
			var hits: Array = []
			for unit in s["units"]:
				if unit["field"] != "Warfield" or unit["defeated"]: continue
				unit["wounds"] = int(unit["wounds"]) + 1
				var c: Dictionary = Source.find_card(Source.catalog(),str(unit["card_id"]))
				if int(c.get("wound_threshold",0)) <= int(unit["wounds"]):
					unit["downed"] = true
				hits.append(unit["uid"])
			details["hit_units"] = hits
		"184":
			var target:String=str(action.get("target_uid",""))
			var at:int=CORE.find_unit(s,target)
			if at<0:return _fail("DOWNED_UNIT_REQUIRED")
			var unit:Dictionary=s["units"][at]
			if not unit["downed"] or unit["defeated"]:
				return _fail("DOWNED_UNIT_REQUIRED")
			if int(unit.get("cannot_rescue_round",-1))==int(s["round"]):
				return _fail("ALREADY_SEALED_THIS_ROUND")
			unit["cannot_rescue_round"]=int(s["round"])
			unit["cannot_ready_round"]=int(s["round"])
			details["sealed"]=target
		"185":
			var family:String=str(action.get("target_kind",""))
			var wanted_id:String=str(action.get("target_card_id",""))
			var target_owner:int=int(action.get("target_controller",-1))
			var target_host:String=str(action.get("target_host_uid",""))
			if target_owner<0 or target_owner>=s["players"].size():
				return _fail("TARGET_CONTROLLER_INVALID")
			if family!="Site" and family!="Relic":
				return _fail("RELIC_OR_SITE_REQUIRED")
			var zone:Array=s["sites"] if family=="Site" else s["attachments"]
			var found:bool=false
			for obj in zone:
				if str(obj.get("card_id",""))!=wanted_id or int(obj.get("controller",-1))!=target_owner:continue
				if family=="Relic" and str(obj.get("host_uid",""))!=target_host:continue
				var obj_card:Dictionary=Source.find_card(Source.catalog(),wanted_id)
				if obj_card.get("card_family")!=family:return _fail("SOURCE_FAMILY_MISMATCH")
				if obj.get("exhausted",false):return _fail("TARGET_ALREADY_EXHAUSTED")
				obj["exhausted"]=true
				obj["exhausted_by"]=seat
				obj["exhausted_round"]=int(s["round"])
				found=true
				break
			if not found:return _fail("TARGET_PERMANENT_NOT_FOUND")
			details["exhausted_card"]=wanted_id
			details["target_controller"]=target_owner
		"188":
			var target: String = str(action.get("target_uid",""))
			var at: int = CORE.find_unit(s,target)
			if at < 0: return _fail("FRIENDLY_CHARACTER_REQUIRED")
			var u: Dictionary = s["units"][at]
			var c: Dictionary = Source.find_card(Source.catalog(),str(u["card_id"]))
			if int(u["controller"]) != seat or c.get("card_family") != "Character" or u["defeated"]:
				return _fail("FRIENDLY_CHARACTER_REQUIRED")
			if int(u["wounds"]) <= 0 and not bool(u["silenced"]):
				return _fail("HEAL_OR_SILENCE_REQUIRED")
			u["silenced"] = false
			u["wounds"] = maxi(0,int(u["wounds"])-1)
			details["healed"] = target
		"191":
			if not s.get("truce", {}).is_empty() and bool(s["truce"].get("active",false)):
				return _fail("TRUCE_ALREADY_ACTIVE")
			s["truce"] = {"active":true,"owner":seat,"started_round":int(s["round"]),"seats":[0,1]}
			for i in range(2): s["players"][i]["heat"] = maxi(0,int(s["players"][i]["heat"])-1)
			details["truce_until_owner_next_upkeep"] = seat
		"193":
			var target: String = str(action.get("target_uid",""))
			var at: int = CORE.find_unit(s,target)
			if at < 0: return _fail("FRIENDLY_EXHAUSTED_REQUIRED")
			var u: Dictionary = s["units"][at]
			if int(u["controller"]) != seat or not bool(u["exhausted"]) or u["downed"] or u["defeated"]:
				return _fail("FRIENDLY_EXHAUSTED_REQUIRED")
			u["exhausted"] = false
			u["cannot_support_round"] = int(s["round"])
			details["readied"] = target
		_:
			return _fail("EFFECT_NOT_SUPPORTED")
	return {"ok":true,"state":s,"effect":details}

static func engagements_blocked(state: Dictionary, attacker_seat: int, defender_seat: int) -> bool:
	var truce: Dictionary = state.get("truce",{})
	return bool(truce.get("active",false)) and attacker_seat != defender_seat and (
		[attacker_seat,defender_seat] == [0,1] or [attacker_seat,defender_seat] == [1,0])
