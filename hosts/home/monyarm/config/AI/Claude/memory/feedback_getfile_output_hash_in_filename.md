---
name: feedback-getfile-output-hash-in-filename
description: "getFile's output is a raw Nix store FILE, so its store path has the hash baked directly into the filename (\"<hash>-TNTR.wad\"), not a parent directory -- scripts deriving names/logic from a getFile path's basename must strip the hash prefix first"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 16dd47ec-4739-46a7-bab4-6ccc43f50f6a
---

`build_custom_maps.py` derives each map-pool source's display name and its
2-letter filename prefix from `os.path.basename(path)` of the `getFile`-produced
wad it's given. First real run against actual Nix-built paths (not my local
manual test files) printed names like `1phy3j9zga1n9yllg1g3xpr2rqwwrcxv-TNTR`
instead of `TNTR` -- the derived prefixes were effectively random per rebuild.

**Why:** most Nix package outputs are directories (`/nix/store/hash-name/bin/foo`),
so `basename` of a file *inside* one is clean. `getFile` (`lib/files.nix:322`)
returns the file itself as the derivation's `$out` -- for a single-file output,
Nix puts the hash directly in the top-level name (`/nix/store/hash-TNTR.wad`),
so `basename` returns the hash-prefixed string, not the clean name.

**How to apply:** before deriving anything (display names, filename prefixes,
grouping keys, etc.) from the basename of a `getFile` output's store path,
strip the leading `<32-char-base32-hash>-` first
(`re.sub(r"^[0-9a-z]{32}-", "", basename)` in Python, or the Nix-side
equivalent). Applies to any future script consuming `getFile`-produced paths
directly, not just this one.
