{
  pkgs,
  lib,
  getFile,
  fetchIdGames,
  fetchzipNoSubst,
  fetchItch,
  fetchSteam,
  sources,
  autoImport,
  ...
}:
let

  mkDoom =
    {
      iwad,
      wad ? [ ],
      ...
    }@args:
    (lib.removeAttrs args [
      "iwad"
      "wad"
    ])
    // {
      game = pkgs.uzdoom;
      args = [
        "-iwad"
        "${iwad}"
        "-file"
      ]
      ++ (lib.optionals (wad != null && wad != [ ]) (map (x: "${x}") wad))
      ++ [ "${wads.lights}" ];

    };

  wadFilter = [ "regex:(.*\.(wad|WAD))" ];

  DOOM_I_II = fetchSteam {
    filelist = wadFilter;
    appId = 2280;
    depotId = 2281;
    manifestId = 557527948370603647;
    sha256 = "sha256-KIX9HRzQyQ6YawMVYGVk43z88bi55JUy3HNKNTMA2y4=";
  };

  wads = {
    lights = pkgs.uzdoom |> getFile "share/games/uzdoom/lights.pk3";

    TUCQR6 =
      let
        version = "6";
      in
      fetchzipNoSubst {
        url = "http://www.doomlegends.com/chexquest/TUCQR${version}.zip";
        sha256 = "sha256-AulxYjl2o/M2zCTe9H5mvMk/2BZ5iigBo9+0iIIpC28=";
        stripRoot = false;
      }
      |> getFile "TUCQR${version}.WAD";

    cqstrife =
      let
        version = "6";
      in
      fetchzipNoSubst {
        url = "http://www.doomlegends.com/chexquest/cqstrifeR${version}.zip";
        sha256 = "sha256-pkVx11rO+1DH5AY88sjbesxH2EVRgXXUkOcUcSXhCyc=";
        stripRoot = false;
      }
      |> getFile "cqstrifeR${version}.wad";

    simonsdestiny = fetchItch sources.wad.simonsdestiny |> getFile "Castlevania.ipk3";
    paranoid = fetchIdGames sources.wad.paranoid |> getFile "Paranoid.pk3";
    paranoic = fetchIdGames sources.wad.paranoic |> getFile "paranoic.pk3";

    freedoom1 = pkgs.freedoom |> getFile "share/games/doom/freedoom1.wad";
    freedoom2 = pkgs.freedoom |> getFile "share/games/doom/freedoom2.wad";

    aoddoom = fetchIdGames sources.wad.aoddoom |> getFile "aoddoom2.wad";
    aoddoom_deh = fetchIdGames sources.wad.aoddoom |> getFile "aoddoom2.deh";

    DOOM = DOOM_I_II |> getFile "rerelease/doom.wad";
    DOOM_2 = DOOM_I_II |> getFile "rerelease/doom2.wad";
    NERVE = DOOM_I_II |> getFile "rerelease/nerve.wad";
    MASTER_LEVELS = DOOM_I_II |> getFile "rerelease/masterlevels.wad";
    SIGIL_I = DOOM_I_II |> getFile "rerelease/sigil.wad";
    SIGIL_II = DOOM_I_II |> getFile "rerelease/sigil2.wad";
    PLUTONIA = DOOM_I_II |> getFile "rerelease/plutonia.wad";
    ID1 = DOOM_I_II |> getFile "rerelease/id1.wad";
    TNT = DOOM_I_II |> getFile "rerelease/tnt.wad";
  };

in
{
  _module.args = { inherit mkDoom wadFilter; };
  imports = autoImport ./wad;
  programs.steam.games = with wads; {
    DOOM = mkDoom {
      name = "The Ultimate Doom";
      iwad = DOOM;
    };
    DOOM_2 = mkDoom {
      name = "Doom II: Hell on Earth";
      iwad = DOOM_2;
    };
    NERVE = mkDoom {
      name = "No Rest for the Living";
      iwad = DOOM_2;
      wad = [ NERVE ];
    };
    MASTER_LEVELS = mkDoom {
      name = "Master Levels for Doom II";
      iwad = DOOM_2;
      wad = [ MASTER_LEVELS ];
    };
    SIGIL_I = mkDoom {
      name = "Sigil";
      iwad = DOOM;
      wad = [ SIGIL_I ];
    };
    SIGIL_II = mkDoom {
      name = "Sigil 2";
      iwad = DOOM;
      wad = [ SIGIL_II ];
    };
    PLUTONIA = mkDoom {
      name = "The Plutonia Experiment";
      iwad = PLUTONIA;
    };
    TNT = mkDoom {
      name = "TNT: Evilution";
      iwad = TNT;
    };
    ID1 = mkDoom {
      name = "Legacy of Rust";
      iwad = DOOM_2;
      wad = [ ID1 ];
    };

    TUCQ = mkDoom {
      name = "The Ultimate Chex Quest";
      iwad = TUCQR6;
      wad = [ cqstrife ];
    };
    simonsdestiny = mkDoom {
      name = "Castlevania: Simon's Destiny";
      iwad = simonsdestiny;
    };
    paranoid = mkDoom {
      name = "Paranoid (Half-Life)";
      iwad = paranoid;
    };
    freedoom1 = mkDoom {
      name = "Freeomd: Phase 1";
      iwad = freedoom1;
    };
    freedoom2 = mkDoom {
      name = "Freeomd: Phase 2";
      iwad = freedoom2;
    };
    aoddoom = mkDoom {
      name = "Army of Darkness Doom";
      iwad = aoddoom;
      wad = [ aoddoom_deh ];
    };
  };
}
