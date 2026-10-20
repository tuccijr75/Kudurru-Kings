extends SceneTree
var passed:int=0
var failed:int=0
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:
		failed+=1
		printerr("FAIL: "+label)
func wait_frame_count(count:int)->void:
	for i in range(count):
		await create_timer(0.04).timeout
func _initialize()->void:
	call_deferred("run")
func run()->void:
	var scene:PackedScene=load("res://scenes/local_match_client.tscn")
	check(scene!=null and scene.can_instantiate(),"localhost client scene can instantiate")
	if scene==null or not scene.can_instantiate():quit(1);return
	var a:Control=scene.instantiate()
	root.add_child(a)
	check(a.seat==-1,"unconnected UI has no authority")
	check(a.view.is_empty(),"unconnected player has no private state")
	a._host_and_join()
	await wait_frame_count(8)
	check(a.host_node!=null,"first window starts actual authoritative Godot server")
	check(a.seat==0,"first TCP client authenticated as Seat 0")
	check(a.token.length()==64,"host issues independent random 256-bit token")
	check(not a.view.is_empty(),"Seat 0 has server projection")
	if a.seat!=0:
		a.free()
		quit(1)
		return
	check(a.view["players"][0].get("hand",[]).size()==6,"Seat 0 sees own six real cards")
	check(not a.view["players"][1].has("hand"),"Seat 0 never sees opponent hidden hand")
	check(a.host_node.claimed_seats.size()==1,"host claims Seat 0 on real connect")
	var b:Control=scene.instantiate()
	root.add_child(b)
	b._join()
	await wait_frame_count(8)
	check(b.seat==1,"second independent client authenticated as Seat 1")
	check(b.token.length()==64 and b.token!=a.token,"each seat holds distinct secret token")
	check(b.view["players"][1].get("hand",[]).size()==6,"Seat 1 sees own six real cards")
	check(not b.view["players"][0].has("hand"),"Seat 1 cannot see original Seat 0 hand")
	check(a.host_node.claimed_seats.size()==2,"both seats remain explicitly reserved")
	check(not a.keep_button.disabled and not b.keep_button.disabled,"independent opening choices enabled")
	var c:Control=scene.instantiate()
	root.add_child(c)
	c._join()
	await wait_frame_count(8)
	check(c.seat==-1,"third client cannot claim a third seat")
	check(c.token.is_empty(),"third client has no session token")
	a._send_action("KEEP")
	await wait_frame_count(6)
	check(int(a.view["revision"])==1 and int(b.view["revision"])==1,"both views observe first authoritative revision")
	check(a.view["players"][0]["setup_ready"],"Seat 0 source-approved opening decision recorded")
	check(not a.view["players"][1]["setup_ready"],"Seat 1 has not auto-accepted")
	b._send_action("KEEP")
	await wait_frame_count(6)
	check(int(a.view["revision"])==2 and int(b.view["revision"])==2,"second player's chosen opening decision synchronized")
	check(a.view["setup_complete"] and b.view["setup_complete"],"server match starts only after both players confirmed")
	b._send_action("ADVANCE")
	await wait_frame_count(4)
	check(int(b.view["revision"])==2,"out-of-turn network action rejected")
	a._send_action("ADVANCE")
	await wait_frame_count(6)
	check(int(a.view["revision"])==3 and int(b.view["revision"])==3,"server safely advances one legal phase")
	check(int(a.view["phase"])==1 and int(b.view["phase"])==1,"both clients see same Draw phase")
	check(not a.view["players"][1].has("hand") and not b.view["players"][0].has("hand"),"private hand projection maintained after game advances")
	check(not a.view.has("seed") and not a.view.has("action_log"),"no random seed or server action history leaked")
	var first:String=str(a.view["players"][0]["hand"][0]["card_id"])
	check(not first.is_empty(),"actual source card accessible to its owning seat")
	# A departed seat's private state cannot be transferred to a third
	# untrusted localhost client. This preview intentionally lacks reconnect.
	b.peer.disconnect_from_host()
	await wait_frame_count(5)
	var late:Control=scene.instantiate()
	root.add_child(late)
	late._join()
	await wait_frame_count(6)
	check(late.seat==-1 and late.token.is_empty(),"disconnect does not reassign claimed private seat")
	check(a.host_node.claimed_seats.size()==2,"claimed seats held until server is closed")
	late.free()
	c.free()
	b.free()
	a.free()
	print("KUDURRU_M15_TWO_REAL_CLIENTS passed=%d failed=%d" % [passed,failed])
	quit(0 if failed==0 else 1)
