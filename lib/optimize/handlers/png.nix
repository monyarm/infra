{
  pkgs,
  guardSizeTail,
  pngLosslessFlags,
  getName,
  ...
}:
# Every stage falls back to src on failure via guardSizeTail's
# missing-candidate case.
let
  pngquant =
    src:
    pkgs.runCommand "${getName src}-quantized.png"
      {
        buildInputs = [ pkgs.pngquant ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        cp "${src}" tmp.png
        chmod +w tmp.png
        pngquant --quality=80-98 --skip-if-larger --ext .png --force tmp.png || rm -f tmp.png
        ${guardSizeTail "tmp.png" src}
      '';

  oxipng =
    level: src:
    pkgs.runCommand "${getName src}-oxipng.png"
      {
        buildInputs = [ pkgs.oxipng ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        cp "${src}" tmp.png
        chmod +w tmp.png
        oxipng ${pngLosslessFlags.oxipng level} tmp.png || rm -f tmp.png
        ${guardSizeTail "tmp.png" src}
      '';

  optipng =
    src:
    pkgs.runCommand "${getName src}-optipng.png"
      {
        buildInputs = [ pkgs.optipng ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        cp "${src}" tmp.png
        chmod +w tmp.png
        optipng ${pngLosslessFlags.optipng} tmp.png || rm -f tmp.png
        ${guardSizeTail "tmp.png" src}
      '';

  advpng =
    src:
    pkgs.runCommand "${getName src}-advpng.png"
      {
        buildInputs = [ pkgs.advancecomp ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        cp "${src}" tmp.png
        chmod +w tmp.png
        advpng ${pngLosslessFlags.advpng} tmp.png || rm -f tmp.png
        ${guardSizeTail "tmp.png" src}
      '';

  lossless =
    src:
    src
    |> (oxipng 4)
    |> optipng
    |> advpng;
in
{
  normal = lossless;
  prime = src: src |> pngquant |> lossless;
}
