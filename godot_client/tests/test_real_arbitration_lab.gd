extends SceneTree
const Arb = preload("res://scripts/real_arbitration_lab.gd")
const FX = preload("res://scripts/real_effects.gd")
var passed: int = 0
var failed: int = 0

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		printerr("FAIL: " + label)

func fixture() -> Dictionary:
	var origin: Dictionary = FX.sandbox()["state"]
	var casted: Dictionary = FX.cast(origin, {"seat":0, "revision":0,
		"card_id":"199","args":{}})
	var s: Dictionary = casted["state"]
	s["permanents"][-1]["controller"] = 1 # Explicit opponent Name fixture
	return s

func _initialize() -> void:
	run_tests()
	print("KUDURRU_M5_ARBITRATION passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)

func run_tests() -> void:
	var root: Dictionary = fixture()
	check(Arb.open(root, "BOSS0", 0)["error"] == "ACTIVE_NAME_REQUIRED", "only Name target allowed")
	check(Arb.open(root, "REAL_1", 1)["error"] == "INVALID_CHALLENGER", "cannot contest own Name")
	var entry: Dictionary = Arb.open(root, "REAL_1", 0)
	check(entry["ok"], "real Name arbitration opened")
	if not entry["ok"]: return
	var s: Dictionary = entry["state"]
	check(s["players"][0]["marks"] == 0, "no fabricated starting marks")
	check(Arb.available_oath(s, 0) == 10, "post-cast real Oath remains")
	check(Arb.bid(s, 2, 1, s["revision"])["error"] == "NOT_PARTICIPANT", "nonparticipant rejected")
	check(Arb.bid(s, 0, 11, s["revision"])["error"] == "INSUFFICIENT_OATH_FOR_BID", "bid cannot exceed Oath")
	var initial: String = JSON.stringify(s)
	check(Arb.resolve(s, "Seize", s["revision"])["error"] == "BOTH_SEALED_BIDS_REQUIRED", "both bids required")
	check(JSON.stringify(s) == initial, "failed bids do not mutate state")
	var first: Dictionary = Arb.bid(s, 0, 3, s["revision"])
	check(first["ok"], "challenger commits hidden bid")
	var secret: Dictionary = first["state"]
	check(Arb.available_oath(secret, 0) == 7, "private escrow reserves exactly three")
	check(secret["players"][0]["oath"] == 10, "public balance does not reveal sealed bid")
	check(not Arb.public_view(secret).has("hidden_bids"), "public projection hides bids")
	check(not first["event"].has("amount"), "commit event hides bid")
	check(JSON.stringify(first["event"]).find("3") == -1 or first["event"]["revision"] == 3, "event contains no explicit amount")
	check(Arb.bid(secret, 0, 1, secret["revision"])["error"] == "BID_ALREADY_COMMITTED", "no bid overwrite")
	check(Arb.bid(secret, 1, 1, s["revision"])["error"] == "STALE_REVISION", "stale revision rejected")
	var second: Dictionary = Arb.bid(secret, 1, 1, secret["revision"])
	check(second["ok"], "defender commits hidden bid")
	var both: Dictionary = second["state"]
	check(Arb.public_view(both)["ready"] == [true, true], "sealed bid readiness public")
	check(not Arb.public_view(both).has("revealed_bids"), "bids sealed until resolution")
	check(Arb.resolve(both, "Suppress", both["revision"])["error"] == "UNRESOLVED_SUPPRESS_OR_CORRUPT_RULE", "unknown suppress outcome blocked")
	var result: Dictionary = Arb.resolve(both, "Seize", both["revision"])
	check(result["ok"], "Seize after higher Oath bid")
	if not result["ok"]: return
	var done: Dictionary = result["state"]
	check(done["permanents"][-1]["controller"] == 0, "Name control transferred to challenger")
	check(done["permanents"][-1]["owner"] == 0, "original owner protected")
	check(done["players"][0]["marks"] == 1, "source Name seizure awards 1 Mark")
	check(done["players"][0]["oath"] == 7, "challenger paid exactly three Oath")
	check(done["players"][1]["oath"] == 9, "defender paid exactly one Oath")
	check(done["arbitration"]["status"] == "RESOLVED", "arbitration lifecycle closed")
	check(done["events"][-1]["revealed_bids"] == [3,1], "bid totals revealed after both commits")
	check(Arb.resolve(done, "Seize", done["revision"])["error"] == "ARBITRATION_ALREADY_RESOLVED", "cannot double score")
	var lose: Dictionary = Arb.open(fixture(), "REAL_1", 0)["state"]
	lose = Arb.bid(lose, 0, 0, lose["revision"])["state"]
	lose = Arb.bid(lose, 1, 1, lose["revision"])["state"]
	result = Arb.resolve(lose, "Seize", lose["revision"])
	check(result["ok"] and not result["event"]["seized"], "defender higher bid wins")
	check(result["state"]["players"][0]["marks"] == 0, "failed challenge scores no Name seizure")
	check(result["state"]["permanents"][-1]["controller"] == 1, "defender retains Name")
	var tie: Dictionary = Arb.open(fixture(), "REAL_1", 0)["state"]
	tie["players"][0]["deck"] = ["255"]
	tie["players"][1]["deck"] = ["180"]
	tie = Arb.bid(tie, 0, 1, tie["revision"])["state"]
	tie = Arb.bid(tie, 1, 1, tie["revision"])["state"]
	result = Arb.resolve(tie, "Seize", tie["revision"])
	check(result["ok"], "tied bids use source Face-off")
	check(result["event"]["winner"] == 0, "valid combat reveal beats no valid card")
	check(result["event"]["revealed_bids"] == [1,1], "ties disclosed only after reveal")
	var unresolved: Dictionary = Arb.open(fixture(), "REAL_1", 0)["state"]
	unresolved = Arb.bid(unresolved, 0, 1, unresolved["revision"])["state"]
	unresolved = Arb.bid(unresolved, 1, 1, unresolved["revision"])["state"]
	initial = JSON.stringify(unresolved)
	check(Arb.resolve(unresolved, "Seize", unresolved["revision"])["error"] == "FACE_OFF_UNRESOLVED_BOTH_EMPTY", "undefined double-empty Face-off blocked")
	check(JSON.stringify(unresolved) == initial, "unresolved arbitration keeps private state intact")
