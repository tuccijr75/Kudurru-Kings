extends SceneTree
const Match = preload("res://scripts/match_integrator.gd")
const Store = preload("res://scripts/match_storage.gd")
var passed:int=0
var failed:int=0
func check(ok:bool,description:String)->void:
	if ok:passed+=1
	else:
		failed+=1
		printerr("FAIL: "+description)
func _initialize()->void:
	_run()
	print("KUDURRU_M8_FULL_MATCH_REPLAY passed=%d failed=%d" % [passed,failed])
	quit(0 if failed==0 else 1)
func _run()->void:
	for seed in [1,2,3,4,5]:
		var made:Dictionary=Match.create(seed,Match.FACTIONS[seed-1],Match.FACTIONS[(seed+1)%5])
		check(made["ok"],"seeded factions setup "+str(seed))
		if not made["ok"]:continue
		var s:Dictionary=made["state"]
		for seat in range(2):
			s=Match.apply(s,{"seat":seat,"revision":int(s["revision"]),"type":"KEEP"})["state"]
		var count:int=0
		var cast_count:int=0
		while int(s["winner"]) < 0 and count<400:
			var actor:int=int(s["seat"])
			if not s.get("priority_queue",[]).is_empty():
				actor=int(s["priority_queue"][0]["seat"])
			if not s.get("pending_attack",{}).is_empty():
				actor=int(s["pending_attack"]["defender_seat"])
			var action:Dictionary=Match.next_action(s,actor)
			var applied:Dictionary=Match.apply(s,action)
			if not applied["ok"]:
				printerr("INVALID "+str(action)+" "+str(applied))
				failed+=1
				break
			if action["type"]=="CAST":cast_count+=1
			s=applied["state"]
			count+=1
		check(int(s["winner"])>=0,"all candidate matches terminate "+str(seed))
		check(int(s["revision"]) == s["action_log"].size(),"all events have exact action history "+str(seed))
		check(s["events"].size() == s["action_log"].size(),"all events recorded "+str(seed))
		var packed:Dictionary=Store.pack(s)
		check(packed.get("ok",false),"completed match integrity pack "+str(seed)+" at action "+str(count))
		if packed["ok"]:
			var restored:Dictionary=Store.unpack(packed["serialized"])
			check(restored["ok"],"completed match replay "+str(seed)+" "+str(restored.get("error","")))
			if restored["ok"]:
				check(int(restored["state"]["winner"])==int(s["winner"]),"winner not changed by roundtrip "+str(seed))
				check(int(restored["state"]["players"][int(s["winner"])]["marks"])>=10,"winning marks preserved "+str(seed))
		check(count<400,"no unbounded match "+str(seed))
