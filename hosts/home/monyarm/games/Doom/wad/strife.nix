{
  config,
  lib,
  getFile,
  fetchSteam,
  mkDoom,
  optimize,
  ...
}:
let
  STRIFE = fetchSteam {
    appId = 317040;
    depotId = 317041;
    manifestId = 8796736291286375028;
    filelist = [
      "strife1.wad"
      "SVE.wad"
      "DOS/C/STRIFE/voices.wad"
    ];
    sha256 = "sha256-FfBu652QTObIaI1w3YsQGZDwwSsTsT7oBeksDyuFIMc=";
  };

  # IWADSearch Path in Doom/conf.nix
  wadDir = "${config.xdg.configHome}/uzdoom/strife";
in
lib.mkIf config.games.doom.enable {
  games.doom.wads = {
    strife1 = STRIFE |> getFile "strife1.wad";
    strifeVeteran = STRIFE |> getFile "SVE.wad";
    strifeVoices = STRIFE |> getFile "DOS/C/STRIFE/voices.wad";
  };

  # SVE iwadinfo: `Required` strife1 only found by scanning IWADSearch dirs (not -file);
  # `Load` voices.wad looked up beside the iwad, else case-insensitive scan of its dir
  # (whole /nix/store for a bare store file). Iwad match is by lumps, so optimized copies fine.
  xdg.configFile = with config.games.doom.wads; {
    "uzdoom/strife/strife1.wad".source = optimize strife1;
    "uzdoom/strife/SVE.wad".source = optimize strifeVeteran;
    "uzdoom/strife/voices.wad".source = optimize strifeVoices;
  };

  programs.steam.games = with config.games.doom.wads; {
    STRIFE =
      mkDoom {
        name = "The Original Strife: Veteran Edition";
        iwad = strifeVeteran;
        steamAppId = 317040;
        steamCdnImagesHash = "sha256-QcuCs08JVYKQ/2LDPezEDPS+jaJ+ddTyObYmXADFx/Y=";
      }
      // {
        game = "${wadDir}/SVE.wad";
      };
  };
}
