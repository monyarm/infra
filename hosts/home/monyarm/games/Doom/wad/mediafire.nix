{
  config,
  lib,
  pkgs,
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
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/735cc7d6936e460a1bcbe1011d099bb4.png";
        sha256 = "sha256-29A/aC44OwEf51DsQHZ0PKMMaTSC+o6R76osi3z7HTU=";
      };
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/958f8ab8809421443d162f7a6df527c8.ico";
        sha256 = "sha256-jZOclMr9XcmZm89Zkop05bN+4P39g0wGWdGs1kNQ34o=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/37b8f935b8a23fdeb2e43a415f9ec193.png";
        sha256 = "sha256-2+B2pQiaOB1CHTl+u/jp2DR7EltLGSnWEFoNO0a9wWo=";
      };
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/2ba9f102905f4102fe5751c7cbe28b9b.png";
        sha256 = "sha256-Jf3HbCWBMMPf4yWpJxhpWBH7QbVM8ECqoV45FstGDPs=";
      };
    };
    Splatterhouse3D = mkDoom {
      name = "Splatterhouse 3D";
      iwad = doom2;
      wad = [ splatterhouse3D ];
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/dbd2d35db50e19a61947777701e813b3.png";
        sha256 = "sha256-JLKBEBftVEG7tzgO0t0Xe4I7qySyV/KZQxjjlAw0zmI=";
      };
    };
  };
}
