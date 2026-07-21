{
  pkgs,
  lib,
  getFile,fetchIdGames,
  fetchzipNoSubst,
  fetchItch,
  fetchSteam,
  sources,
  ...
}:
let

  mkDoom =
    {
      iwad,
      wads ? [ ],
      ...
    }@args:
    (lib.removeAttrs args [
      "iwad"
      "wads"
    ])
    // {
      game = pkgs.uzdoom;
      args = [
        "-iwad ${iwad}"
      ]
      ++ (lib.optionals (wads != null && wads != [ ])  (["-file"] ++ (map (x: "${x}") wads)));

    };
    
    DOOM_I_II = fetchSteam {
      filelist = ["regex:(.*\.(wad|WAD))"];
      appId = 2280;
      depotId = 2281;
      manifestId = 557527948370603647;
      sha256 = "sha256-wHjpjgYPoUyBcC5E53AwrgvvW4hls09MVSDuLHl/5YY=";
    };

  wads = {
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
    paranoid =
      fetchIdGames sources.wad.paranoid
      |> getFile "Paranoid.pk3";
    paranoic =
      fetchIdGames sources.wad.paranoic
      |> getFile "paranoic.pk3";
  
    freedoom1 = pkgs.freedoom
      |> getFile "share/games/doom/freedoom1.wad";
    freedoom2 = pkgs.freedoom
      |> getFile "share/games/doom/freedoom2.wad";

    aoddoom =
      fetchIdGames sources.wad.aoddoom
      |> getFile "aoddoom2.wad";
    aoddoom_deh =
      fetchIdGames sources.wad.aoddoom
      |> getFile "aoddoom2.deh";

    DOOM = DOOM_I_II  |> getFile "base/DOOM.WAD";
  };

in
{
  programs.steam.games = with wads; {
    # DOOM = mkDoom {
    #   name = "Doom";
    #   iwad = DOOM;
    # };

    TUCQ = mkDoom {
      name = "The Ultimate Chex Quest";
      iwad = TUCQR6;
      wads = [ cqstrife ];
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
      wads = [aoddoom_deh];
    };
  };
}
