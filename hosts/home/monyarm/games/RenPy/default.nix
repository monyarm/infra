{
  lib,
  pkgs,
  config,
  optimize,
  autoImport,
  ...
}:
let
  inherit (import ./mkGame.nix { inherit lib pkgs; }) mkRenPyGame;
in
{
  options.games.renpy.games = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        freeformType = lib.types.attrsOf lib.types.anything;
        options = {
          game = lib.mkOption {
            type = lib.types.package;
            description = "Pre-optimize built Ren'Py game derivation (mkRenPyGame's build output).";
          };
          renpy = lib.mkOption {
            type = lib.types.package;
            default = pkgs.renpyMinimal;
            description = "Ren'Py engine package used to launch this game.";
          };
        };
      }
    );
    default = { };
    description = ''
      Registry of Ren'Py games, keyed the same as programs.steam.games.
      programs.steam.games is generated from this automatically (see
      config below) -- optimize is applied at generation time, mirroring
      games.doom.wads (game) + mkDoom's `game = optimize iwad`. Freeform:
      any extra key (steamAppId, steamCdnImagesHash, tags, ...) passes
      straight through into the generated programs.steam.games entry.
    '';
  };

  imports = autoImport {
    path = ./.;
    exclude = [ "mkGame.nix" ];
  };

  config = {
    _module.args = {
      inherit mkRenPyGame;
    };

    programs.steam.games = lib.mapAttrs (
      _: g:
      (removeAttrs g [
        "game"
        "renpy"
      ])
      // {
        game = optimize g.game;
        launcher = {
          package = g.renpy;
        };
        args = "run";
      }
    ) config.games.renpy.games;
  };
}
