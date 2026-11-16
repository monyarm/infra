{
  pkgs,
  lib,
  config,
  fetchSteam,
  ...
}:
let
  data = fetchSteam {
    appId = 7760;
    depotId = 7761;
    manifestId = 9064227437018934890;
    os = "windows";
    filelist = [
      "regex:^XCOM/(GEODATA|GEOGRAPH|MAPS|MISSDAT|ROUTES|SOUND|TERRAIN|UFOGRAPH|UNITS|VAR)/.*$"
    ];
    sha256 = "sha256-HsTyiY3MhRTkFwv5spHnQsugckjQ1t9WXniA/Gc/T1A=";
  };

  # -data must be a root holding common/ (engine data) and UFO/ (game data) as
  # siblings. mods/ and standard/ stay absent because no mods are used.
  game =
    let
      tree = pkgs.runCommand "openxcom-data" { } ''
        mkdir -p "$out"
        ln -s ${pkgs.openxcom-extended}/share/openxcom/common "$out/common"
        ln -s ${data}/XCOM "$out/UFO"
      '';
    in
    pkgs.writeShellApplication {
      name = "openxcom";
      text = ''
        exec ${pkgs.openxcom-extended}/bin/openxcom -data "${tree}" "$@"
      '';
    };
in
{
  options.games.openxcom.enable = lib.mkOption {
    type = lib.types.bool;
    default = (builtins.getEnv "LIGHT") == "";
    description = ''
      Whether to fetch and register the X-COM UFO Defense data.
    '';
  };

  config = lib.mkIf config.games.openxcom.enable {
    programs.steam.games.XCOM_UFO_DEFENSE = {
      name = "X-COM: UFO Defense";
      inherit game;
      steamAppId = 7760;
    };
  };
}
