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
    simpsons3Doom = fetchItch sources.wad.simpsons3doom |> getFile "Simpsons3Ddoomrecreation.pk3";
    venturous = fetchItch sources.wad.venturous |> getFile (findWad sources.wad.venturous.files);
    square = fetchItch sources.wad.square |> getFile "square1.pk3";
    bikiniBottomMassacre =
      fetchItch sources.wad.bikinibottommassacre |> getFile "bikini bottom massacre.wad";
  };

  programs.steam.games = with config.games.doom.wads; {
    Simpsons3Doom = mkDoom {
      name = "The Simpsons: Bart Saves Springfield";
      iwad = doom2;
      wad = [ simpsons3Doom ];
    };
    Venturous = mkDoom {
      name = "Venturous";
      iwad = doom2;
      wad = [ venturous ];
    };
    AdventuresOfSquare = mkDoom {
      name = "The Adventures of Square";
      iwad = square;
    };
    BikiniBottomMassacre = mkDoom {
      name = "The Bikini Bottom Massacre";
      iwad = doom2;
      wad = [ bikiniBottomMassacre ];
    };
  };
}
