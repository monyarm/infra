{
  pkgs,
  lib,
  autoImport,
  optimize,
  ...
}:
let
  # grp: game dir, file: main GRP inside it. Raze adds the GRP's own dir
  # (loose CONs/maps/music), so never pass a bare single-file store path.
  mkRaze =
    {
      grp,
      file,
      ...
    }@args:
    (lib.removeAttrs args [
      "grp"
      "file"
    ])
    // {
      game = "${optimize grp}/${file}";
      launcher = {
        package = pkgs.raze;
        args = [ "-iwad" ];
      };
    };
in
{
  options.games.raze.grps = lib.mkOption {
    type = lib.types.attrsOf lib.types.package;
    default = { };
    description = ''
      Registry of Raze game dirs (GRP plus loose content).
    '';
  };

  options.games.raze.enable = lib.mkOption {
    type = lib.types.bool;
    default = (builtins.getEnv "LIGHT") == "";
    description = ''
      Whether to fetch, optimize, and register Raze games at all.
    '';
  };

  imports = autoImport ./.;

  config._module.args = { inherit mkRaze; };
}
