{ pkgs, guardSize, getName, ... }:
# gcc's own tokenizer strips comments correctly (string/char-literal-safe,
# unlike regex/awk). -fpreprocessed -undef: no macro expansion, no #include
# resolution, no #if evaluation -- just comment removal. -dD keeps #define
# lines; -P drops line markers and blank lines. -x c++ covers c/h/cc/cpp
# alike (strict superset lexer). Falls back to the original file on failure.
src:
guardSize (pkgs.runCommand "${getName src}-stripped"
  {
    nativeBuildInputs = [ pkgs.gcc ];
    __contentAddressed = true;
    allowSubstitutes = false;
    outputHashAlgo = "sha256";
    outputHashMode = "flat";
  }
  ''
    gcc -E -fpreprocessed -dD -P -undef -w -x c++ "${src}" > tmp.out 2>/dev/null || true
    [ -s tmp.out ] && mv tmp.out "$out" || cp "${src}" "$out"
  ''
) src
