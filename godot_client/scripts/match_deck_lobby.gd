extends RefCounted
## Immutable pre-deal deck lock. No rule effects, rewards or opponent choices.
const Decks = preload("res://scripts/deck_registry.gd")

static func create() -> Dictionary:
	return {"revision":0,"ready":[false,false],"deck_ids":[[],[]],"started":false}

static func select(state:Dictionary, seat:int, revision:Variant, ids:Variant) -> Dictionary:
	if seat not in [0,1]:return {"ok":false,"error":"INVALID_LOBBY_SEAT"}
	if state["started"]:return {"ok":false,"error":"DECK_SELECTION_CLOSED"}
	if typeof(revision)!=TYPE_INT or revision!=state["revision"]:
		return {"ok":false,"error":"STALE_DECK_REVISION"}
	if state["ready"][seat]:return {"ok":false,"error":"DECK_ALREADY_LOCKED"}
	if typeof(ids)!=TYPE_ARRAY or ids.size()!=36:return {"ok":false,"error":"DECK_SIZE_36"}
	for id in ids:
		if typeof(id)!=TYPE_STRING:return {"ok":false,"error":"STRING_CARD_IDS_REQUIRED"}
	var legal:Dictionary=Decks.validate_ids(ids,true)
	if not legal.get("ok",false):return {"ok":false,"error":"CANDIDATE_DECK_INVALID","errors":legal.get("errors",[])}
	var next:Dictionary=state.duplicate(true)
	next["deck_ids"][seat]=ids.duplicate()
	next["ready"][seat]=true
	next["revision"]+=1
	next["started"]=next["ready"][0] and next["ready"][1]
	return {"ok":true,"state":next}

static func projection(state:Dictionary) -> Dictionary:
	return {"revision":state["revision"],"ready":state["ready"].duplicate(),"started":state["started"]}
