{ pkgs, guardSize, getName, ... }:
# Every stage below falls back to passing its own input through unchanged
# on any failure (corrupt/unusual PNGs some real mods ship do exist). No
# subshell/set -e: each command runs plainly, and a plain `[ -e "$out" ] ||
# cp` at the end catches anything that didn't leave a real file behind.
let
  pngquant =
    src:
    guardSize (pkgs.runCommand "${getName src}-quantized.png"
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
        # pngquant's own --skip-if-larger declining to write is expected,
        # not an error -- tmp.png is just left as the pre-quantize copy.
        pngquant --quality=80-98 --skip-if-larger --ext .png --force tmp.png || true
        mv tmp.png "$out" || true
        [ -e "$out" ] || cp "${src}" "$out"
      ''
    ) src;

  oxipng =
    level: src:
    guardSize (pkgs.runCommand "${getName src}-oxipng.png"
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
        oxipng -o ${toString level} --strip all --alpha tmp.png || true
        mv tmp.png "$out" || true
        [ -e "$out" ] || cp "${src}" "$out"
      ''
    ) src;

  optipng =
    src:
    guardSize (pkgs.runCommand "${getName src}-optipng.png"
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
        optipng -o7 -quiet tmp.png || true
        mv tmp.png "$out" || true
        [ -e "$out" ] || cp "${src}" "$out"
      ''
    ) src;

  advpng =
    src:
    guardSize (pkgs.runCommand "${getName src}-advpng.png"
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
        advpng -z -4 tmp.png || true
        mv tmp.png "$out" || true
        [ -e "$out" ] || cp "${src}" "$out"
      ''
    ) src;

  lossless = src: src |> (oxipng 4) |> optipng |> advpng;
in
{
  normal = lossless;
  prime = src: src |> pngquant |> lossless;
}
