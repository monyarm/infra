{
  config,
  lib,
  pkgs,
  getFile,
  mkRom,
  ...
}:
let
  inherit (config.games.emulation) marchive;
in
lib.mkIf config.games.emulation.enable {
  games.emulation.roms = {
    # Contra Anniversary Collection's dumps have had Nintendo/Sega
    # copyright/branding screens stripped for legal reasons (contrapedia.wordpress.com);
    # unclear how that affects offset-based rom-hack IPS/BPS/UPS patches.
    contraIII = marchive.contra |> getFile "snes_ContraIII.smc";

    # regional variants, registered for enumeration only -- not launchable
    superProbotector = marchive.contra |> getFile "snes_SuperProbotector.smc";
    contraSpiritsSufami = marchive.contra |> getFile "sufami_ContraSpirits.smc";
  };

  programs.steam.games = with config.games.emulation.roms; {
    CONTRA_III = mkRom {
      name = "Contra III: The Alien Wars";
      rom = contraIII;
      system = "snes";
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/2931063739d4a2ea969474ff753bf05e.png";
        sha256 = "sha256-MXAfQm0Mk8GM+Vn0q1ZUMvULEt6ny+O+pCpuYnL7ERs=";
      };
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/5300ef422e613b74fbf759d293aaab6a.png";
        sha256 = "sha256-5reG4xIlKB92XVYbckWoDV2neaHjmSIeqoHcliHiNbA=";
      };
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/4f6537663f76d2db65952c06da97a02d.png";
        sha256 = "sha256-X4Vsrhkm4f8TyEiC6tb6qRQPcqscyd1BjAOWWIdQaPs=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/8ae1da0fe37c98412768453f82490da2.png";
        sha256 = "sha256-3rRcXXbwJ2K1oMvtpN7qyamM+WlbP17Ayag8FnCi3p4=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/23edd566480c510a2d22eb3f2fb04a62.png";
        sha256 = "sha256-vTk0FKAJAebzj+0GZZuyie0bu5Gvg5WJMI/9JpGzRnk=";
      };
    };
  };
}
