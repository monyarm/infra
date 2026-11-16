{
  pkgs,
  lib,
  config,
  fetchSteam,
  ...
}:
let
  data = fetchSteam {
    appId = 9010;
    depotId = 9011;
    manifestId = 3427162182448439563;
    os = "windows";
    filelist = [
      "Main/pak0.pk3"
      "Main/sp_pak1.pk3"
      "Main/sp_pak2.pk3"
      "Main/sp_pak3.pk3"
      "Main/sp_pak4.pk3"
    ];
    sha256 = "sha256-9AzsYeoyvov76/A4rD6QHCfrcWPC5n0s6uYX8DMes14=";
  };

  # RealRTCW's own data (loose files) plus the retail paks it needs.
  base = pkgs.runCommand "realrtcw-base" { } ''
    mkdir -p "$out/main"
    cp -rs ${pkgs.realrtcw}/lib/realrtcw/main/. "$out/main/"
    for pak in pak0 sp_pak1 sp_pak2 sp_pak3 sp_pak4; do
      ln -s ${data}/Main/"$pak".pk3 "$out/main/$pak.pk3"
    done
  '';

  game = pkgs.writeShellApplication {
    name = "realrtcw";
    text = ''
      home="''${XDG_DATA_HOME:-$HOME/.local/share}/realrtcw"
      mkdir -p "$home/main"

      exec ${pkgs.realrtcw}/lib/realrtcw/RealRTCW.x86_64 \
        +set fs_basepath ${base} \
        +set fs_homepath "$home" \
        "$@"
    '';
  };
in
{
  options.games.rtcw.enable = lib.mkOption {
    type = lib.types.bool;
    default = (builtins.getEnv "LIGHT") == "";
    description = "Whether to fetch the Return to Castle Wolfenstein data for RealRTCW.";
  };

  config = lib.mkIf config.games.rtcw.enable {
    programs.steam.games.RETURN_TO_CASTLE_WOLFENSTEIN = {
      name = "Return to Castle Wolfenstein";
      inherit game;
      steamAppId = 9010;
    };
  };
}
