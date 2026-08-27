{
  pkgs,
  system,
  guardSizeTail,
  getName,
  ...
}:
# gcc tokenizer strips comments safely (string/char-literal-aware).
# -fpreprocessed -undef: comment removal only, no macro expansion.
{
  handler =
    src:
    derivation {
      name = "${getName src}-stripped";
      inherit system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        ''
          export PATH=${pkgs.coreutils}/bin:${pkgs.gcc}/bin
          gcc -E -fpreprocessed -dD -P -undef -w -x c++ "${src}" > tmp.out 2>/dev/null || rm -f tmp.out
          ${guardSizeTail "tmp.out" src}
        ''
      ];
      allowSubstitutes = false;
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";
    };
  extensions = [
    "h"
    "cc"
    "cpp"
    "hpp"
  ];
}
