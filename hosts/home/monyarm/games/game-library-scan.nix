{
  config,
  lib,
  pkgs,
  ...
}:
let
  ids =
    field:
    lib.pipe (lib.attrValues config.programs.steam.games) [
      (map (g: g.${field}))
      (lib.filter (x: x != null))
    ];
in
{
  home.packages = [ pkgs.game-library-scan ];

  xdg.dataFile."game-library-scan/already-defined.json".text = builtins.toJSON {
    steamAppIds = ids "steamAppId";
    gogIds = ids "gogId";
    epicIds = ids "epicId";
    maximaSlugs = ids "maximaSlug";
  };
}
