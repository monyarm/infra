{ pkgs, lib, ... }:
{
  # Merges an ordered list of directory layers into one derivation. Later
  # layers overwrite matching paths from earlier layers. Deliberately a
  # build-time file copy rather than an eval-time attrset merge over
  # builtins.readDir -- reading a fetched layer's directory listing at eval
  # time would force-realize it during evaluation (IFD).
  mkModDir =
    { name, layers }:
    pkgs.runCommand name { } ''
      mkdir -p "$out"
      ${lib.concatMapStringsSep "\n" (layer: ''
        if [ -d "${layer}" ]; then
          cp -rT --no-preserve=mode,ownership "${layer}" "$out"
        fi
      '') layers}
    '';
}
