{
  config,
  getFile,
  fetchModDB,
  mkDoom,
  ...
}:
let
  # Each of these is fetched once and getFile'd twice/thrice, so it's worth
  # naming; everything else below is single-use and goes straight into
  # games.doom.wads.
  metroidDreadnought = fetchModDB {
    id = 182831;
    sha256 = "sha256-GQw2km8e/9Tu62yv3dcbCFBaN9Lke7rgh9LumCpl+6w=";
  };

  spramsMetroidDoom = fetchModDB {
    id = 170103;
    sha256 = "sha256-Yemf9yw68u4xkckaPHQ8DfKpk8/BSpA8FREJfmtgzfU=";
  };
in
{
  games.doom.wads = {
    jazzJackrabbitDoom =
      fetchModDB {
        id = 287573;
        sha256 = "sha256-Sg2hsHw4Zujz+j3YGOTnn7B1kwShvZ+3Rs/1YlSrj+8=";
      }
      |> getFile "UJJD.pk3";

    zombiesAteMyNeighboursTC =
      fetchModDB {
        id = 307303;
        sha256 = "sha256-NRzyhY9ppOZHbXd4KMwCjXGK0bXnchDaPaArGzr88kw=";
      }
      |> getFile "Zombies Ate My Neighbors TC/ZAMN_MAIN.ipk3";

    # The base wad lives in gdrive.nix; this is just the moddb addon
    # (avoiding the sibling LoDMusicLoops.pk3).
    legendOfDoomAddon =
      fetchModDB {
        id = 243444;
        sha256 = "sha256-SVQSE4fJDA1itXrwJ0rp+tGzSbdqOtph32h6gXcU/ow=";
      }
      |> getFile "fdssounds.pk3";

    metroidDreadnoughtMain = metroidDreadnought |> getFile "MDO 1.5c 8-8-19.pk3";
    metroidDreadnoughtLevels = metroidDreadnought |> getFile "MetroidDreadnought-levels-v1.1.pk3";

    spramsMetroidDoomWad = spramsMetroidDoom |> getFile "Met.wad";
    spramsMetroidDoomMaps = spramsMetroidDoom |> getFile "Met_maps_fancy.wad";
    spramsMetroidDoomDeh = spramsMetroidDoom |> getFile "metroid.deh";

    hocusPocusDoom =
      fetchModDB {
        id = 189681;
        sha256 = "sha256-r7hs1EAcyoNknHq0NLEdofZZJYbtGEXBdrenVG5jJVI=";
      }
      |> getFile "HOCUS.pk3";
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
