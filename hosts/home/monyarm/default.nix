{
  lib,
  dirs,
  ...
}:
rec {
  home.username = builtins.getEnv "USER";
  home.homeDirectory = dirs.HOME;
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;

  imports =
    let
      configDir = ./config;
      configImports = lib.filter (path: path != null) (
        lib.mapAttrsToList (
          name: type:
          if type == "directory" then
            if lib.pathExists "${configDir}/${name}/default.nix" then
              "${configDir}/${name}/default.nix"
            else
              null
          else if type == "regular" && lib.hasSuffix ".nix" name then
            "${configDir}/${name}"
          else
            null
        ) (builtins.readDir configDir)
      );
    in
    configImports;
}
