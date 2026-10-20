extends RefCounted
## M7 integrated REAL-CARD match candidate (not certified Standard).
## Fully local deterministic 2-seat scenario: Warfield objective control.
## Whitelisted real cards only; unresolved source effects are NOT activated.
const CardSource = preload("res://scripts/real_effects.gd")
const Adj = preload("res://scripts/adjacency_rule.gd")
const Rules = preload("res://scripts/game_rules.gd")
const Costs = preload("res://scripts/cost_rules.gd")
const Deck = preload("res://scripts/deck_validator.gd")
const DeckRegistry = preload("res://scripts/deck_registry.gd")
const Combat = preload("res://scripts/real_combat_core.gd")
const Edicts = preload("res://scripts/match_edicts.gd")
const Priority = preload("res://scripts/match_priority.gd")
const MODE := "M7_REAL_MATCH_CANDIDATE"
const SCENARIO := "Warfield Ascendancy (candidate, not canon)"
const AXES := ["Stone", "Veil", "Authority"]
const SITES := ["214", "216"]
const SUPPORT := ["239", "241", "254"]
const EDICTS := ["181","182","184","185","187","188","190","191","193"]
const FIELD_NAMES := ["Warfield", "Sanctuary"]
const FACTIONS := ["BorderstoneGuild","FloodbornPact","SkyloomTemple","UnderwellKeepers","Fateforge"]
const SOURCE_HASHES := {"239":"62ce231bc67c47e99832c4d8c18da701c04ecce102799bfad21eb295613f18dd",
	"241":"9d8b1b4b296c74bcd2ce75bf3c18cb49671e25728cf8cd1cb7e486a6ccd554d1",
	"254":"4d02f398201e108e7dfb95441a182f7c050564499229a1d03cbb76cf70264af4",
	"214":"d36bef97289a48543ead3b18f7744f44bd03afcec75a97fd0b84dd27bb9b8c7b",
	"216":"8a8db6ddd60bb781e6af42f2e028fde3303b919abb1be9dc59bc491a2b32fb44"}

static func error(code: String) -> Dictionary:
	return {"ok": false, "error": code}

static func _supported(c: Dictionary) -> bool:
	var id: String = str(c.get("card_id", ""))
	if EDICTS.has(id): return Edicts.verified(id)
	if SITES.has(id) or SUPPORT.has(id):
		return str(c.get("rules_sha256","")) == str(SOURCE_HASHES.get(id,"")) and str(c.get("rules_text","")).replace("\r\n","\n").sha256_text() == SOURCE_HASHES[id]
	return c.get("card_family") == "Character" and Adj.has_compiled_rule(id)

static func _deck(faction: String) -> Array:
	var source: Dictionary = CardSource.catalog()
	if source.is_empty(): return []
	var pool: Array = []
	for c in source["cards"]:
		if c["owner_faction"] == faction and c["card_family"] == "Character" and Adj.has_compiled_rule(str(c["card_id"])) and (
			int(c["cost_sinew"]) <= 2 and not c["requires_faction_lock"] and
			["Common","Uncommon","Rare"].has(c["rarity"])):
			pool.append(c)
	pool.sort_custom(func(a,b):
		if a["cost_sinew"] == b["cost_sinew"]: return int(a["card_id"]) < int(b["card_id"])
		return int(a["cost_sinew"]) < int(b["cost_sinew"]))
	if pool.size() < 21: return []
	var out: Array = []
	var seen_names: Dictionary = {}
	for candidate in pool:
		if seen_names.has(str(candidate["card_name"])): continue
		seen_names[str(candidate["card_name"])] = true
		var c: Dictionary = candidate.duplicate(true)
		c["playable"] = true # Candidate whitelist ONLY, original registry stays locked.
		out.append(c)
		if out.size() == 21: break
	if out.size() != 21: return []
	for id in SITES:
		var site: Dictionary = CardSource.find_card(source, id).duplicate(true)
		site["playable"] = true
		out.append(site)
	for id in SUPPORT:
		for i in range(2 if id == "239" else 1):
			var item: Dictionary = CardSource.find_card(source, id).duplicate(true)
			item["playable"] = true
			out.append(item)
	for id in EDICTS:
		var edict: Dictionary = CardSource.find_card(source,id).duplicate(true)
		edict["playable"] = true
		out.append(edict)
	return out

