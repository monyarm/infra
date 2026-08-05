{
  pkgs,
  guardSizeTail,
  getName,
  ...
}:
# gcc tokenizer strips comments safely (string/char-literal-aware).
# -fpreprocessed -undef: comment removal only, no macro expansion.
src:
pkgs.runCommand "${getName src}-stripped"
  {
    nativeBuildInputs = [ pkgs.gcc ];
    __contentAddressed = true;
    allowSubstitutes = false;
    outputHashAlgo = "sha256";
    outputHashMode = "flat";
  }
  ''
    gcc -E -fpreprocessed -dD -P -undef -w -x c++ "${src}" > tmp.out 2>/dev/null || rm -f tmp.out
    ${guardSizeTail "tmp.out" src}
  ''
