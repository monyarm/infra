{
  config,
  getFile,
  fetchMediafire,
  mkDoom,
  ...
}:
{
  games.doom.wads = {
    seriousSamRetroEncounter = fetchMediafire {
      url = "http://www.mediafire.com/file/3tgp183p48vb06z/SS_RETRO_ENCOUNTER_2018_hotfix.pk3";
      sha256 = "sha256-YzWT8uB616HIUik1GvXjg29c0GU4biKalM/rPY3YhDM=";
    };

    splatterhouse3D =
      fetchMediafire {
        url = "http://www.mediafire.com/file/zr6zklcj337p1q5/splat3dmus.zip/file";
        extract = true;
        sha256 = "sha256-7ML/Ws+O/sbPGcHXYEpy1GYNXFYuH/lgy8Pex7l4LAE=";
      }
      |> getFile "splat3dmus.pk3";
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
