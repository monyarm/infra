{ config, lib, ... }:
let
  ids =
    field:
    lib.pipe (lib.attrValues config.programs.steam.games) [
      (map (g: g.${field}))
      (lib.filter (x: x != null))
    ];
in
{
  xdg.dataFile."game-library-scan/already-defined.json".text = builtins.toJSON {
    steamAppIds = ids "steamAppId";
    gogIds = ids "gogId";
    epicIds = ids "epicId";
    maximaSlugs = ids "maximaSlug";
  };
}
