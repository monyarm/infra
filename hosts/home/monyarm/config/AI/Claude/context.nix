{ config, ... }:
{
  programs.claude-code.context = config.ai.agentMd + ''

    # Claude-specific reminders

    - Check your memory index for the current project before starting nontrivial work:
      `~/.claude/projects/<project-slug>/memory/MEMORY.md` (slug = cwd path, `/` -> `-`).
    - Don't add a memory entry telling yourself to write tersely/caveman-style once the
      `caveman` plugin is active -- it already owns that behavior.
    - Invoke `caveman:caveman` and `ponytail:ponytail` at intensity "ultra" at the start
      of every session, and keep following it for every remaining turn, not just the
      first few.
  '';
}
