{
  pkgs,
  system,
  guardSizeTail,
  getName,
  ...
}:
# Zeroes cosmetic title/sample-name text in a ProTracker-family .mod;
# audio data untouched. GZDoom never reads that text (libxmp decode-only).
src:
derivation {
  name = "${getName src}-stripped.mod";
  inherit system;
  builder = "${pkgs.bash}/bin/bash";
  args = [
    "-c"
    ''
      export PATH=${pkgs.coreutils}/bin:${pkgs.python3}/bin
      python3 ${../py/modstrip.py} "${src}" tmp.mod || rm -f tmp.mod
      ${guardSizeTail "tmp.mod" src}
    ''
  ];
  allowSubstitutes = false;
  __contentAddressed = true;
  outputHashAlgo = "sha256";
  outputHashMode = "flat";
}
