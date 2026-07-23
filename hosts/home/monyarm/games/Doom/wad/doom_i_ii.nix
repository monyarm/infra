{
  config,
  pkgs,
  getFile,
  fetchSteam,
  mkDoom,
  wadFilter,
  ...
}:
let
  DOOM_I_II = fetchSteam {
    filelist = wadFilter;
    appId = 2280;
    depotId = 2281;
    manifestId = 557527948370603647;
    sha256 = "sha256-KIX9HRzQyQ6YawMVYGVk43z88bi55JUy3HNKNTMA2y4=";
  };

  # Corrected PC versions of the hidden Original-Xbox Doom/Doom II levels
  # (https://classicdoom.com/xboxspec.htm).
  xboxspec = pkgs.fetchzip {
    url = "https://classicdoom.com/xboxspec.zip";
    hash = "sha256-an/n2O1yEe/i0j3V/XbP9mXGFRYjXDenNjl1h3eI4gI=";
    stripRoot = false;
  };
in
{
  games.doom.wads = {
    doom = DOOM_I_II |> getFile "rerelease/doom.wad";
    doom2 = DOOM_I_II |> getFile "rerelease/doom2.wad";
    nerve = DOOM_I_II |> getFile "rerelease/nerve.wad";
    masterLevels = DOOM_I_II |> getFile "rerelease/masterlevels.wad";
    sigil = DOOM_I_II |> getFile "rerelease/sigil.wad";
    sigil2 = DOOM_I_II |> getFile "rerelease/sigil2.wad";
    plutonia = DOOM_I_II |> getFile "rerelease/plutonia.wad";
    id1 = DOOM_I_II |> getFile "rerelease/id1.wad";
    tnt = DOOM_I_II |> getFile "rerelease/tnt.wad";

    sewers = xboxspec |> getFile "SEWERS.WAD";
    betray = xboxspec |> getFile "BETRAY.WAD";
  };

  programs.steam.games = with config.games.doom.wads; {
    DOOM = mkDoom {
      name = "The Ultimate Doom";
      iwad = doom;
      wad = [ sewers ];
    };
    DOOM_2 = mkDoom {
      name = "Doom II: Hell on Earth";
      iwad = doom2;
      wad = [ betray ];
    };
    NERVE = mkDoom {
      name = "No Rest for the Living";
      iwad = doom2;
      wad = [ nerve ];
    };
    MASTER_LEVELS = mkDoom {
      name = "Master Levels for Doom II";
      iwad = doom2;
      wad = [ masterLevels ];
    };
    SIGIL_I = mkDoom {
      name = "Sigil";
      iwad = doom;
      wad = [ sigil ];
    };
    SIGIL_II = mkDoom {
      name = "Sigil 2";
      iwad = doom;
      wad = [ sigil2 ];
    };
    PLUTONIA = mkDoom {
      name = "The Plutonia Experiment";
      iwad = plutonia;
    };
    TNT = mkDoom {
      name = "TNT: Evilution";
      iwad = tnt;
    };
    ID1 = mkDoom {
      name = "Legacy of Rust";
      iwad = doom2;
      wad = [ id1 ];
    };
  };
}
