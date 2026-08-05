{
  pkgs,
  guardSizeTail,
  getName,
  ...
}:
src:
pkgs.runCommand "${getName src}-optimized.wad"
  {
    buildInputs = [ pkgs.wadptr ];
    __contentAddressed = true;
    allowSubstitutes = false;
    outputHashAlgo = "sha256";
    outputHashMode = "flat";
  }
  ''
    # wadptr stops parsing flags at the first non-flag argument, so
    # -o must come before the input filename or it's silently treated
    # as part of the (single-file) input list instead.
    wadptr -c -o tmp.wad "${src}" || rm -f tmp.wad
    ${guardSizeTail "tmp.wad" src}
  ''
