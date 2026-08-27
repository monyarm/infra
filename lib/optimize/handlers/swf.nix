{
  pkgs,
  system,
  guardSizeTail,
  getName,
  ...
}:
# FWS -> CWS: a real, lossless SWF feature (see py/swfrecompress.py),
# not a re-encode.
{
  handler =
    src:
    derivation {
      name = "${getName src}-recompressed.swf";
      inherit system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        ''
          export PATH=${pkgs.coreutils}/bin:${pkgs.python3}/bin
          python3 ${../py/swfrecompress.py} "${src}" tmp.out || rm -f tmp.out
          ${guardSizeTail "tmp.out" src}
        ''
      ];
      allowSubstitutes = false;
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";
    };
  extensions = [ "swf" ];
}
