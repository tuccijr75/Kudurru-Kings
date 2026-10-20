extends RefCounted
## Validates known composition restrictions; certified-card whitelist added at M2.
const FACTIONS = ["BorderstoneGuild", "FloodbornPact", "SkyloomTemple", "UnderwellKeepers", "Fateforge"]
const FAMILIES = ["Character", "Boss", "Edict", "HostSigil", "Name", "Pet", "Relic", "Site"]
const RARITIES = ["Common", "Uncommon", "Rare", "SuperRare", "Legendary", "Ultra"]

static func validate(cards: Array) -> Dictionary:
	var errors: Array = []
	if cards.size() != 36: errors.append("DECK_SIZE_36")
	var copies: Dictionary = {}
	var families: Dictionary = {}
	var factions: Dictionary = {}
	var contains_lock: bool = false
	for item in cards:
		if typeof(item) != TYPE_DICTIONARY:
			errors.append("INVALID_CARD")
			continue
		var c: Dictionary = item
		var name: String = str(c.get("card_name", ""))
		var id: String = str(c.get("card_id", ""))
		var fam: String = str(c.get("card_family", ""))
		var faction: String = str(c.get("owner_faction", ""))
		var rarity: String = str(c.get("rarity", ""))
		if id.is_empty() or name.is_empty(): errors.append("MISSING_ID")
		if not FAMILIES.has(fam): errors.append("UNKNOWN_FAMILY")
		if not FACTIONS.has(faction): errors.append("UNKNOWN_FACTION")
		if not RARITIES.has(rarity): errors.append("UNKNOWN_RARITY")
		if rarity == "Ultra" and name != "Anu" and name != "Adamu": errors.append("ULTRA_IDENTITY")
		if not bool(c.get("is_standard_legal", false)) or bool(c.get("scenario_only", false)):
			errors.append("NOT_STANDARD_LEGAL")
		copies[name] = int(copies.get(name, 0)) + 1
		families[fam] = int(families.get(fam, 0)) + 1
		factions[faction] = true
		if bool(c.get("requires_faction_lock", false)): contains_lock = true
		var cap: int = mini(2, int(c.get("deck_copy_limit", 2)))
		if rarity == "SuperRare": cap = mini(cap, 1)
		if int(copies[name]) > cap: errors.append("COPY_LIMIT")
	if int(families.get("Character", 0)) < 12: errors.append("MIN_12_CHARACTERS")
	if int(families.get("Site", 0)) < 2: errors.append("MIN_2_SITES")
	if int(families.get("Pet", 0)) + int(families.get("Relic", 0)) < 4: errors.append("MIN_4_SUPPORT")
	if int(families.get("Boss", 0)) > 3: errors.append("MAX_3_BOSSES")
	if int(families.get("Name", 0)) > 3: errors.append("MAX_3_NAMES")
	if int(families.get("HostSigil", 0)) > 1: errors.append("MAX_1_HOST_SIGIL")
	if contains_lock and factions.size() > 1: errors.append("FACTION_LOCK_REQUIRES_CARD_SPECIFIC_REVIEW")
	var unique_errors: Array = []
	for e in errors:
		if not unique_errors.has(e): unique_errors.append(e)
	return {"legal": unique_errors.is_empty(), "errors": unique_errors, "composition": "pure" if factions.size() == 1 else "mixed", "pure_faction_bonus_active": false}
