{
  pkgs,
  lib,
  getName,
  ...
}:
# Patch an existing MAME-style romset zip's member list: add zero-filled
# dummy stubs for chips that can't be extracted (e.g. a system BIOS file no
# owned source embeds), and/or rename existing members to match a driver
# revision that renamed its ROM labels without changing content.
{
  add ? { }, # { "sm1.sm1" = 131072; } -- name -> size in bytes
  rename ? { }, # { "256-sma.bin" = "green.neo-sma"; } -- old name -> new name
}:
zip:
pkgs.runCommand "${getName zip}.zip"
  {
    nativeBuildInputs = [
      pkgs.unzip
      pkgs.zip
      pkgs.advancecomp
    ];
    __contentAddressed = true;
    allowSubstitutes = false;
    outputHashAlgo = "sha256";
    outputHashMode = "flat";
  }
  ''
    mkdir extracted
    unzip -q "${zip}" -d extracted
    entries=$(find extracted -mindepth 1 -maxdepth 1)
    if [ "$(printf '%s\n' "$entries" | wc -l)" -eq 1 ] && [ -d "$entries" ]; then
      mv "$entries"/* extracted/
      rmdir "$entries"
    fi
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (old: new: ''mv "extracted/${old}" "extracted/${new}"'') rename
    )}
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: size: ''head -c ${toString size} /dev/zero > "extracted/${name}"'') add
    )}
    (cd extracted && zip -q -r -X "$out" .)
    chmod +w "$out"
    advzip -z -4 "$out"
  ''
