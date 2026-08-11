{
  pkgs,
  guardSizeTail,
  getName,
  ...
}:
# Zeroes cosmetic title/sample-name text in a ProTracker-family .mod;
# audio data untouched. GZDoom never reads that text (libxmp decode-only).
src:
pkgs.runCommand "${getName src}-stripped.mod"
  {
    nativeBuildInputs = [ pkgs.python3 ];
    __contentAddressed = true;
    allowSubstitutes = false;
    outputHashAlgo = "sha256";
    outputHashMode = "flat";
  }
  ''
    python3 ${../py/modstrip.py} "${src}" tmp.mod || rm -f tmp.mod
    ${guardSizeTail "tmp.mod" src}
  ''
