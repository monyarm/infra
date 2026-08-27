{
  config,
  pkgs,
  hostName ? "localhost",
  ...
}:
{
  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    web = {
      enable = true;
      extraArgs = [
        "--hostname"
        hostName
      ];
    };
    context = config.ai.agentMd;
    settings = {
      autoupdate = false;
      model = "opencode-go/gpt-5.6-luna";
      small_model = "opencode-go/deepseek-v4-flash";
      share = "disabled";
      compaction.prune = true;
      lsp = true;
      # C# LSP also requires Microsoft's C# extension in VS Code.
      mcp.markitdown = {
        command = [ "${pkgs.markitdown-mcp}/bin/markitdown-mcp" ];
        timeout = 60000;
        type = "local";
      };
      plugin = [
        "opencode-direnv"
        "envsitter-guard"
      ];
      permission = {
        external_directory."~/.claude/**/memory/**" = "allow";
        read."~/.claude/**/memory/**" = "allow";
      };
    };
  };

  # Consider tmux/Zellij integration later for observing concurrent agent work.
}
