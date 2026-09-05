{
  config,
  lib,
  pkgs,
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
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/5a81b9faa9143f401c9be9dd209bf750.ico";
          sha256 = "sha256-EqAEFxETO5K8U+/jt1aXBd5yHZhuZQ66njABi/7TWuw=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/061b7b3d5e2ee31c7875058883fbcce8.png";
          sha256 = "sha256-UflCKKZ2HaQsAfHaFJ1tvF/0PtmSVjKLJSvT5DESfEA=";
        };
      };
    };
    ZombiesAteMyNeighboursTC = mkDoom {
      name = "Zombies Ate My Neighbours TC";
      iwad = zombiesAteMyNeighboursTC;
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/3d3621cee6f49e93a34f3f0f654ab41a.png";
          sha256 = "sha256-pFTpMNpXX2yFoCqUj9JJGHzJUFdb6tFpLX7p4Nhjlig=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/6b3829244a3cb6ef04f4f11733faa5a2.jpg";
          sha256 = "sha256-mmDPGssLf55tGBmFUATxe3izACiln4tULshvrUOt6SI=";
        };
      };
    };
    MetroidDreadnought = mkDoom {
      name = "Metroid: Dreadnought";
      iwad = doom2;
      wad = [
        metroidDreadnoughtMain
        metroidDreadnoughtLevels
      ];
      images = {
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/67a83eab0da5d5e1357e82cee4ea9907.png";
          sha256 = "sha256-+2ycjIWUJp4VDKkEWB+9DZ7BD7xvaZ/v6mIAHJr1lj0=";
        };
      };
    };
    SpramsMetroidDoom = mkDoom {
      name = "Spram's Metroid Doom";
      iwad = doom2;
      wad = [
        spramsMetroidDoomWad
        spramsMetroidDoomMaps
        spramsMetroidDoomDeh
      ];
      images = {
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/4a7f1cb467dcc9ddea3e09294fde31d8.png";
          sha256 = "sha256-I/rkJORKCeyCciPTpSTBMtymUtaYwuoe7YIYzcmBU9o=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/5e6fdb08bbe39d99e74cd6353f648d37.png";
          sha256 = "sha256-mymMhmMhmlos8iYDAGuGvMHiGXfVejODu/BvwsSbdzU=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/8efa72aa981f8fe7381fe43376d3314e.png";
          sha256 = "sha256-GY2vJXatG+t/+AOnRXu7dSbaWFZHCfhZ6JFLCj9kwKI=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/710c8330cdf354bd19901cb6829ac26d.png";
          sha256 = "sha256-nKHBVrVhlbUiIpxMfYuXKr+ugaS42l50d6sNDUs9c4Y=";
        };
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/1be04b0d388175bc2c4bb9d7af786741.png";
          sha256 = "sha256-Wm8Og5LrP4oAMp6Gc23VLis1Vv/UR3MNGkSfd373WhY=";
        };
      };
    };
    HocusPocusDoom = mkDoom {
      name = "Hocus Pocus Doom";
      iwad = doom2;
      wad = [ hocusPocusDoom ];
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/978f30ebe0d9a24bd763ba6201b2f7ba.ico";
          sha256 = "sha256-iYKOpaKd1VVtiG4dUFlr2ArZ4aoYantdAGoHk40ShYk=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/c2ffdb3719c15fc9e072dc06f8fecc83.png";
          sha256 = "sha256-53CsJa1IHsq9c5EfwobL56F+5X7L3AaB4EHx1kFj2zo=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/21a23df33dceb8b7c865bee83322de29.png";
          sha256 = "sha256-rsvkiqxaa1Yf2jQO2nOH+HNtqsHXOqwMGcZWAXe40Tg=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/c57bad8e3a1b3eb8aacb14b47e79387c.png";
          sha256 = "sha256-eW0/VxR6CTtlQDMQTRQxm22J1tg4OgsHeVQiDPtcxPU=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/a11342bf87f0871946dc4c9f52637158.png";
          sha256 = "sha256-nKDNau/GqtB0qmZwdhjDSGwB9FvNw/ycs3yD0k+zyzA=";
        };
      };
    };
  };
}
