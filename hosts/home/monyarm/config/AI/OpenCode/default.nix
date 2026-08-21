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
      share = "disabled";
      compaction.prune = true;
      permission = {
        external_directory."~/.claude/**/memory/**" = "allow";
        read."~/.claude/**/memory/**" = "allow";
      };
    };
  };
}
