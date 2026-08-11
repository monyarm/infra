{
  config,
  lib,
  getFile,
  fetchMediafire,
  mkDoom,
  sources,
  ...
}:
lib.mkIf config.games.doom.enable {
  games.doom.wads = {
    seriousSamRetroEncounter = fetchMediafire sources.wad.seriousSamRetroEncounter;

    splatterhouse3D = fetchMediafire sources.wad.splatterhouse3D |> getFile "splat3dmus.pk3";
  };

  programs.steam.games = with config.games.doom.wads; {
    SeriousSamRetroEncounter = mkDoom {
      name = "Serious Sam: The Retro Encounter";
      iwad = doom2;
      wad = [ seriousSamRetroEncounter ];
    };
    Splatterhouse3D = mkDoom {
      name = "Splatterhouse 3D";
      iwad = doom2;
      wad = [ splatterhouse3D ];
    };
  };
}
