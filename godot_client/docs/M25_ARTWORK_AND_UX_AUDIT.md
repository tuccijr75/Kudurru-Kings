# M25 artwork evidence and UI acceptance boundary

Baseline: `45999124d5d6a19d539efe8c7c66734ea4dec290`. Production CLOSED.

Shipping Rules §§31–32 require the layered asset pipeline, Ultra overrides, locked family visual identity and inspectable field dominance, Trials, Audit level, Name ownership, Bind/Downed/capture/raid states and End income. Release gates G6–G7 additionally require verified card-to-image mapping, permitted use, legibility, accessibility and human/device acceptance.

## Reproducible inventory

Run `python godot_client/tools/audit_card_assets.py` from repository root. The generated `data/card_asset_audit_v1.json` covers every canonical master card ID and pins the master SHA256. `--check` exits nonzero when evidence is missing or invalid; the inventory command alone succeeds while recording blockers. This is independent of runtime card-effect certification.

Current result: **0/754 complete artwork-evidence records**, **754 missing card mappings**, no certification manifest. This means no per-card evidence has been provided to this audit; it does not establish that the user's separate art archives contain zero usable images. Source `art_prompt_ref`, `render_template_ref` and `asset_package_ref` fields are references, not identity or rights approval. The repository tracks generic family/back/border layers and an archive; their presence alone cannot certify any card.

No asset archive was expanded, downloaded or published by this work. No artwork was generated and no private lore reference was added to the repository.

## Manifest contract

The optional input `godot_client/data/card_asset_manifest_v1.json` uses schema `kudurru_card_asset_manifest_v1`, a canonical master `source_sha256` and `cards` list. Each record requires:

- exact source `card_id`, `card_name`, `card_family`, and SHA256 of UTF-8 `rules_text` in `rules_sha256`;
- repository-relative `image_path` and exact `image_sha256`;
- `rights_evidence`, `identity_review` and `legibility_review`, each containing an evidence-file `path`, `sha256` and named `reviewer`.

Only nonsymlink-escaping local files are accepted. Traversal, absolute/Windows paths, missing files, stale hashes/source identity, duplicate mappings (including lexical/internal-symlink image aliases), malformed records and unknown IDs are rejected or reported. Reusing an image across records remains flagged for identity review. Evidence references must be public-safe approved attestations; do not put contracts, personal data or private EOE material into a public repository.

The tool checks reference integrity, not the truth or legal sufficiency of evidence contents, whether a file decodes as an image, its artistic quality or visual legibility. Even a complete evidence record stays `production_certified: false`. A human review and broader production acceptance process remain necessary.

## Current UI audit and remaining acceptance

Static inspection of `real_match_ui.gd` and `local_match_client_ui.gd` confirms text/control candidate presentation, source-card action selectors, defender consent and End-income preview. M24 documents all-seat public standings and own-hand-only network projections. Neither static inspection nor headless UI assertions establishes readable art, accessibility, controller support or full board acceptance.

Required manual matrix remains open: solo/2/3/4 seats; setup and legal deck errors; full seven-phase operation; own/opponent visibility; every implemented action prompt; all §32 state indicators once their rules are integrated; dense four-seat layouts; long names/tooltips; supported window sizes/scaling; keyboard focus and gamepad where required; color/contrast and status readability; recovery/error feedback; real Windows graphics/performance and complete-match playtests. Unimplemented Boss/Name/raid states cannot be visually certified through placeholders.

Focused verification: `python -m unittest discover -s godot_client/tests -p test_card_asset_audit.py` passes 15 fixture tests. `python godot_client/tools/audit_card_assets.py --check` intentionally exits1 on the actual incomplete754-card evidence inventory. No full Godot gate or human visual acceptance is claimed for this tooling-only change.
