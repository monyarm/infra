{ pkgs, lib, ... }:
{
  mkRandomobs =
    {
      name,
      packFormat,
      texturePacks ? [ ],
      skins ? { },
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
          --out "$out"
      '';
}
