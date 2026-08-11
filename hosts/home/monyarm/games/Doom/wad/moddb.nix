{
  config,
  lib,
  getFile,
  fetchModDB,
  mkDoom,
  sources,
  ...
}:
let
  # Each of these is fetched once and getFile'd twice/thrice, so it's worth
  # naming; everything else below is single-use and goes straight into
  # games.doom.wads.
  metroidDreadnought = fetchModDB sources.wad.metroidDreadnought;
  spramsMetroidDoom = fetchModDB sources.wad.spramsMetroidDoom;
in
lib.mkIf config.games.doom.enable {
  games.doom.wads = {
    jazzJackrabbitDoom = fetchModDB sources.wad.jazzJackrabbitDoom |> getFile "UJJD.pk3";

    zombiesAteMyNeighboursTC =
      fetchModDB sources.wad.zombiesAteMyNeighboursTC
      |> getFile "Zombies Ate My Neighbors TC/ZAMN_MAIN.ipk3";

    # The base wad lives in gdrive.nix; this is just the moddb addon
    # (avoiding the sibling LoDMusicLoops.pk3).
    legendOfDoomAddon = fetchModDB sources.wad.legendOfDoomAddon |> getFile "fdssounds.pk3";

    metroidDreadnoughtMain = metroidDreadnought |> getFile "MDO 1.5c 8-8-19.pk3";
    metroidDreadnoughtLevels = metroidDreadnought |> getFile "MetroidDreadnought-levels-v1.1.pk3";

    spramsMetroidDoomWad = spramsMetroidDoom |> getFile "Met.wad";
    spramsMetroidDoomMaps = spramsMetroidDoom |> getFile "Met_maps_fancy.wad";
    spramsMetroidDoomDeh = spramsMetroidDoom |> getFile "metroid.deh";

    hocusPocusDoom = fetchModDB sources.wad.hocusPocusDoom |> getFile "HOCUS.pk3";
  };

  programs.steam.games = with config.games.doom.wads; {
    JazzJackrabbitDoom = mkDoom {
      name = "Ultimate Jazz Jackrabbit Doom";
      iwad = doom2;
      wad = [ jazzJackrabbitDoom ];
    };
    ZombiesAteMyNeighboursTC = mkDoom {
      name = "Zombies Ate My Neighbours TC";
      iwad = zombiesAteMyNeighboursTC;
    };
    MetroidDreadnought = mkDoom {
      name = "Metroid: Dreadnought";
      iwad = doom2;
      wad = [
        metroidDreadnoughtMain
        metroidDreadnoughtLevels
      ];
    };
    SpramsMetroidDoom = mkDoom {
      name = "Spram's Metroid Doom";
      iwad = doom2;
      wad = [
        spramsMetroidDoomWad
        spramsMetroidDoomMaps
        spramsMetroidDoomDeh
      ];
    };
    HocusPocusDoom = mkDoom {
      name = "Hocus Pocus Doom";
      iwad = doom2;
      wad = [ hocusPocusDoom ];
    };
  };
}
