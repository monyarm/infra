{
  pkgs,
  guardSizeTail,
  getName,
  ...
}:
# FWS -> CWS: a real, lossless SWF feature (see py/swfrecompress.py),
# not a re-encode.
{
  handler =
    src:
    pkgs.runCommand "${getName src}-recompressed.swf"
      {
        nativeBuildInputs = [ pkgs.python3 ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        python3 ${../py/swfrecompress.py} "${src}" tmp.out || rm -f tmp.out
        ${guardSizeTail "tmp.out" src}
      '';
  extensions = [ "swf" ];
}
