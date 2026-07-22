{
  pkgs,
  lib,
  config,
  getFile,
  fetchIdGames,
  fetchzipNoSubst,
  fetchItch,
  sources,
  autoImport,
  ...
}:
let

  mkDoom =
    {
      game,
      wad ? [ ],
      ...
    }@args:
    (lib.removeAttrs args [ "wad" ])
    // {
      launcher = {
        package = pkgs.uzdoom;
        args = [ "-iwad" ];
      };
      args = [ "-file" ]
      ++ (lib.optionals (wad != null && wad != [ ]) (map (x: "${x}") wad))
      ++ [ "${config.games.doom.wads.lights}" ];
    };

  wadFilter = [ "regex:(.*\.(wad|WAD))" ];

in
{
  options.games.doom.wads = lib.mkOption {
    type = lib.types.attrsOf lib.types.package;
    default = { };
    description = ''
      Registry of Doom WAD/PK3 derivations. 
    '';
  };

  imports = autoImport ./wad;

  config = {
    _module.args = { inherit mkDoom wadFilter; };

    games.doom.wads = {
      lights = pkgs.uzdoom |> getFile "share/games/uzdoom/lights.pk3";

      tucq =
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
      aoddoomDeh = fetchIdGames sources.wad.aoddoom |> getFile "aoddoom2.deh";
    };

    programs.steam.games = with config.games.doom.wads; {
      DOOM = mkDoom {
        name = "The Ultimate Doom";
        game = doom;
      };
      DOOM_2 = mkDoom {
        name = "Doom II: Hell on Earth";
        game = doom2;
      };
      NERVE = mkDoom {
        name = "No Rest for the Living";
        game = doom2;
        wad = [ nerve ];
      };
      MASTER_LEVELS = mkDoom {
        name = "Master Levels for Doom II";
        game = doom2;
        wad = [ masterLevels ];
      };
      SIGIL_I = mkDoom {
        name = "Sigil";
        game = doom;
        wad = [ sigil ];
      };
      SIGIL_II = mkDoom {
        name = "Sigil 2";
        game = doom;
        wad = [ sigil2 ];
      };
      PLUTONIA = mkDoom {
        name = "The Plutonia Experiment";
        game = plutonia;
      };
      TNT = mkDoom {
        name = "TNT: Evilution";
        game = tnt;
      };
      ID1 = mkDoom {
        name = "Legacy of Rust";
        game = doom2;
        wad = [ id1 ];
      };

      TUCQ = mkDoom {
        name = "The Ultimate Chex Quest";
        game = tucq;
        wad = [ cqstrife ];
      };
      simonsdestiny = mkDoom {
        name = "Castlevania: Simon's Destiny";
        game = simonsdestiny;
      };
      paranoid = mkDoom {
        name = "Paranoid (Half-Life)";
        game = paranoid;
      };
      freedoom1 = mkDoom {
        name = "Freeomd: Phase 1";
        game = freedoom1;
      };
      freedoom2 = mkDoom {
        name = "Freeomd: Phase 2";
        game = freedoom2;
      };
      aoddoom = mkDoom {
        name = "Army of Darkness Doom";
        game = aoddoom;
        wad = [ aoddoomDeh ];
      };
    };
  };
}
