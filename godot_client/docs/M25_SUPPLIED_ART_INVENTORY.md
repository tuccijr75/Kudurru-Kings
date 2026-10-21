# M25 supplied artwork inventory

Read-only inspection on 2026-10-21. Production CLOSED. No source images or private EOE material are added by this report.

## Supplied card layer archive

The specifically supplied `card_images (2).zip` is available and was inspected after confirming its 80,487,997-byte size. SHA256: `c997c4f134fc3c9ea988acd64d83f3ac6c53294a531dad936b8429fa459f8bd4`.

The archive contains **21 entries: one directory and 20 PNG files**, totaling 80,532,968 uncompressed bytes. All entry paths passed absolute-path/traversal/backslash/drive checks. Images were opened directly from archive streams for header/dimension inspection; archive contents were not extracted into the game or published.

| PNG input names inside `card_images/` | Count | Dimensions |
| --- | ---: | --- |
| `back_background.png` | 1 | 1409 ×2048 |
| `back_color_boss.png`, `back_color_character.png`, `back_color_edict.png`, `back_color_host_sigil.png`, `back_color_name.png`, `back_color_pet.png`, `back_color_relic.png`, `back_color_site.png`, `back_color_ultra.png` | 9 | 1357 ×2009 |
| `back_main.png` | 1 | 1357 ×2009 |
| `border_common.png`, `border_legendary.png`, `border_rare.png`, `border_super_rare.png`, `border_template.png`, `border_ultra.png`, `border_uncommon.png` | 7 | 1357 ×2009 |
| `front_background.png` | 1 | 1025 ×1514 |
| `front_main.png` | 1 | 1038 ×1514 |

Seventeen images therefore share 1357 ×2009 dimensions. Three use different dimensions; the render pipeline must explicitly establish their approved registration/scaling instead of assuming every layer aligns pixel-for-pixel. Three border files use indexed/palette mode (`border_legendary`, `border_super_rare`, `border_ultra`); the remaining 17 images report RGBA mode.

**All 20 PNG contents exactly match existing tracked `attached_assets/card_images/` blobs** at the inspected M24 baseline, verified by computing each Git blob object hash directly from the archive member bytes and comparing it to the local index. This archive adds no newly identified card illustrations relative to those tracked layers; the ZIP container bytes need not match another archive's compression.

These are reusable family/rarity/front/back render inputs. There are **zero individual card-ID or named-character illustrations in this archive**, no 754-card image mapping, and no rights attestation. A layer's supplied filename alone does not certify permitted use, final card identity or legibility.

## Separately supplied board and logo

| Source file | Bytes | Dimensions/mode | SHA256 |
| --- | ---: | --- | --- |
| `gameboard.png` | 3,500,917 | 1536 ×1024, RGBA | `161c28bac0c20b58fbaae1cbf877e53e723bf77284fe6cac358eb4521a9ab7ce` |
| `logo(1).png` | 3,197,512 | 1254 ×1254, RGBA | `aa2cef5334aa68ac046f6b49d682c3e01606134e99439d409951ea763737b1b7` |

Both exact named user-supplied files were resolved and inspected outside the repository. They are board/brand inputs, not card illustrations. They are not asserted to match similarly named tracked assets, and their dimensions alone establish neither visual acceptance nor rights.

## Remaining work

The art source blocker is now concrete: the supplied card ZIP provides 20 reusable layers, not 754 subject illustrations. Locate any separate original card illustration archive or explicitly approve a new artwork acquisition/creation batch; then map each genuine card ID to source image bytes, verify identity and permitted use, implement the approved layered registration/family/Ultra renderer and conduct human legibility/board acceptance. No new artwork generation, rights assumption, UI design change or publication is authorized by this inventory.

The source-pinned `audit_card_assets.py` inventory remains 0/754 complete per-card evidence records. The absence of a certification mapping does not claim that no other artwork exists; it accurately describes the inspected archive and current evidence manifest.
