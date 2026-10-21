extends SceneTree
const Match=preload("res://scripts/match_integrator.gd")
const Decks=preload("res://scripts/deck_registry.gd")
const Lobby=preload("res://scripts/match_deck_lobby.gd")
const Storage=preload("res://scripts/match_storage.gd")
var passed:int=0
var failed:int=0
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:
		failed+=1
		printerr("FAIL: "+label)
func wait_frames(n:int=6)->void:
	for i in range(n):await create_timer(0.04).timeout
static func ids(seat:int)->Array:
	var out:Array=[]
	for card in Match._deck("BorderstoneGuild" if seat==0 else "UnderwellKeepers"):out.append(str(card["card_id"]))
	return out
func packet(client:Control,revision:Variant,cards:Variant,token:String="",extra:Dictionary={})->void:
	var body:Dictionary={"type":"SELECT_DECK","token":client.token if token.is_empty() else token,"deck_revision":revision,"card_ids":cards}
	for key in extra:body[key]=extra[key]
	client.peer.put_data((JSON.stringify(body)+"\n").to_utf8_buffer())
func _initialize()->void:call_deferred("run")
func run()->void:
	var original:Dictionary=Lobby.create()
	var snapshot:String=JSON.stringify(original)
	for cards in [null,{},[],ids(0).slice(0,35)]:
		check(not Lobby.select(original,0,0,cards)["ok"],"invalid deck container or size refused")
	for value in [null,1,true,[],{}]:
		var malformed:Array=ids(0);malformed[0]=value
		check(not Lobby.select(original,0,0,malformed)["ok"],"non-string source ID refused")
	for revision in [null,0.5,"0",true,-1]:
		check(not Lobby.select(original,0,revision,ids(0))["ok"],"malformed or stale revision refused")
	var unsupported:Array=ids(0);unsupported[unsupported.find("241")]="249"
	check(not Lobby.select(original,0,0,unsupported)["ok"],"unimplemented Gecko remains disabled")
	var copies:Array=ids(0);copies[0]=copies[1];copies[2]=copies[1]
	check(not Lobby.select(original,0,0,copies)["ok"],"source copy limits enforced")
	var submitted:Array=ids(0)
	var first:Dictionary=Lobby.select(original,0,0,submitted)
	check(first["ok"] and not first["state"]["started"],"first legal lock awaits opponent")
	check(JSON.stringify(original)==snapshot,"lobby reducer leaves caller untouched")
	submitted[0]="999999"
	check(first["state"]["deck_ids"][0]==ids(0),"locked IDs are detached from caller array")
	var public_view:Dictionary=Lobby.projection(first["state"])
	public_view["ready"][0]=false
	check(first["state"]["ready"][0],"public projection cannot mutate private readiness")
	check(not Lobby.select(first["state"],0,1,ids(0))["ok"],"locked deck cannot change")
	check(not Lobby.select(first["state"],1,0,ids(1))["ok"],"stale simultaneous lock refused")
	var second:Dictionary=Lobby.select(first["state"],1,1,ids(1))
	check(second["ok"] and second["state"]["started"],"second lock starts once")
	check(not Lobby.select(second["state"],1,2,ids(1))["ok"],"started lobby cannot redeal")
	check(not Lobby.projection(first["state"]).has("deck_ids"),"public readiness has no deck identities")
	var scene:PackedScene=load("res://scenes/local_match_client.tscn")
	var a:Control=scene.instantiate();root.add_child(a)
	a._host_and_join(true)
	await wait_frames()
	var b:Control=scene.instantiate();root.add_child(b);b._join()
	await wait_frames()
	check(a.seat==0 and b.seat==1,"two authenticated real client seats")
	if a.seat!=0 or b.seat!=1:b.free();a.free();quit(1);return
	check(a.view.has("lobby") and b.view.has("lobby"),"both receive deck lobby")
	check(not a.view.has("players") and not b.view.has("players"),"no initial hands or deck order before locks")
	check(not a.deck_lock.disabled and not b.deck_lock.disabled,"both UI deck lock controls available")
	check(a.keep_button.disabled and b.next_button.disabled,"gameplay controls withheld during deck choice")
	snapshot=JSON.stringify(a.host_node.game)
	var lobby_snapshot:String=JSON.stringify(a.host_node.deck_lobby)
	packet(a,0,ids(0),"forged")
	await wait_frames(3)
	check(a.status.text.contains("BAD_SESSION_TOKEN"),"unauthenticated deck lock refused")
	packet(a,0.5,ids(0))
	await wait_frames(3)
	check(a.status.text.contains("DECK_REVISION_REQUIRED"),"fractional network revision refused")
	packet(a,0,unsupported)
	await wait_frames(3)
	check(a.status.text.contains("CANDIDATE_DECK_INVALID"),"real host refuses unsupported card")
	check(JSON.stringify(a.host_node.deck_lobby)==lobby_snapshot and JSON.stringify(a.host_node.game)==snapshot,"invalid requests preserve lobby and undealt match")
	a.peer.put_data((JSON.stringify({"type":"ACTION","token":a.token,"action":{"type":"KEEP","revision":0}})+"\n").to_utf8_buffer())
	await wait_frames(3)
	check(a.status.text.contains("BOTH_DECKS_REQUIRED"),"transport blocks gameplay before locks")
	var custom:Array=ids(0);custom.reverse()
	custom[custom.find("239")]="254"
	packet(a,0,custom,"",{"seat":1})
	await wait_frames()
	check(a.host_node.deck_lobby["ready"]==[true,false],"forged packet seat ignored; sender locks own deck")
	if not a.host_node.deck_lobby["ready"][0]:b.free();a.free();quit(1);return
	check(a.deck_lock.disabled and not b.deck_lock.disabled,"only confirmed player's UI locks")
	check(not a.view.has("players") and not b.view.has("players"),"first lock exposes neither hand")
	packet(a,1,ids(0))
	await wait_frames(3)
	check(a.status.text.contains("DECK_ALREADY_LOCKED"),"first player cannot swap after opponent sees readiness")
	packet(b,0,ids(1))
	await wait_frames(3)
	check(b.status.text.contains("STALE_DECK_REVISION"),"stale second lock rejected without reset")
	var saved_name:String="M22test_"+str(Time.get_ticks_usec())
	var saved_ids:Array=ids(1);saved_ids.reverse()
	saved_ids[saved_ids.find("239")]="254"
	var saved:Dictionary=Decks.save(saved_name,saved_ids)
	check(saved.get("ok",false),"existing deck store saves legal candidate list")
	if not saved.get("ok",false):b.free();a.free();quit(1);return
	b.deck_pick.add_item(saved_name)
	b.deck_pick.set_item_metadata(b.deck_pick.item_count-1,saved_name)
	b.deck_pick.select(b.deck_pick.item_count-1)
	b._lock_deck()
	await wait_frames()
	check(not a.view.has("lobby") and not b.view.has("lobby"),"both final locks enter actual match")
	if a.view.has("lobby") or b.view.has("lobby"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Decks.file_path(saved_name)))
		b.free();a.free();quit(1);return
	check(a.host_node.game["initial_deck_ids"][0]==custom,"host uses selected custom list exactly")
	check(a.host_node.game["initial_deck_ids"][1]==saved_ids,"saved-deck UI submits selected source list")
	check(a.view["players"][0]["hand"].size()==6 and b.view["players"][1]["hand"].size()==6,"both get actual own six-card opening")
	check(not a.view["players"][1].has("hand") and not b.view["players"][0].has("hand"),"opponent hand stays private")
	check(not a.view.has("seed") and not a.view.has("initial_deck_ids"),"seed and full deck lists stay server-side")
	check(not a.keep_button.disabled and not b.keep_button.disabled,"actual keep/mulligan controls unlock")
	check(Storage.pack(a.host_node.game).get("ok",false),"custom match initial state replays and conserves 36 cards each")
	a._send_action("KEEP");await wait_frames(3)
	b._send_action("MULLIGAN");await wait_frames(3)
	a._send_action("ADVANCE");await wait_frames(3)
	check(a.view["setup_complete"] and b.view["phase"]==1,"independent opening decisions continue into real Draw")
	check(Storage.pack(a.host_node.game).get("ok",false),"actual network custom-deck actions replay with card conservation")
	snapshot=JSON.stringify(a.host_node.game)
	packet(b,2,ids(1))
	await wait_frames(3)
	check(b.status.text.contains("DECK_SELECTION_CLOSED") and JSON.stringify(a.host_node.game)==snapshot,"post-deal request cannot redeal or alter running match")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Decks.file_path(saved_name)))
	b.free();a.free()
	print("KUDURRU_M22_NETWORK_DECK_LOBBY passed=%d failed=%d" % [passed,failed])
	quit(0 if failed==0 else 1)
