{
  pkgs,
  getName,
  ...
}:
# Arcade romset zips (NeoGeo/CPS/etc) already have correct MAME member
# names/structure -- just re-deflate in place for a smaller file. Must
# stay plain DEFLATE: MAME can't read 7z/LZMA, so sevenzip-lzma/-deflate
# is out (wraps input as a *new* member, nesting the zip). advzip -4 is
# the highest lossless PKZIP-compatible deflate level.
_extra: rom:
pkgs.runCommand "${getName rom}.zip"
  {
    nativeBuildInputs = [ pkgs.advancecomp ];
    __contentAddressed = true;
    allowSubstitutes = false;
    outputHashAlgo = "sha256";
    outputHashMode = "flat";
  }
  ''
    cp "${rom}" "$out"
    chmod +w "$out"
    advzip -z -4 "$out" || true
  ''
