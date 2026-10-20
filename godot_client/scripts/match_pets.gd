extends RefCounted
## Source-pinned Pet reactions used by the integrated authoritative reducer.
const Source = preload("res://scripts/real_effects.gd")
const HALO_PUP := "241"
const HALO_HASH := "9d8b1b4b296c74bcd2ce75bf3c18cb49671e25728cf8cd1cb7e486a6ccd554d1"

static func verified() -> bool:
	var card: Dictionary = Source.find_card(Source.catalog(), HALO_PUP)
	return card.get("card_family") == "Pet" and card.get("rules_sha256") == HALO_HASH and str(card.get("rules_text", "")).replace("\r\n", "\n").sha256_text() == HALO_HASH

# Mutates only the reducer's already-validated private working copy.
# Printed text says cancel, not 'may': no choice or payment is invented.
static func cancel_displace(state: Dictionary, host: Dictionary) -> Dictionary:
	for pet in state["attachments"]:
		if str(pet.get("card_id", "")) != HALO_PUP or str(pet.get("host_uid", "")) != str(host["uid"]): continue
		if int(pet.get("controller", -1)) != int(host["controller"]): continue
		if not verified(): return {"ok": false, "error": "HALO_PUP_SOURCE_CHANGED"}
		if int(pet.get("guard_used_round", -1)) == int(state["round"]): continue
		pet["guard_used_round"] = int(state["round"])
		return {"ok": true, "canceled": true}
	return {"ok": true, "canceled": false}

static func guard_label(pet: Dictionary, round_number: int) -> String:
	if str(pet.get("card_id", "")) != HALO_PUP: return ""
	return "Radiant Guard: " + ("SPENT THIS ROUND" if int(pet.get("guard_used_round", -1)) == round_number else "READY")
