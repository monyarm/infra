{
  config,
  pkgs,
  lib,
  fetchModDB,
  splitFiles,
  getFile,
  fetchSteam,
  wadFilter,
  mkDoom,
  patchFile,
  ...
}:
let

  Doom64 =
    fetchSteam {
      appId = 1148590;
      depotId = 1148591;
      manifestId = 1585039031650632684;
      filelist = wadFilter;
      sha256 = "sha256-58/x6rIDE+GX17QN22I7l5P6XdB9aLy5dNUl5n+jxC8=";
    }
    |> getFile "DOOM64.WAD";
  Doom64CE = fetchModDB {
    id = 285205;
    sha256 = "sha256-D8hf6WQ3+CLAFIDqPu/uPgww1EfnZ2U0ZFXL7OoCkb0=";
  };
  Doom64CEWads =
    Doom64CE
    |> splitFiles [
      "DOOM64.CE.ipk3"
      "DOOM64.CE.Addon.BGM.Extended.pk3"
      "DOOM64.CE.Addon.GFX.Brightmaps.pk3"
      "DOOM64.CE.Addon.GFX.Decals.pk3"
      "DOOM64.CE.Addon.GFX.Extra.pk3"
      "DOOM64.CE.Addon.GFX.Parallax.pk3"
      "DOOM64.CE.Addon.GFX.PBR.pk3"
      "DOOM64.CE.Addon.SFX.HQ.pk3"
    ];

  wadExtractMap =
    wad: entryName:
    pkgs.runCommand "wad-map-${lib.toLower entryName}" { nativeBuildInputs = [ pkgs.python3 ]; } ''
      python3 ${../wadextract.py} M "${wad}" "${entryName}" "$out"
    '';

  lostLevels = lib.imap1 (
    c: mapNum:
    let
      numStr = lib.fixedWidthString 2 "0" (toString c);
      mapOut = wadExtractMap Doom64 "MAP${toString mapNum}";
    in
    {
      num = numStr;
      mapWad = patchFile (getFile "patcher/LOST${numStr}.bps" Doom64CE) (getFile "_MAP.WAD" mapOut);
      sLump = getFile "SECTORS" mapOut;
      iLump = getFile "LINEDEFS" mapOut;
      lLump = getFile "LIGHTS" mapOut;
    }
  ) (lib.range 34 40);

  doom64LostLevelsPk3 =
    pkgs.runCommand "DOOM64.CE.Maps.LostLevels.pk3" { nativeBuildInputs = [ pkgs.zip ]; }
      ''
        mkdir -p ce/MAPS ce/FILTER/game-doom

        ${lib.concatMapStringsSep "\n" (lvl: ''
          cp ${lvl.mapWad} ce/MAPS/LOST${lvl.num}.WAD
          cp ${lvl.sLump}  ce/FILTER/game-doom/S_LOST${lvl.num}
          cp ${lvl.iLump}  ce/FILTER/game-doom/I_LOST${lvl.num}
          cp ${lvl.lLump}  ce/FILTER/game-doom/L_LOST${lvl.num}
        '') lostLevels}

        # cp $\{getFile "patcher/LOST00.wad" Doom64CE} ce/MAPS/LOST00.wad

        (cd ce && zip -r ../DOOM64.CE.Maps.LostLevels.pk3 .)
        cp DOOM64.CE.Maps.LostLevels.pk3 "$out"
      '';
in
{
  games.doom.wads.doom64 = Doom64;

  programs.steam.games = with config.games.doom.wads; {
    Doom64 = mkDoom {
      name = "Doom64";
      iwad = doom64;
      wad = Doom64CEWads ++ [ doom64LostLevelsPk3 ];
    };
  };
}
