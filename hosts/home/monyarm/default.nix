{
  dirs,
  autoImport,
  ...
}:
rec {
  home.username = builtins.getEnv "USER";
  home.homeDirectory = dirs.HOME;
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;

  imports = autoImport ./config;
}
