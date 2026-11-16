{
  config,
  lib,
  pkgs,
  fetchSteam,
  mkTrx,
  ...
}:
let
  # 2020 GOG DOSBox repack: all game data sits in a 2352-byte-sector ISO.
  depot = fetchSteam {
    appId = 224960;
    depotId = 224961;
    manifestId = 1018039351833983427;
    os = "windows";
    filelist = [
      "GAME.GOG"
      "regex:^0[2-9]\.mp3$"
      "regex:^10\.mp3$"
    ];
    sha256 = "sha256-hqLW84VDWn+9HsNCEtGsiW1cgs9n3uhB3xblU7np1oI=";
  };
in
lib.mkIf config.games.trx.enable {
  games.trx.data.tr1 =
    pkgs.runCommand "trx-tr1-data"
      {
        nativeBuildInputs = [
          pkgs.p7zip
          pkgs.python3
        ];
      }
      ''
        cp -r ${pkgs.tombraider-trx}/share/trx/games/tr1 $out
        chmod -R u+w $out
        mkdir -p $out/levels $out/fmv $out/music

        python3 - ${depot}/GAME.GOG game.iso <<'EOF'
        import sys
        with open(sys.argv[1], "rb") as src, open(sys.argv[2], "wb") as dst:
            while True:
                sector = src.read(2352)
                if not sector:
                    break
                dst.write(sector[16:2064])
        EOF

        7z x -y game.iso -oiso >/dev/null

        for f in iso/DATA/*.[Pp][Hh][Dd]; do
          b=$(basename "$f")
          cp "$f" "$out/levels/$(printf '%s' "$b" | sed 's/\.[^.]*$//' | tr '[:upper:]' '[:lower:]').phd"
        done
        for f in iso/FMV/*.[Rr][Pp][Ll]; do
          b=$(basename "$f")
          cp "$f" "$out/fmv/$(printf '%s' "$b" | sed 's/\.[^.]*$//' | tr '[:upper:]' '[:lower:]').rpl"
        done
        for f in ${depot}/0[2-9].mp3 ${depot}/10.mp3; do
          cp "$f" "$out/music/track$(basename "$f" .mp3).mp3"
        done

        test -e $out/levels/level1.phd
        test -e $out/fmv/core.rpl
        test -e $out/music/track10.mp3
      '';

  programs.steam.games.TOMB_RAIDER_1 = mkTrx {
    name = "Tomb Raider";
    id = "tr1";
    steamAppId = 224960;
  };
}
