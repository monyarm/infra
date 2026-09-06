{
  pkgs,
  getName,
  ...
}:
# Arcade romset zips (NeoGeo/CPS/etc) already have correct MAME member
# names -- just re-deflate in place for a smaller file. Must stay plain
# DEFLATE: MAME can't read 7z/LZMA, so sevenzip-lzma/-deflate is out (wraps
# input as a *new* member, nesting the zip). advzip -4 is the highest
# lossless PKZIP-compatible deflate level.
#
# Some extractors (REE.Rom.Cryptor's CAS2 output, confirmed on real
# Capcom titles) nest every member one level down under a "<game>/" dir --
# MAME's zip reader doesn't recurse, so every ROM inside reads as missing.
# Flatten that single wrapping directory before recompressing, if present.
_extra: rom:
pkgs.runCommand "${getName rom}.zip"
  {
    nativeBuildInputs = [
      pkgs.advancecomp
      pkgs.unzip
      pkgs.zip
    ];
    __contentAddressed = true;
    allowSubstitutes = false;
    outputHashAlgo = "sha256";
    outputHashMode = "flat";
  }
  ''
    mkdir extracted
    unzip -q "${rom}" -d extracted
    entries=$(find extracted -mindepth 1 -maxdepth 1)
    if [ "$(printf '%s\n' "$entries" | wc -l)" -eq 1 ] && [ -d "$entries" ]; then
      mv "$entries"/* extracted/
      rmdir "$entries"
    fi
    (cd extracted && zip -q -r -X "$out" .)
    chmod +w "$out"
    advzip -z -4 "$out"
  ''
