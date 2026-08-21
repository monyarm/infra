{
  config,
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
        "127.0.0.1"
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
      permission = {
        external_directory."~/.claude/**/memory/**" = "allow";
        read."~/.claude/**/memory/**" = "allow";
      };
    };
  };
}
