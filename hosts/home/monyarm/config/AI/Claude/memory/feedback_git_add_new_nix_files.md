______________________________________________________________________

## name: git-add-new-nix-files description: "Always `git add` a newly-created .nix (or other flake-relevant) file immediately, or flake evaluation silently can't see it." metadata: node_type: memory type: feedback originSessionId: d24c4aa1-6d5f-4fe7-98d1-668cb8eef1f1

When creating a new file that the flake needs to evaluate (a new `.nix` module, a companion script referenced via `./foo.sh`-style path, etc.), `git add` it right away — don't wait until a batch commit later.

**Why:** `builtins.getFlake (toString ./.)` on a local git repo only sees git-tracked (at least staged) files. In the ~/.nix session, a newly-added `lib/optimize/decorate.nix` was left untracked (`??` in `git status`) and caused a confusing `attribute 'decorate' missing` failure deep in an unrelated build — the file existed on disk and was correct, but was invisible to the flake. Same class of bug recurred with several other new handler files (flac.nix, glsl.nix, obj.nix, etc.) all being untracked at once.

**How to apply:** Right after Write-ing a new file under a Nix flake's source tree, run `git add <path>` before doing any `nix eval`/`nix build` that exercises it. This applies to every new file added this session (c.nix, wma.nix, mod.nix, modstrip.py, etc.) — get in the habit of staging immediately rather than batching it at the end.
