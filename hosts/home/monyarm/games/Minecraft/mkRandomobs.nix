{ pkgs, lib, ... }:
{
  mkRandomobs =
    {
      name,
      packFormat,
      texturePacks ? [ ], # resource-pack-shaped dirs; extracts each entity's known vanilla-convention path
      jarTextures ? { }, # entity -> [ { jar; path; } ... ] -- explicit extraction from an arbitrary mod jar
      skins ? { }, # entity -> [ package ... ] -- each a single skin PNG, or a directory of multiple skin PNGs
    }:
    pkgs.runCommand name
      {
        nativeBuildInputs = [ (pkgs.python3.withPackages (ps: [ ps.pillow ])) ];
      }
      ''
        python3 ${./randomobs.py} \
          --pack-format ${toString packFormat} \
          ${lib.concatMapStringsSep " " (p: "--texture-pack \"${p}\"") texturePacks} \
          ${
            lib.concatStringsSep " " (
              lib.flatten (lib.mapAttrsToList (entity: paths: map (p: "--skin \"${entity}=${p}\"") paths) skins)
            )
          } \
          ${
            lib.concatStringsSep " " (
              lib.flatten (
                lib.mapAttrsToList (
                  entity: entries: map (e: "--jar-texture \"${entity}=${e.jar}::${e.path}\"") entries
                ) jarTextures
              )
            )
          } \
          --out "$out"
      '';
}
