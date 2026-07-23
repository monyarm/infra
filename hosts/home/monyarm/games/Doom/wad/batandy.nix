{
  config,
  getFile,
  fetchItch,
  mkDoom,
  findWad,
  sources,
  ...
}:
{
  games.doom.wads = {
    simonsdestiny = fetchItch sources.wad.simonsdestiny |> getFile "Castlevania.ipk3";
    goldenSoulsRemastered = fetchItch sources.wad.goldensouls |> getFile (findWad sources.wad.goldensouls.files);
    goldenSouls2 = fetchItch sources.wad.goldensouls2 |> getFile (findWad sources.wad.goldensouls2.files);
    goldenSouls3 = fetchItch sources.wad.goldensouls3 |> getFile (findWad sources.wad.goldensouls3.files);
    gzpt = fetchItch sources.wad.gzpt |> getFile "GZPT.ipk3";
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