static func _shuffle(deck: Array, seed_value: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cards: Array = deck.duplicate(true)
	for i in range(cards.size() - 1, 0, -1):
		var j: int = rng.randi_range(0,i)
		var swap: Variant = cards[i]
		cards[i] = cards[j]
		cards[j] = swap
	return cards

static func _draw(p: Dictionary) -> void:
	while p["hand"].size() < 6 and not p["deck"].is_empty():
		p["hand"].append(p["deck"].pop_back())

static func create(seed_value: int = 20261020, player_faction: String = "BorderstoneGuild",
		opponent_faction: String = "UnderwellKeepers", custom_decks: Array = []) -> Dictionary:
	if seed_value < 0: return error("BAD_SEED")
	if not FACTIONS.has(player_faction) or not FACTIONS.has(opponent_faction):
		return error("UNKNOWN_FACTION")
	var factions := [player_faction,opponent_faction]
	if not custom_decks.is_empty() and custom_decks.size()!=2:
		return error("TWO_SEAT_DECKLIST_SCOPE_REQUIRED")
	var players: Array = []
	var initial_ids: Array = []
	for seat in range(2):
		var deck: Array = _deck(factions[seat])
		if custom_decks.size()==2 and typeof(custom_decks[seat])==TYPE_ARRAY and not custom_decks[seat].is_empty():
			var checked: Dictionary = DeckRegistry.validate_ids(custom_decks[seat],true)
			if not checked.get("ok",false): return error("CANDIDATE_CUSTOM_DECK_INVALID")
			deck = checked["cards"]
		var id_list: Array = []
		for card in deck:id_list.append(str(card["card_id"]))
		initial_ids.append(id_list)
		if deck.size() != 36 or not Deck.validate(deck)["legal"]:
			return error("CANDIDATE_DECK_INVALID")
		var p: Dictionary = {"seat": seat, "name": "Player" if seat == 0 else "Opponent",
			"faction": factions[seat], "sinew": 2, "sigil": 1, "oath": 1,
			"heat": 0, "marks": 0, "hand": [], "deck": _shuffle(deck,seed_value+seat*7919),
			"discard": [], "setup_ready": false}
		_draw(p)
		players.append(p)
	return {"ok": true, "state": {"mode": MODE, "scenario": SCENARIO,
		"source_catalog": "real_cards_v1", "seed": seed_value, "initial_deck_ids": initial_ids,
		"round": 1, "seat": 0, "phase": 0, "revision": 0,
		"players": players, "units": [], "sites": [], "attachments": [],
		"next_uid": 1, "objective_owner": -1, "winner": -1, "peek_used": {}, "truce": {}, "pending_end_clause": {}, "priority_queue": [],
		"events": [], "action_log": [], "setup_complete": false,
		"release_certified": false, "reward_enabled": false}}

static func _unit_index(s: Dictionary, uid: String) -> int:
	for i in range(s["units"].size()):
		if s["units"][i]["uid"] == uid: return i
	return -1

static func _ready(u: Dictionary) -> bool:
	return not bool(u["exhausted"]) and not bool(u["downed"]) and not bool(u["defeated"])

static func _control(s: Dictionary) -> int:
	var tally := [0,0]
	for u in s["units"]:
		if u["field"] == "Warfield" and not u["downed"] and not u["defeated"]:
			tally[int(u["controller"])] += 1
	if tally[0] == tally[1]: return -1
	return 0 if tally[0] > tally[1] else 1

static func _summary_income(s: Dictionary, seat: int) -> Dictionary:
	var counts := [0,0]
	for u in s["units"]:
		if _ready(u): counts[int(u["controller"])] += 1
	var best: int = maxi(counts[0],counts[1])
	var sinew: int = 1 if best > 0 and counts[seat] == best and counts[seat] > counts[1-seat] else 0
	var sigil: int = 0
	for site in s["sites"]:
		if int(site["controller"]) == seat: sigil = 1
	var oath: int = 1 if _control(s) == seat else 0
	if sinew == 0 and sigil == 0 and oath == 0: sinew = 1
	return {"sinew": sinew, "sigil": sigil, "oath": oath}

static func _restore_defeated_due(s:Dictionary)->Dictionary:
	# Shipping Rule 17.6: two FULL intervening rounds, then owner Hand or Deck.
	# A card Defeated in round 1 cannot return until the start of round 4.
	var due:Array=[]
	for unit in s["units"]:
		if not bool(unit["defeated"]):continue
		var defeated_at:int=int(unit.get("defeated_round",-1))
		if defeated_at>=0 and int(s["round"])>=defeated_at+3:due.append(unit)
	if due.is_empty():return {"ok":true,"returns":[],"attachments_released":[]}
	var units_left:Array=[]
	var released:Array=[]
	var affected_decks:Dictionary={}
	var restored:Array=[]
	for unit in s["units"]:
		if not due.has(unit):
			units_left.append(unit)
			continue
		var original:int=int(unit.get("owner",-1))
		if original<0 or original>=s["players"].size():return error("RESTORE_ORIGINAL_OWNER_INVALID")
		var card:Dictionary=CardSource.find_card(CardSource.catalog(),str(unit["card_id"])).duplicate(true)
		if not _supported(card):return error("RESTORE_SOURCE_ID_NOT_IN_LOCAL_MATCH")
		card["playable"]=true
		var dest:String="Hand"
		if s["players"][original]["hand"].size()<6:
			s["players"][original]["hand"].append(card)
		else:
			s["players"][original]["deck"].append(card)
			affected_decks[original]=true
			dest="Deck"
		restored.append({"uid":str(unit["uid"]),"card_id":str(unit["card_id"]),
			"original_owner":original,"destination":dest})
	var remaining_attachments:Array=[]
	for attachment in s["attachments"]:
		var falls:bool=false
		for info in restored:
			if str(info["uid"])==str(attachment.get("host_uid","")):
				falls=true
				break
		if not falls:
			remaining_attachments.append(attachment)
			continue
		var owner:int=int(attachment.get("controller",-1))
		if owner<0 or owner>=s["players"].size():return error("RESTORE_ATTACHMENT_OWNER_INVALID")
		var owned:Dictionary=CardSource.find_card(CardSource.catalog(),str(attachment["card_id"])).duplicate(true)
		if not _supported(owned):return error("RESTORE_ATTACHMENT_NOT_IN_LOCAL_MATCH")
		owned["playable"]=true
		s["players"][owner]["discard"].append(owned)
		released.append({"card_id":str(attachment["card_id"]),"to_discard_owner":owner})
	s["units"]=units_left
	s["attachments"]=remaining_attachments
	for seat in affected_decks:
		s["players"][seat]["deck"]=_shuffle(s["players"][seat]["deck"],
			int(s["seed"])+int(s["round"])*27581+int(seat)*18013+343)
	return {"ok":true,"returns":restored,"attachments_released":released}

static func _commit(s: Dictionary, type_name: String, details: Dictionary = {}, committed_action: Dictionary = {}) -> Dictionary:
	s["revision"] = int(s["revision"]) + 1
	var event: Dictionary = {"type": type_name, "revision": s["revision"]}
	for key in details: event[key] = details[key]
	s["events"].append(event)
	if not committed_action.is_empty(): s["action_log"].append(committed_action.duplicate(true))
	return {"ok": true, "state": s, "event": event}

static func apply(state: Dictionary, action: Dictionary) -> Dictionary:
	if state.get("mode") != MODE or bool(state.get("release_certified", true)):
		return error("NOT_CANDIDATE_MODE")
	if int(state.get("winner", -1)) >= 0: return error("MATCH_FINISHED")
	if typeof(action.get("revision")) != TYPE_INT or action["revision"] != state["revision"]:
		return error("STALE_REVISION")
	if typeof(action.get("seat")) != TYPE_INT: return error("INVALID_SEAT")
	var seat: int = int(action["seat"])
	if seat < 0 or seat > 1: return error("INVALID_SEAT")
	var kind: String = str(action.get("type",""))
	var s: Dictionary = state.duplicate(true)
	var p: Dictionary = s["players"][seat]
	if not bool(s["setup_complete"]):
		if p["setup_ready"]: return error("SETUP_ALREADY_DECIDED")
		if kind != "KEEP" and kind != "MULLIGAN": return error("PREGAME_DECISION_REQUIRED")
		if kind == "MULLIGAN":
			var all: Array = p["deck"] + p["hand"]
			if all.size() != 36: return error("SETUP_CONSERVATION")
			p["deck"] = _shuffle(all,int(s["seed"]) + seat*7919 + 919)
			p["hand"] = []
			_draw(p)
		p["setup_ready"] = true
		s["players"][seat] = p
		s["setup_complete"] = s["players"][0]["setup_ready"] and s["players"][1]["setup_ready"]
		return _commit(s,"SETUP_"+kind,{"seat":seat},action)
	if not s.get("priority_queue",[]).is_empty():
		if kind!=Priority.CHOICE_ACTION:return error("RESPONSE_CHOICE_REQUIRED")
		var choice_result:Dictionary=Priority.choose(s,seat,action)
		if not choice_result["ok"]:return choice_result
		return _commit(choice_result["state"],"OPPONENT_CHOICE",choice_result["effect"],action)
	if kind==Priority.CHOICE_ACTION:return error("NO_PENDING_PRIORITY_CHOICE")
	if seat != int(s["seat"]): return error("NOT_ACTIVE_SEAT")
	var phase: int = int(s["phase"])
	if kind == "CAST_END":
		if phase!=6:return error("END_WINDOW_REQUIRED")
		if not s["pending_end_clause"].is_empty():return error("DISCARD_PENDING")
		if not Edicts.verified("187"):return error("SOURCE_TEXT_CHANGED")
		var card_index:int=-1
		for i in range(p["hand"].size()):
			if str(p["hand"][i]["card_id"])=="187":
				card_index=i
				break
		if card_index<0:return error("NIGHT_MARKET_NOT_IN_HAND")
		var clause:Dictionary=p["hand"][card_index]
		var payment:Dictionary=Costs.pay(p,clause)
		if not payment["ok"]:return payment
		# Draw first, *then* choose one card to discard. Never preselect it.
		for resource in Costs.RESOURCE_KEYS:p[resource]=int(payment["player"][resource])
		p["hand"].remove_at(card_index)
		p["discard"].append(clause)
		var drawn:Array=[]
		for k in range(2):
			if p["deck"].is_empty():break
			var pulled:Dictionary=p["deck"].pop_back()
			p["hand"].append(pulled)
			drawn.append(str(pulled["card_id"]))
		if p["hand"].is_empty():return error("NIGHT_MARKET_DISCARD_REQUIRED")
		s["players"][seat]=p
		s["pending_end_clause"]={"seat":seat,"drawn_count":drawn.size()}
		# Do not reveal drawn card identities to other seats in the public event.
		return _commit(s,"NIGHT_MARKET_DRAW",{"seat":seat,"drawn_count":drawn.size(),"paid":payment["paid"]},action)
	if kind == "CLAUSE_DISCARD":
		if phase!=6:return error("END_WINDOW_REQUIRED")
		if s["pending_end_clause"].is_empty() or int(s["pending_end_clause"]["seat"])!=seat:
			return error("NO_PENDING_END_DISCARD")
		var choice:int=int(action.get("hand_index",-1))
		if choice<0 or choice>=p["hand"].size():return error("INVALID_DISCARD_CHOICE")
		var selected:Dictionary=p["hand"].pop_at(choice)
		p["discard"].append(selected)
		p["heat"]=int(p["heat"])+1
		s["players"][seat]=p
		s["pending_end_clause"]={}
		return _commit(s,"NIGHT_MARKET_DISCARD",{"seat":seat,"card_id":str(selected["card_id"]),"heat_gained":1},action)
	if kind == "END_DISCARD":
		if phase!=6:return error("END_WINDOW_REQUIRED")
		if not s["pending_end_clause"].is_empty():return error("NIGHT_MARKET_DISCARD_PENDING")
		if p["hand"].size()<=6:return error("HAND_LIMIT_NOT_EXCEEDED")
		var index:int=int(action.get("hand_index",-1))
		if index<0 or index>=p["hand"].size():return error("INVALID_END_DISCARD")
		var card:Dictionary=p["hand"].pop_at(index)
		p["discard"].append(card)
		s["players"][seat]=p
		return _commit(s,"END_HAND_LIMIT_DISCARD",{"seat":seat,"card_id":str(card["card_id"]),
			"remaining_hand":p["hand"].size()},action)
	if kind == "ADVANCE":
		if phase==6 and not s["pending_end_clause"].is_empty():
			return error("NIGHT_MARKET_DISCARD_PENDING")
		if phase==6 and p["hand"].size()>6:
			return error("END_HAND_LIMIT_CHOICE_REQUIRED")
		if phase == 0:
			if bool(s["truce"].get("active",false)) and int(s["truce"]["owner"]) == seat and int(s["round"]) > int(s["truce"]["started_round"]):
				s["truce"] = {}
			for u in s["units"]:
				if int(u["controller"]) == seat and not u["downed"] and not u["defeated"]: u["exhausted"] = false
			for site in s["sites"]:
				if int(site["controller"])==seat:site["exhausted"]=false
			for attachment in s["attachments"]:
				if int(attachment["controller"])==seat:attachment["exhausted"]=false
		if phase == 5:
			s["objective_owner"] = _control(s)
			var controller: int = int(s["objective_owner"])
			if controller >= 0:
				s["players"][controller]["marks"] += 1
				if s["players"][controller]["marks"] >= 10: s["winner"] = controller
		if phase == 6:
			var income: Dictionary = _summary_income(s,seat)
			for k in ["sinew","sigil","oath"]: s["players"][seat][k] += int(income[k])
			s["seat"] = 1-seat
			if s["seat"] == 0: s["round"] += 1
		var returns:Dictionary={"returns":[],"attachments_released":[]}
		if phase==6 and int(s["seat"])==0:
			returns=_restore_defeated_due(s)
			if not returns["ok"]:return returns
		s["phase"] = (phase+1)%7
		if s["phase"] == 1: _draw(s["players"][int(s["seat"])])
		return _commit(s,"PHASE",{"seat":s["seat"],"phase":Rules.PHASES[int(s["phase"])],
			"objective_owner":s["objective_owner"],"winner":s["winner"],
			"defeated_returns":returns["returns"],
			"released_support":returns["attachments_released"]},action)
	if kind == "PEEK":
		if phase != 3: return error("MAIN_REQUIRED")
		var has_archive: bool = false
		for site in s["sites"]:
			if site["card_id"] == "214" and int(site["controller"]) == seat and not site.get("exhausted",false): has_archive = true
		if not has_archive: return error("MIRROR_ARCHIVE_REQUIRED")
		var stamp: String = str(int(s["round"])*2+seat)
		if s["peek_used"].has(stamp): return error("MIRROR_ALREADY_USED")
		var target: int = int(action.get("target_seat", -1))
		if target < 0 or target > 1 or s["players"][target]["deck"].is_empty(): return error("TARGET_DECK_UNAVAILABLE")
		var revealed_id: String = str(s["players"][target]["deck"][-1]["card_id"])
		s["peek_used"][stamp] = true
		var peek_result: Dictionary = _commit(s,"PRIVATE_TOP_DECK_VIEW",{"seat":seat,"target_seat":target},action)
		peek_result["private_card_id"] = revealed_id
		peek_result["private_for_seat"] = seat
		return peek_result
	if kind == "CAST":
		if phase != 2: return error("EDICTS_WINDOW_REQUIRED")
		var id: String = str(action.get("card_id",""))
		var index: int = -1
		for i in range(p["hand"].size()):
			if str(p["hand"][i]["card_id"]) == id:
				index = i
				break
		if index < 0: return error("EDICT_NOT_IN_HAND")
		var card: Dictionary = p["hand"][index]
		if not _supported(card) or card["card_family"] != "Edict":
			return error("UNVERIFIED_EDICT")
		if id=="187":return error("END_WINDOW_REQUIRED")
		var effect: Dictionary = Edicts.resolve(s,seat,id,action)
		if not effect["ok"]: return effect
		var payment: Dictionary = Costs.pay(p,card)
		if not payment["ok"]: return payment
		s = effect["state"]
		for resource in Costs.RESOURCE_KEYS:
			s["players"][seat][resource] = int(payment["player"][resource])
		s["players"][seat]["hand"].remove_at(index)
		s["players"][seat]["discard"].append(card)
		return _commit(s,"EDICT",{"seat":seat,"card_id":id,"paid":payment["paid"],
			"resolved":effect["effect"]},action)
	if kind == "DEPLOY":
		if phase != 3: return error("MAIN_REQUIRED")
		var id: String = str(action.get("card_id",""))
		var index: int = -1
		for i in range(p["hand"].size()):
			if str(p["hand"][i]["card_id"]) == id:
				index = i
				break
		if index < 0: return error("NOT_IN_HAND")
		var c: Dictionary = p["hand"][index]
		if not _supported(c): return error("UNIMPLEMENTED_CARD_EFFECT")
		var family: String = str(c["card_family"])
		var field: String = str(action.get("field","Warfield"))
		if not FIELD_NAMES.has(field): return error("UNKNOWN_FIELD")
		var host: String = str(action.get("host_uid",""))
		if family == "Site":
			if (id == "216" and field != "Warfield") or (id == "214" and field != "Sanctuary"):
				return error("SITE_ZONE_RESTRICTION")
			for site in s["sites"]:
				if site["controller"] == seat and site["card_id"] == id:
					return error("SITE_ALREADY_CONTROLLED")
		elif family == "Pet" or family == "Relic":
			var ui: int = _unit_index(s, host)
			if ui < 0 or s["units"][ui]["controller"] != seat or s["units"][ui]["downed"]:
				return error("FRIENDLY_HOST_REQUIRED")
			for attachment in s["attachments"]:
				if attachment["host_uid"] == host and attachment["card_id"] == id:
					return error("DUPLICATE_ATTACHMENT")
		var payment: Dictionary = Costs.pay(p,c)
		if not payment["ok"]: return payment
		for k in Costs.RESOURCE_KEYS: p[k] = int(payment["player"][k])
		p["hand"].remove_at(index)
		s["players"][seat] = p
		if family == "Character":
			var slot: int = 0
			for u in s["units"]:
				if u["field"] == field and u["controller"] == seat:
					slot = maxi(slot,int(u["slot"])+1)
			var unit: Dictionary = Combat.unit("REAL_%d" % int(s["next_uid"]),id,seat,slot,field)
			unit["exhausted"] = true # No surprise attack on the deployment turn
			s["next_uid"] += 1
			s["units"].append(unit)
		elif family == "Site":
			s["sites"].append({"card_id":id,"controller":seat,"field":field})
		else:
			s["attachments"].append({"card_id":id,"controller":seat,"host_uid":host})
		return _commit(s,"DEPLOY",{"seat":seat,"card_id":id,"family":family,"paid":payment["paid"]},action)
	if kind == "ATTACK":
		if phase != 4: return error("BATTLE_REQUIRED")
		if Edicts.engagements_blocked(s,seat,1-seat): return error("FESTIVAL_TRUCE_NO_ENGAGEMENT")
		var attacker: String = str(action.get("attacker",""))
		var defender: String = str(action.get("defender",""))
		var ai: int = _unit_index(s,attacker)
		if ai < 0 or s["units"][ai]["controller"] != seat: return error("NOT_YOUR_ATTACKER")
		var battle_players: Array = s["players"].duplicate(true)
		for j in range(2):
			var ids: Array = []
			for record in battle_players[j]["deck"]: ids.append(str(record["card_id"]))
			battle_players[j]["deck"] = ids
		var battle: Dictionary = {
			"mode":"REAL_COMBAT_LAB","phase":"Battle","active_seat":seat,
			"revision":s["revision"],"seed":s["seed"],
			"players":battle_players, "units":s["units"].duplicate(true),
			"sites":s["sites"].duplicate(true),"attachments":s["attachments"].duplicate(true),
			"round":s["round"],"events":[]}
		var result: Dictionary = Combat.attack(battle,{
			"revision":s["revision"],"attacker":attacker,"defender":defender,
			"axis":str(action.get("axis","Stone")),
			"attacker_spend":int(action.get("attacker_spend",0)),
			"defender_spend":int(action.get("defender_spend",0))})
		if not result["ok"]: return result
		s["units"] = result["state"]["units"]
		for i in range(2):
			s["players"][i]["sinew"] = result["state"]["players"][i]["sinew"]
			s["players"][i]["sigil"] = result["state"]["players"][i]["sigil"]
			s["players"][i]["oath"] = result["state"]["players"][i]["oath"]
			var restored_deck: Array = []
			for deck_id in result["state"]["players"][i]["deck"]:
				var real_card: Dictionary = CardSource.find_card(CardSource.catalog(), str(deck_id)).duplicate(true)
				real_card["playable"] = true
				restored_deck.append(real_card)
			s["players"][i]["deck"] = restored_deck
		return _commit(s,"COMBAT",{"seat":seat,"attacker":attacker,"defender":defender,
			"axis":str(action.get("axis","Stone")), "winner":result["event"]["winner_seat"]},action)
	return error("UNSUPPORTED_ACTION")

static func next_action(state: Dictionary, seat: int = 1) -> Dictionary:
	# Deterministic candidate-AI policy; reads only acting player's hand.
	if seat < 0 or seat > 1: return {}
	var action: Dictionary = {"seat":seat,"revision":int(state["revision"]),"type":"ADVANCE"}
	if not state.get("priority_queue",[]).is_empty():
		return Priority.deterministic_response(state,seat)
	if not state["setup_complete"]:
		action["type"] = "KEEP"
		return action
	var phase: int = int(state["phase"])
	var p: Dictionary = state["players"][seat]
	if phase==6:
		if not state["pending_end_clause"].is_empty():
			return {"seat":seat,"revision":int(state["revision"]),"type":"CLAUSE_DISCARD",
				"hand_index":p["hand"].size()-1}
		for card in p["hand"]:
			if str(card["card_id"])=="187" and Edicts.verified("187"):
				if int(card["cost_sinew"])<=int(p["sinew"]) and int(card["cost_sigil"])<=int(p["sigil"]) and int(card["cost_oath"])<=int(p["oath"]) and (
					p["hand"].size()>1 or not p["deck"].is_empty()):
					return {"seat":seat,"revision":int(state["revision"]),"type":"CAST_END"}
		if p["hand"].size()>6:
			return {"seat":seat,"revision":int(state["revision"]),"type":"END_DISCARD",
				"hand_index":p["hand"].size()-1}
	if phase == 2:
		for c in p["hand"]:
			var id: String = str(c["card_id"])
			if not EDICTS.has(id) or id=="187":continue
			if id=="182":
				var any_hot:bool=false
				for other in range(state["players"].size()):
					if other!=seat and int(state["players"][other]["heat"])>=4:any_hot=true
				if not any_hot:continue
			if int(c["cost_sinew"]) > int(p["sinew"]) or int(c["cost_sigil"]) > int(p["sigil"]) or int(c["cost_oath"]) > int(p["oath"]): continue
			var attempt: Dictionary = {"seat":seat,"revision":int(state["revision"]),
				"type":"CAST","card_id":id}
			if id=="190":
				var opponent:int=1-seat
				if int(state["players"][opponent]["heat"])>=3 and not Priority.legal_options(state,opponent,id).is_empty():
					attempt["target_seat"]=opponent
			if id == "184":
				for u in state["units"]:
					if u["downed"] and not u["defeated"] and int(u.get("cannot_rescue_round",-1))!=int(state["round"]):
						attempt["target_uid"]=u["uid"]
						break
			if id == "185":
				for site in state["sites"]:
					if site.get("exhausted",false):continue
					attempt["target_kind"]="Site"
					attempt["target_card_id"]=site["card_id"]
					attempt["target_controller"]=site["controller"]
					break
				if not attempt.has("target_kind"):
					for attachment in state["attachments"]:
						if attachment.get("exhausted",false) or str(attachment["card_id"])!="239":continue
						attempt["target_kind"]="Relic"
						attempt["target_card_id"]=attachment["card_id"]
						attempt["target_controller"]=attachment["controller"]
						attempt["target_host_uid"]=attachment["host_uid"]
						break
			if id == "188" or id == "193":
				for u in state["units"]:
					if int(u["controller"]) != seat or u["defeated"]: continue
					if id == "188" and (int(u["wounds"]) > 0 or bool(u["silenced"])):
						attempt["target_uid"] = u["uid"]
						break
					if id == "193" and u["exhausted"] and not u["downed"]:
						attempt["target_uid"] = u["uid"]
						break
			if apply(state,attempt).get("ok",false): return attempt
	if phase == 3:
		for c in p["hand"]:
			if str(c["card_family"]) == "Character" and int(c["cost_sinew"]) <= int(p["sinew"]) and (
				int(c["cost_sigil"]) <= int(p["sigil"]) and int(c["cost_oath"]) <= int(p["oath"])):
				action["type"] = "DEPLOY"
				action["card_id"] = c["card_id"]
				action["field"] = "Warfield"
				return action
		for c in p["hand"]:
			if str(c["card_family"]) == "Site" and int(c["cost_sigil"]) <= int(p["sigil"]):
				action["type"] = "DEPLOY"
				action["card_id"] = c["card_id"]
				action["field"] = "Sanctuary" if c["card_id"] == "214" else "Warfield"
				return action
	if phase == 3:
		# Source-verified Pets/Relics must be playable by the local opponent too.
		# Site and Character priorities above remain unchanged.
		for c in p["hand"]:
			if str(c["card_family"])!="Relic" and str(c["card_family"])!="Pet":continue
			if int(c["cost_sinew"])>int(p["sinew"]) or int(c["cost_sigil"])>int(p["sigil"]) or int(c["cost_oath"])>int(p["oath"]):continue
			for host in state["units"]:
				if int(host["controller"])!=seat or host["downed"] or host["defeated"]:continue
				var attach_action:Dictionary={"seat":seat,"revision":int(state["revision"]),"type":"DEPLOY",
					"card_id":str(c["card_id"]),"field":str(host["field"]),"host_uid":str(host["uid"])}
				if apply(state,attach_action).get("ok",false):
					return attach_action
	if phase == 4:
		for a in state["units"]:
			if a["controller"] != seat or not _ready(a): continue
			for b in state["units"]:
				if b["controller"] == seat or b["field"] != a["field"] or b["downed"] or b["defeated"]: continue
				var source_a: Dictionary = CardSource.find_card(CardSource.catalog(),str(a["card_id"]))
				var source_b: Dictionary = CardSource.find_card(CardSource.catalog(),str(b["card_id"]))
				var best: String = "Stone"
				for ax in AXES:
					if int(source_a[ax.to_lower()])-int(source_b[ax.to_lower()]) > (
						int(source_a[best.to_lower()])-int(source_b[best.to_lower()])):
						best = ax
				action["type"] = "ATTACK"
				action["attacker"] = a["uid"]
				action["defender"] = b["uid"]
				action["axis"] = best
				if apply(state, action).get("ok", false): return action
				action = {"seat":seat,"revision":int(state["revision"]),"type":"ADVANCE"}
	return action
