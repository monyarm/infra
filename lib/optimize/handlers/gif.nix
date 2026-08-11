{
  pkgs,
  guardSizeTail,
  getName,
  ...
}:
# gifsicle -O3: lossless LZW re-optimization, pixels/frames untouched.
{
  handler =
    src:
    pkgs.runCommand "${getName src}-optimized.gif"
      {
        nativeBuildInputs = [ pkgs.gifsicle ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        gifsicle -O3 "${src}" > tmp.out || rm -f tmp.out
        ${guardSizeTail "tmp.out" src}
      '';
  extensions = [ "gif" ];
}
