{
  config,
  lib,
  pkgs,
  autoImport,
  ...
}:
let
  # The engine wants writes next to cfg/ (shell.json5, console history), so
  # TRX_DIR is a real XDG dir whose read-only parts link back to the store.
  mkTrx =
    { id, ... }@args:
    (lib.removeAttrs args [ "id" ])
    // {
      game = pkgs.writeShellApplication {
        name = "trx-${id}";
        text = ''
          data="''${XDG_DATA_HOME:-$HOME/.local/share}/trx"
          mkdir -p "$data/games" "$data/cfg"
          ln -sfn ${pkgs.tombraider-trx}/share/trx/modules "$data/modules"
          ln -sfn ${pkgs.tombraider-trx}/share/trx/scripts "$data/scripts"
          ln -sfn ${pkgs.tombraider-trx}/share/trx/cfg/* "$data/cfg/"
          ln -sfn ${config.games.trx.data.${id}} "$data/games/${id}"
          export TRX_DIR="$data"
          export TRX_CONFIG_DIR="$data/cfg"
          export TRX_GAMES_DIR="$data/games"
          exec ${pkgs.tombraider-trx}/bin/TRX --mod ${id} "$@"
        '';
      };
    };
in
{
  options.games.trx.data = lib.mkOption {
    type = lib.types.attrsOf lib.types.package;
    default = { };
    description = ''
      Registry of TRX campaign dirs (levels, fmv, music) keyed by mod id.
    '';
  };

  options.games.trx.enable = lib.mkOption {
    type = lib.types.bool;
    default = (builtins.getEnv "LIGHT") == "";
    description = ''
      Whether to fetch and register TRX games at all.
    '';
  };

  imports = autoImport ./.;

  config._module.args = { inherit mkTrx; };
}
