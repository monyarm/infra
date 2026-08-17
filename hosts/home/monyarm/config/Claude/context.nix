_: {
  programs.claude-code.context = ''
    # Global reminders

    - Check your memory index for the current project before starting nontrivial work:
      `~/.claude/projects/<project-slug>/memory/MEMORY.md` (slug = cwd path, `/` -> `-`).
    - Don't add a memory entry telling yourself to write tersely/caveman-style once the
      `caveman` plugin is active -- it already owns that behavior.
    - These are already in project memory (feedback_no_du_whole_nix_store.md,
      feedback_no_tail_short_logs.md) but keep getting broken anyway, so repeating
      them here directly: never run `find`/`du`/`ls` recursively over the whole
      `/nix/store` or `/`, and never pipe `nix build`/`nix eval` output through
      `tail`/`head` or wrap it in `timeout`.
    - Read `~/.claude/.caveman-active` / `~/.claude/.ponytail-active`. If a file
      exists and is non-empty, its content is the active intensity level (e.g.
      "full") -- invoke `caveman:caveman`/`ponytail:ponytail` with that level at
      the start of the session, and keep following it for every remaining turn,
      not just the first few.
  '';
}
