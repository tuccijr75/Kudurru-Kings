#!/usr/bin/env python3
"""Build a deterministic read-only, explicitly uncertified KK catalog.
Source of truth is repository Gameplay_Master_v1.csv, not this derivative JSON.
Known EOE world-authority corrections apply only as a clearly labeled overlay.
Never convert a provisional card into a playable card.
"""
from __future__ import annotations
import csv
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "02_Data" / "Kudurru_Kings_Gameplay_Master_v1.csv"
OUT = ROOT / "godot_client" / "data" / "catalog_preview.json"
REQUIRED = (
    "card_id", "card_slug", "card_name", "card_family", "owner_faction",
    "rarity", "cost_sinew", "cost_sigil", "cost_oath",
    "is_standard_legal", "requires_faction_lock", "deck_copy_limit"
)
FACTIONS = {"BorderstoneGuild", "FloodbornPact", "SkyloomTemple", "UnderwellKeepers", "Fateforge"}
FAMILIES = {"Character", "Boss", "Edict", "HostSigil", "Name", "Pet", "Relic", "Site"}
# Verified explicit EOE alignments; do not infer assignments for remaining records.
EOE_VERIFIED = {
    "Drowned Archivist": "UnderwellKeepers",
    "Ash Prophetess": "Fateforge",
    "Chain Marshal": "BorderstoneGuild",
    "Taxlord Balash": "BorderstoneGuild",
    "Silver Mask Judge": "SkyloomTemple",
    "Adamu": "BorderstoneGuild",
}

def build() -> dict:
    raw = SRC.read_bytes()
    with SRC.open("r", encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        headers = set(reader.fieldnames or ())
        missing = set(REQUIRED) - headers
        if missing:
            raise ValueError("Required source fields absent: " + ", ".join(sorted(missing)))
        rows = list(reader)
    if len(rows) != 754:
        raise ValueError(f"Expected 754 inherited card records, found {len(rows)}")
    ids, slugs = set(), {}
    slug_collisions = []
    cards = []
    mismatches = []
    for row in rows:
        identity = str(row["card_id"]).strip()
        slug = str(row["card_slug"]).strip()
        name = str(row["card_name"]).strip()
        faction = str(row["owner_faction"]).strip()
        family = str(row["card_family"]).strip()
        if not identity or not slug or not name or identity in ids:
            raise ValueError(f"Missing/duplicate immutable identity: {identity} {slug}")
        if faction not in FACTIONS or family not in FAMILIES:
            raise ValueError(f"Unsupported owner faction or family: {identity}")
        ids.add(identity)
        if slug in slugs:
            slug_collisions.append({"slug": slug, "card_ids": [slugs[slug], identity]})
        else:
            slugs[slug] = identity
        verified = EOE_VERIFIED.get(name) if family == "Character" else None
        resolved_faction = verified or faction
        provenance = ("EOE_VERIFIED_CONFLICT" if verified and faction != verified
                      else ("EOE_VERIFIED_MATCH" if verified else "MIGRATED_PROVISIONAL"))
        if provenance == "EOE_VERIFIED_CONFLICT":
            mismatches.append({"card_id": identity, "card_name": name,
                               "source_faction": faction, "eoe_faction": resolved_faction})
        cost_source = {}
        for field in ("cost_sinew", "cost_sigil", "cost_oath"):
            value = str(row[field]).strip()
            if not value.isdigit():
                raise ValueError(f"Non-integer {field} at card {identity}")
            cost_source[field.removeprefix("cost_")] = int(value)
        cards.append({
            "card_id": identity,
            "slug": slug,
            "name": name,
            "family": family,
            "source_faction": faction,
            "display_faction": resolved_faction,
            "faction_provenance": provenance,
            "rarity": str(row["rarity"]).strip(),
            "reported_source_cost": cost_source,
            "cost_certification": "PENDING_REVIEW",
            "playable": False,
        })
    result = {
        "schema": "kudurru_catalog_preview_v1",
        "source_file": "02_Data/Kudurru_Kings_Gameplay_Master_v1.csv",
        "source_sha256": hashlib.sha256(raw).hexdigest(),
        "record_count": len(cards),
        "playable_count": 0,
        "faction_conflicts_corrected_for_display": mismatches,
        "source_slug_collisions": slug_collisions,
        "cards": cards,
        "certification": "RESEARCH_ONLY_DO_NOT_USE_FOR_MATCHES",
    }
    return result

def main() -> None:
    result = build()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    encoded = json.dumps(result, indent=2, sort_keys=True, ensure_ascii=False) + "\n"
    OUT.write_text(encoded, encoding="utf-8")
    print(json.dumps({
        "status": "CATALOG_UNCERTIFIED",
        "records": result["record_count"],
        "playable": result["playable_count"],
        "verified_eoe_conflicts": len(result["faction_conflicts_corrected_for_display"]),
        "source_sha256": result["source_sha256"],
        "output": str(OUT),
        "output_sha256": hashlib.sha256(encoded.encode("utf-8")).hexdigest(),
    }, sort_keys=True))

if __name__ == "__main__":
    main()
