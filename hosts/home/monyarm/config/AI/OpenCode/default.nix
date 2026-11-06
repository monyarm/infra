{
  config,
  lib,
  pkgs,
  hostName ? "localhost",
  ...
}:
{
  programs.opencode = {
    enable = true;
    # llm-agents `opencode` is 1.x; 2.x is `opencode2`
    package = pkgs.llm-agents.opencode2;
    enableMcpIntegration = true;
    web = {
      enable = true;
      extraArgs = [
        "--hostname"
        hostName
      ];
    };
    context = config.ai.agentMd;
    # stylix still sets v1 `tui.theme`; drop once
    # https://github.com/nix-community/stylix/pull/2537 lands
    tui = lib.mkForce { };
    cli.theme.name = "stylix";
    settings = {
      update = "disable";
      model = "opencode-go/deepseek-v4.1-flash";
      agents.title.model = "opencode-go/mimo-v2.6-flash";
      share = "disabled";
      lsp = true;
      # C# LSP also requires Microsoft's C# extension in VS Code.
      mcp.servers.markitdown = {
        type = "local";
        command = [ "${pkgs.markitdown-mcp}/bin/markitdown-mcp" ];
        timeout = {
          startup = 60000;
          catalog = 60000;
          execution = 60000;
        };
      };
      plugins = [
        "@madsoftwaredev/opencode-direnv"
        "envsitter-guard"
        "@tarquinen/opencode-dcp"
        "@mohak34/opencode-notifier"
        "opencode-claude-memory"
        "@prevalentware/opencode-goal-plugin"
      ];
      permissions =
        map
          (action: {
            inherit action;
            resource = "~/.claude/**/memory/**";
            effect = "allow";
          })
          [
            "external_directory"
            "read"
          ]
        # direnv plugin has no approval tool; gate `direnv allow` here.
        ++ [
          {
            action = "shell";
            resource = "direnv allow *";
            effect = "ask";
          }
        ];
    };
  };

  # Consider tmux/Zellij integration later for observing concurrent agent work.
}
