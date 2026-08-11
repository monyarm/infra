{
  pkgs,
  guardSizeTail,
  getName,
  ...
}:
# tokenize-based comment/blank-line stripper (see py/pystrip.py) --
# string/f-string/docstring-aware, unlike a naive line-based "#" filter.
{
  handler =
    src:
    pkgs.runCommand "${getName src}-stripped.py"
      {
        nativeBuildInputs = [ pkgs.python3 ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        python3 ${../py/pystrip.py} "${src}" tmp.out || rm -f tmp.out
        ${guardSizeTail "tmp.out" src}
      '';
  extensions = [ "py" ];
}
