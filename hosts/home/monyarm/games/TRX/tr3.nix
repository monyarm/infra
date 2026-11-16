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
    appId = 225320;
    depotId = 225321;
    manifestId = 5659119167172291423;
    os = "windows";
    filelist = [
      "data/MAIN.SFX"
      "audio/cdaudio.wad"
      "regex:(?i)^data/[^/]+\.tr2$"
      "regex:(?i)^cuts/[^/]+\.tr2$"
      "regex:(?i)^fmv/[^/]+\.rpl$"
    ];
    sha256 = "sha256-xY5i9SCD4n30kIofTqOg5o3XOQA0i3kqcyuaRIo28NM=";
  };
in
lib.mkIf config.games.trx.enable {
  games.trx.data.tr3 = pkgs.runCommand "trx-tr3-data" { } ''
    cp -r ${pkgs.tombraider-trx}/share/trx/games/tr3 $out
    chmod -R u+w $out
    mkdir -p $out/levels $out/fmv $out/cuts $out/audio

    cp ${depot}/data/MAIN.SFX $out/main.sfx
    cp ${depot}/audio/cdaudio.wad $out/audio/cdaudio.wad
    for f in ${depot}/data/*.[Tt][Rr]2; do
      b=$(basename "$f")
      cp "$f" "$out/levels/$(printf '%s' "$b" | sed 's/\.[^.]*$//' | tr '[:upper:]' '[:lower:]').tr2"
    done
    for f in ${depot}/cuts/*.[Tt][Rr]2; do
      b=$(basename "$f")
      cp "$f" "$out/cuts/$(printf '%s' "$b" | sed 's/\.[^.]*$//' | tr '[:upper:]' '[:lower:]').tr2"
    done
    for f in ${depot}/fmv/*.[Rr][Pp][Ll]; do
      b=$(basename "$f")
      cp "$f" "$out/fmv/$(printf '%s' "$b" | sed 's/\.[^.]*$//' | tr '[:upper:]' '[:lower:]').rpl"
    done

    test -e $out/levels/antarc.tr2
    test -e $out/audio/cdaudio.wad
  '';

  programs.steam.games.TOMB_RAIDER_3 = mkTrx {
    name = "Tomb Raider III: Adventures of Lara Croft";
    id = "tr3";
    steamAppId = 225320;
  };
}
