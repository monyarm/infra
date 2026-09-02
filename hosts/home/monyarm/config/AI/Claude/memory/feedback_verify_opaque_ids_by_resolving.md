---
name: feedback-verify-opaque-ids-by-resolving
description: "Opaque numeric ids carried over from an earlier research pass (moddb file ids, etc.) can be silently wrong; resolve and check what they actually point to before wiring them in, not just before/after a failed build"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 16dd47ec-4739-46a7-bab4-6ccc43f50f6a
---

Hit this twice in one session on the WadFusion/roguelike-stack work: `sources.toml`'s
`[moddb] wad.doomZero = "259737"` and `wad.tnt2Devilution = "282106"` were both carried
over uncommitted from an earlier research pass. `259737` didn't resolve at all (bot-check
page). `282106` resolved fine and even fetched successfully — but the file it resolved to
(`CFCS_Release_8_Patch_3.2.zip`, some unrelated Source-port config pack) had nothing to do
with TNT2: Devilution. A successful fetch does not mean the id is right.

**Why:** unlike a URL or a named path, a bare numeric id (moddb file id, Steam depot id,
etc.) carries no self-checking information — nothing about `282106` looks wrong on
inspection, and `update-sources.py` will happily fetch and hash whatever it resolves to
without noticing it's the wrong mod. [[feedback_verify_against_pinned_version]] and
[[feedback_verify_formats_before_implementing]] are about which version/format to trust;
this is about not trusting an opaque id at all until its resolved content is inspected.

**How to apply:** before wiring any moddb/similarly opaque numeric id into `sources.toml`,
actually resolve it first (curl the download-start page with the repo's moddb
headers/TLS-max-1.2 workaround, or just build it and read `sources.nix`'s recorded
`files`/`resolvedUrl` afterward) and confirm the filename/content matches what's expected —
don't take a previously-recorded id on faith just because it's already sitting in the
file. If a wrong id is already committed to `sources.nix`, deleting the stale generated
block and re-running `update-sources.py --append` (see
[[feedback_update_sources_no_help_flag]]) is fine — that's correcting a mistake by letting
the real tool redo its job, not hand-fabricating source data.
