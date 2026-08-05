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
    simpsons3Doom =
      fetchItch sources.wad.simpsons3doom |> getFile "Simpsons3Ddoomrecreation.pk3" |> optimizePk3;
    venturous =
      fetchItch sources.wad.venturous |> getFile (findWad sources.wad.venturous.files) |> optimizePk3;
    square = fetchItch sources.wad.square |> getFile "square1.pk3" |> optimizePk3;
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
