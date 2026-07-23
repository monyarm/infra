{
  config,
  getFile,
  fetchIdGames,
  mkDoom,
  sources,
  ...
}:
{
  games.doom.wads = {
    paranoid = fetchIdGames sources.wad.paranoid |> getFile "Paranoid.pk3";
    paranoiac = fetchIdGames sources.wad.paranoic |> getFile "paranoic.pk3";
    aoddoom = fetchIdGames sources.wad.aoddoom |> getFile "aoddoom2.wad";
    aoddoomDeh = fetchIdGames sources.wad.aoddoom |> getFile "aoddoom2.deh";

    actionDoom2 = fetchIdGames sources.wad.actiondoom2 |> getFile "action2.wad";
    pirateDoom = fetchIdGames sources.wad.piratedoom |> getFile "Pirates!.wad";
    batmanWad = fetchIdGames sources.wad.batmandoom |> getFile "batman.wad";
    batmanDeh = fetchIdGames sources.wad.batmandoom |> getFile "batman.deh";
    inquisitor = fetchIdGames sources.wad.inquisitor |> getFile "inqstr.wad";
    inquisitor2 = fetchIdGames sources.wad.inquisitor2 |> getFile "inqstr2e.wad";
    inquisitor3Res = fetchIdGames sources.wad.inquisitor3 |> getFile "inq3resE.pk3";
    inquisitor3Wad = fetchIdGames sources.wad.inquisitor3 |> getFile "inqstr3e.wad";
  };

  programs.steam.games = with config.games.doom.wads; {
    paranoid = mkDoom {
      name = "Paranoid (Half-Life)";
      iwad = paranoid;
    };
    Paranoiac = mkDoom {
      name = "Paranoiac";
      iwad = paranoid;
      wad = [ paranoiac ];
    };
    aoddoom = mkDoom {
      name = "Army of Darkness Doom";
      iwad = aoddoom;
      wad = [ aoddoomDeh ];
    };

    ActionDoom2 = mkDoom {
      name = "Action Doom 2: Urban Brawl";
      iwad = actionDoom2;
    };
    PirateDoom = mkDoom {
      name = "Pirate Doom";
      iwad = doom2;
      wad = [ pirateDoom ];
    };
    BatmanDoom = mkDoom {
      name = "Batman Doom";
      iwad = doom2;
      wad = [
        batmanWad
        batmanDeh
      ];
    };
    Inquisitor = mkDoom {
      name = "The Inquisitor";
      iwad = doom2;
      wad = [ inquisitor ];
    };
    Inquisitor2 = mkDoom {
      name = "The Inquisitor 2";
      iwad = doom2;
      wad = [ inquisitor2 ];
    };
    Inquisitor3 = mkDoom {
      name = "The Inquisitor 3";
      iwad = doom2;
      wad = [
        inquisitor3Res
        inquisitor3Wad
      ];
    };
  };
}
