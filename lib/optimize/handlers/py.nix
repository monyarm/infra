{
  pkgs,
  system,
  guardSizeTail,
  getName,
  ...
}:
# tokenize-based comment/blank-line stripper (see py/pystrip.py) --
# string/f-string/docstring-aware, unlike a naive line-based "#" filter.
{
  handler =
    src:
    derivation {
      name = "${getName src}-stripped.py";
      inherit system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        ''
          export PATH=${pkgs.coreutils}/bin:${pkgs.python3}/bin
          python3 ${../py/pystrip.py} "${src}" tmp.out || rm -f tmp.out
          ${guardSizeTail "tmp.out" src}
        ''
      ];
      allowSubstitutes = false;
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";
    };
  extensions = [ "py" ];
}
