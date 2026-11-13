{
  config,
  lib,
  pkgs,
  ripDiscContents,
  getFiles,
  ...
}:
let
  # DIABDAT.MPQ is the only file DevilutionX needs from the retail CD.
  diabloData =
    ripDiscContents {
      name = "Diablo";
      sha256 = "sha256-L8HvM8SyJY8ZFCHZhbnrUW5Hs0WE9P7i0uI16u1StTs=";
    }
    |> getFiles [ "DIABDAT.MPQ" ];
in
{
  options.games.devilutionx.enable = lib.mkOption {
    type = lib.types.bool;
    default = (builtins.getEnv "LIGHT") == "";
    description = ''
      Whether to rip and register Diablo (DevilutionX).
    '';
  };

  config = lib.mkIf config.games.devilutionx.enable {
    # --data-dir keeps saves/diablo.ini in the writable default prefpath.
    programs.steam.games.DIABLO = {
      name = "Diablo";
      game = pkgs.devilutionx;
      args = [
        "--data-dir"
        "${diabloData}"
      ];
    };
  };
}
