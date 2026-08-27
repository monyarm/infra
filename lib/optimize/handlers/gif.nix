{
  pkgs,
  system,
  guardSizeTail,
  getName,
  ...
}:
# gifsicle -O3: lossless LZW re-optimization, pixels/frames untouched.
{
  handler =
    src:
    derivation {
      name = "${getName src}-optimized.gif";
      inherit system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        ''
          export PATH=${pkgs.coreutils}/bin:${pkgs.gifsicle}/bin
          gifsicle -O3 "${src}" > tmp.out || rm -f tmp.out
          ${guardSizeTail "tmp.out" src}
        ''
      ];
      allowSubstitutes = false;
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";
    };
  extensions = [ "gif" ];
}
