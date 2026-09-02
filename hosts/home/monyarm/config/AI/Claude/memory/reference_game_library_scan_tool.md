---
name: reference-game-library-scan-tool
description: packages/game-library-scan.nix is the existing owned-game-vs-external-catalog cross-referencing tool — check it before proposing a new scanning/catalog script.
metadata: 
  node_type: memory
  type: reference
  originSessionId: 913da512-b3a2-443b-bc56-75b3633c275e
---

`packages/game-library-scan.nix` (a `writers.writePython3Bin` derivation) is the canonical "what do I own vs. what's out there" scanner in this repo. It already:

- Pulls owned titles live at scan time (not via `update-sources.py`/Nix eval) from GOG (`lgogdownloader --list=json`), Epic (`legendary list --json`), Steam (Web API + local `.acf` fallback), and Maxima (`maxima-cli list-games`), using `sops`-decrypted secrets.
- Excludes titles already defined in this repo via `~/.local/share/game-library-scan/already-defined.json` (`PROVIDER_ID_KEYS` maps provider → this repo's own id field).
- Has a `--scummvm` mode: fuzzy-matches owned titles against `scummvm --list-games` using a block-then-fuzzy scheme (`build_index`/`significant_words`/`fuzzy_matches`) — an inverted-word-index prefilter before running `difflib.SequenceMatcher`, to keep an O(owned × scummvm) comparison fast.
- Default (no flag) mode just lists owned-but-undefined titles per provider, plus a "Multi-Provider" section for titles owned on more than one storefront.

**Why this matters:** when a task needs "cross-reference owned games against an external engine/catalog" (e.g. Ren'Py via VNDB), the instinct to write a new standalone script (`scripts/renpy-catalog.py`) is wrong — extend this file with a new mode flag instead, reusing `build_index`/`fuzzy_matches` and the `sources` dict it already builds. Caught mid-plan when the user corrected exactly this mistake for a Ren'Py catalog-scan feature. See [[feedback_minimal_abstractions]] for the general principle.

**How to apply:** before writing any new "scan/list/cross-reference owned games" script, read this file first — it's very likely already 80% of what's needed via a new mode flag on the existing argparse.
