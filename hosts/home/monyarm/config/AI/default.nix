{
  lib,
  ...
}:
{
  imports = [
    ./skills.nix
    ./mcp.nix
    ./Claude
    ./OpenCode
  ];

  options.ai = {
    skills = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = "Tool-agnostic skill directories, keyed by installed skill name.";
    };
    agentMd = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Shared, tool-agnostic agent instructions. Tool-specific configs (Claude, future others) extend this with their own additions.";
    };
  };

  config = {
    ai.agentMd = ''
      # Repo-wide agent reminders

      - Never run `find`/`du`/`ls` recursively over the whole `/nix/store` or `/`, and never
        pipe `nix build`/`nix eval` output through `tail`/`head` or wrap it in `timeout`.
    '';

  };
}
