{
  dirs,
  autoImport,
  ...
}:
rec {
  home.username = builtins.getEnv "USER";
  home.homeDirectory = dirs.HOME;
  home.stateVersion = "25.05";
  home.pointerCursor.enable = true;
  programs.home-manager.enable = true;
  systemd.user.startServices = "sd-switch";

  imports = (autoImport ./config) ++ (autoImport ./games);
}
