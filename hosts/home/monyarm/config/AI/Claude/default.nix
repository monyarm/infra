{
  config,
  pkgs,
  dirs,
  mkOutOfStoreSymlink,
  ...
}:
{
  imports = [
    ./plugins.nix
    ./context.nix
    ./caveman-proxy.nix
  ];

  programs.claude-code = {
    enable = true;
    # package left unset -- resolves to pkgs.claude-code by default
    settings = {
      theme = "dark";
      editorMode = "normal";
      agentPushNotifEnabled = true;
      permissions.defaultMode = "plan";
      # OmniRoute combo, configured through its own UI/CLI -- see omniroute-proxy.nix
      # model = "custom/claude";
    };
    mcpServers = config.ai.mcp;
    skills = config.ai.skills;
  };

  # whole dir symlinked (not per-file) -- new memory files future sessions write land
  # straight in the git checkout, no module edits needed
  home.file.".claude/projects/-home-monyarm--nix/memory".source =
    mkOutOfStoreSymlink "${dirs.hmConfig}/AI/Claude/memory";

  home.file.".caveman-cloud/bin" = {
    source = "${pkgs.caveman-cli}/libexec/caveman-engine-bin";
    recursive = true;
  };

  home.packages = [
    pkgs.caveman-cli
    pkgs.codegraph
    # ponytail + caveman both run node-based lifecycle hooks (SessionStart/
    # UserPromptSubmit) -- degrade silently without node, but this makes them work
    pkgs.nodejs
  ];

  programs.zsh.shellAliases = {
    claude = "caveman claude";
  };

  home.sessionVariables = {
    # Routes claude through the local OmniRoute gateway (../omniroute-proxy.nix)
    # instead of Anthropic directly -- no CLI wrapping needed, and
    # --remote-control only works against the official Anthropic base URL anyway,
    # so it's dropped rather than kept as a bare flag.
    # ANTHROPIC_BASE_URL = "http://localhost:20128";
    # CLAUDE_CODE_SUBAGENT_MODEL = "custom/subagent";
    CLAUDE_CODE_SUBAGENT_MODEL = "haiku";
  };
}
