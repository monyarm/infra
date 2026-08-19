{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./skills.nix
    ./mcp.nix
    # ./omniroute-proxy.nix # Stability issues
    ./Claude
  ];

  options.ai = {
    skills = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = "Tool-agnostic skill directories, keyed by installed skill name.";
    };
    mcp = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = "Tool-agnostic MCP server definitions (command/args/env/type), keyed by server name.";
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

    home.packages = [ pkgs.omniroute ];
  };
}
