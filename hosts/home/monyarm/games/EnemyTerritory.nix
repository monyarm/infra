{
  pkgs,
  lib,
  config,
  ...
}:
let
  # ET:Legacy assets (pak0-2.pk3) ship with the nixpkgs wrapper; the engine
  # writes configs/profiles into fs_homepath, which must be writable.
  game = pkgs.writeShellApplication {
    name = "etlegacy";
    text = ''
      home="''${XDG_DATA_HOME:-$HOME/.local/share}/etlegacy"
      mkdir -p "$home"
      exec ${lib.getExe pkgs.etlegacy} +set fs_homepath "$home" "$@"
    '';
  };
in
{
  options.games.enemyTerritory.enable = lib.mkOption {
    type = lib.types.bool;
    default = (builtins.getEnv "LIGHT") == "";
    description = ''
      Whether to register Wolfenstein: Enemy Territory (ET:Legacy) as a Steam
      shortcut. The game itself is free; the assets ship in the nixpkgs package.
    '';
  };

  config = lib.mkIf config.games.enemyTerritory.enable {
    programs.steam.games.ENEMY_TERRITORY = {
      name = "Wolfenstein: Enemy Territory";
      inherit game;
      steamAppId = 1873030;
    };
  };
}
