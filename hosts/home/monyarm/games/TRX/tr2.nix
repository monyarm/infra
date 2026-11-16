{
  config,
  lib,
  pkgs,
  fetchSteam,
  mkTrx,
  ...
}:
let
  depot = fetchSteam {
    appId = 225300;
    depotId = 225301;
    manifestId = 1701443328413221856;
    os = "windows";
    filelist = [
      "data/MAIN.SFX"
      "regex:(?i)^data/[^/]+\.tr2$"
      "regex:(?i)^fmv/[^/]+\.rpl$"
      "regex:^music/[0-9]+\.mp3$"
    ];
    sha256 = "sha256-P5mGO+vd33NmcwKvvaEaj37k3iZGzym7zdzNtS6bF2M=";
  };
in
lib.mkIf config.games.trx.enable {
  games.trx.data.tr2 = pkgs.runCommand "trx-tr2-data" { } ''
    cp -r ${pkgs.tombraider-trx}/share/trx/games/tr2 $out
    chmod -R u+w $out
    mkdir -p $out/levels $out/fmv $out/music

    cp ${depot}/data/MAIN.SFX $out/main.sfx
    for f in ${depot}/data/*.[Tt][Rr]2; do
      b=$(basename "$f")
      cp "$f" "$out/levels/$(printf '%s' "$b" | sed 's/\.[^.]*$//' | tr '[:upper:]' '[:lower:]').tr2"
    done
    for f in ${depot}/fmv/*.[Rr][Pp][Ll]; do
      b=$(basename "$f")
      cp "$f" "$out/fmv/$(printf '%s' "$b" | sed 's/\.[^.]*$//' | tr '[:upper:]' '[:lower:]').rpl"
    done
    cp ${depot}/music/*.mp3 $out/music/

    test -e $out/levels/assault.tr2
    test -e $out/main.sfx
  '';

  programs.steam.games.TOMB_RAIDER_2 = mkTrx {
    name = "Tomb Raider II";
    id = "tr2";
    steamAppId = 225300;
  };
}
