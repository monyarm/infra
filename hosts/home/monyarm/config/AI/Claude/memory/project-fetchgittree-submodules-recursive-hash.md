---
name: fetchgittree-submodules-recursive-hash
description: "Why fetchGitTree's git submodule lines were commented out (sha1 tree hash cannot pin submodule content) and the decided fix: outputHashMode = \"recursive\" when submodules = true, plus --fetch-submodules in update-sources.py"
metadata:
  type: project
  origin: opencode
  modified: 2026-11-16T23:27:47.390Z
---

**Fact (2026-11-17, design agreed, not implemented):** `fetchGitTree`'s checkout cannot be pinned by the git-tree (sha1) hash once submodules are involved. A submodule is only a *gitlink* entry in the parent tree, so running `git submodule update --init` populates files that the sha1 tree hash never covers — the store path changes while the hash stays the same (fixed-output mismatch). That is exactly why the submodule lines in the fetcher, and `has_submodules` handling in `update-sources.py`, were commented out: the user's words were that submodules were commented because "we couldn't figure out how to get them to work with the sha1 tree hash".

**Decided fix (paper only):** when `submodules = true`, switch the fetcher to `outputHashMode = "recursive"` (sha256 NAR hash of the whole output), which is what nixpkgs' own `fetchgit { fetchSubmodules = true; }` does. Correspondingly `update-sources.py` needs a `--fetch-submodules` flag carried into its authoritative-hash branch (the `nix-prefetch-git` / `get_git_metadata` path) so recorded hashes actually match the recursive-mode output.

**Why:** the naive "just re-enable the commented `git submodule update --init` line" cannot work with a tree hash, and bypassing `sources.*.toml` with a bare `git+file:.?submodules=1` fetch contradicts the repo's source-vendoring policy.
**How to apply:** for OpenJKDF2 or any other submodule build, implement the recursive-hash path in the generic fetcher rather than special-casing the package; keep tree-hash (sha1) mode as the default for submodule-free sources so existing hashes stay valid.
