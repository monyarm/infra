______________________________________________________________________

## name: feedback_generic_shared_tooling description: "Never hardcode single-consumer logic into shared repo tooling (update-sources.py, lib/\*); keep additions generic and check for existing native support before hand-rolling." metadata: node_type: memory type: feedback originSessionId: 2a85a860-258a-48c6-a6b9-bb36f603f849

Two related rules from the same session (Claude Code nix module build-out):

1. **Shared scripts stay generic.** `update-sources.py` is used by the whole repo
   (games, tools, fonts...). Adding a function hardcoded to one consumer
   (`process_caveman_cli_pnpm_deps` with a baked-in `pnpmWorkspaces`/`prePnpmInstall`
   for one package) drew immediate, sharp pushback. New section types added to it
   (e.g. `[github-release]`) must stay parametric — same shape as the existing
   `[go]`/`[npm]` sections (take a source-name reference + generic params), not a
   bespoke one-off function.
1. **Check for existing native support before hand-rolling.** Before writing a new
   home-manager module from scratch, checked whether `programs.claude-code` already
   existed upstream — it did, at the exact pinned nixpkgs/home-manager rev, and
   supported plugins/mcpServers/settings/context directly. Don't assume greenfield
   just because the repo hasn't used something yet.

**Why:** Shared tooling used across an entire large repo needs to stay predictable
and reusable; anyone touching it later (including future-me) shouldn't have to
read past a pile of single-purpose special cases. See also \[[feedback_minimal_abstractions]\].

**How to apply:** Before adding to a shared script or hand-building infra, ask (a)
does this already exist upstream/natively, (b) if I'm adding new capability to
shared tooling, would a *different* consumer with a different name/shape be able
to reuse this without editing it.
