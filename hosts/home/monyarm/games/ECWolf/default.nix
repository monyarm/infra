{
  pkgs,
  lib,
  config,
  autoImport,
  optimize,
  ...
}:
{
  options.games.ecwolf.data = lib.mkOption {
    type = lib.types.attrsOf lib.types.package;
    default = { };
    description = ''
      Registry of ECWolf base data files, keyed by on-disk filename (e.g. VSWAP.WL6).
    '';
  };

  options.games.ecwolf.enable = lib.mkOption {
    type = lib.types.bool;
    default = (builtins.getEnv "LIGHT") == "";
    description = ''
      Whether to fetch and register ECWolf games at all.
    '';
  };

  imports = autoImport ./.;

  # no data-dir arg; ~/.config/ecwolf is in default BaseDataPaths (non-recursive)
  config.xdg.configFile = lib.mapAttrs' (
    name: file: lib.nameValuePair "ecwolf/${name}" { source = optimize file; }
  ) config.games.ecwolf.data;

  config._module.args.mkEcwolf =
    { data, ... }@args:
    (lib.removeAttrs args [ "data" ])
    // {
      game = pkgs.ecwolf;
      args = [
        "--data"
        data
      ];
    };
}
