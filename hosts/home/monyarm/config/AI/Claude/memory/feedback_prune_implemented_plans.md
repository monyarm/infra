---
name: feedback-prune-implemented-plans
description: ".claude/plans should only hold unimplemented work: remove implemented plans with git rm and repoint anything that referenced them"
metadata:
  type: feedback
  origin: opencode
  modified: 2026-11-13T23:05:17.131Z
---

Keep `.claude/plans/` limited to plans that are not yet implemented. When a plan's work has landed, delete it with `git rm` (history keeps it), and keep anything still open or that is a research report rather than a plan.

**Why:** The user asked for this cleanup on 2026-11-14 ("clean up .claude/plans, cause we've done this, and there are others in there that are already implemented") — stale plans mislead later sessions about what is left to do.

**How to apply:** Before deleting, check whether the work really exists in the tree (grep the repo for the files/options the plan describes) and whether the plan still has an open task (e.g. a component never referenced by any `.nix`), in which case keep it. Then grep for references to the deleted path — SDD ledgers (`./.superpowers/sdd/<name>/progress.md`) and memories under `hosts/home/monyarm/config/AI/Claude/memory/` cite plan paths too — and repoint or reword them. Deletions alone do not need a `nix flake check`.
