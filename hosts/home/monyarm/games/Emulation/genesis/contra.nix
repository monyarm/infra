{
  config,
  lib,
  pkgs,
  getFile,
  rename,
  mkRom,
  ...
}:
let
  inherit (config.games.emulation) marchive;
in
lib.mkIf config.games.emulation.enable {
  games.emulation.roms = {
    # Renamed .md so compressRom routes it to sevenzip-deflate (real zip) --
    # blastem only added zip-archive loading (0.6.2), not raw .7z.
    contraHardCorps =
      marchive.contra |> getFile "sega_ContraHardCorps.bin" |> rename "ContraHardCorps.md";

    # regional variants, registered for enumeration only -- not launchable
    contraTheHardCoreJp =
      marchive.contra |> getFile "sega_ContraTheHardCore.BIN" |> rename "ContraTheHardCore.md";
    probotectorGenesis = marchive.contra |> getFile "sega_Probotector.BIN" |> rename "Probotector.md";
    probotectorGenesisHackedWW =
      marchive.contra |> getFile "sega_Probotector_hacked_WW.BIN" |> rename "Probotector_hacked_WW.md";
  };

  programs.steam.games = with config.games.emulation.roms; {
    CONTRA_HARD_CORPS = mkRom {
      name = "Contra: Hard Corps";
      rom = contraHardCorps;
      system = "genesis";
      images = {
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/6d8baf465e25dcb5f546646ee3f9c000.png";
          sha256 = "sha256-ISpoj1igjNs/+l2dA55bxruxT9gZjVsKQWPAIpskKXA=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/21a0cf0088e7e13ca2a8ee316ed1ed2e.png";
          sha256 = "sha256-J/FhZH6qg528H3hlDl24z3D9lzni/X4Vjw5fzBXncTM=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/d0a0890b4ed35d097396473c7c84da92.png";
          sha256 = "sha256-R1qyRFRN+h7Qyr+h8YVn4GspZyW1k+zR1+sBRG4E+ds=";
        };
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/d26f85f8391a4966706b6748c816979f.ico";
          sha256 = "sha256-KQqxL6BeAAoUG3TQlNXjzsRF8JnJG+rO7ng8ljiftio=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/919635985f213275b60878669bba0be0.png";
          sha256 = "sha256-o8q5Tn1jTOqK1GdcyesbT1SVzn5HRh43rZ1bWwwLlsk=";
        };
      };
    };
  };
}
