{
  config,
  lib,
  getFile,
  optimizePk3,
  fetchItch,
  mkDoom,
  findWad,
  sources,
  ...
}:
lib.mkIf config.games.doom.enable {
  games.doom.wads = {
    simonsdestiny =
      fetchItch sources.wad.simonsdestiny
      |> getFile "Castlevania.ipk3"
      |> optimizePk3;
    goldenSoulsRemastered =
      fetchItch sources.wad.goldensouls
      |> getFile (findWad sources.wad.goldensouls.files)
      |> optimizePk3;
    goldenSouls2 =
      fetchItch sources.wad.goldensouls2
      |> getFile (findWad sources.wad.goldensouls2.files)
      |> optimizePk3;
    goldenSouls3 =
      fetchItch sources.wad.goldensouls3
      |> getFile (findWad sources.wad.goldensouls3.files)
      |> optimizePk3;
    gzpt = fetchItch sources.wad.gzpt |> getFile "GZPT.ipk3" |> optimizePk3;
  };

  programs.steam.games = with config.games.doom.wads; {
    simonsdestiny = mkDoom {
      name = "Castlevania: Simon's Destiny";
      iwad = simonsdestiny;
    };
    GoldenSoulsRemastered = mkDoom {
      name = "Doom: The Golden Souls Remastered";
      iwad = doom2;
      wad = [ goldenSoulsRemastered ];
    };
    GoldenSouls2 = mkDoom {
      name = "Doom: The Golden Souls 2";
      iwad = doom2;
      wad = [ goldenSouls2 ];
    };
    GoldenSouls3 = mkDoom {
      name = "Doom: The Golden Souls 3";
      iwad = doom2;
      wad = [ goldenSouls3 ];
    };
    GzPt = mkDoom {
      name = "GZ PT";
      iwad = gzpt;
    };
  };
}
