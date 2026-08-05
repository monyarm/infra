# icotool extracts every frame as PNG (even raw-BMP frames) and repacks
# with -r to keep them PNG-encoded. Same lossless chain as png.nix.
{
  pkgs,
  guardSizeTail,
  pngLosslessFlags,
  getName,
  ...
}:
src:
pkgs.runCommand "${getName src}-icomin.ico"
  {
    nativeBuildInputs = [
      pkgs.icoutils
      pkgs.oxipng
      pkgs.optipng
      pkgs.advancecomp
    ];
    __contentAddressed = true;
    allowSubstitutes = false;
    outputHashAlgo = "sha256";
    outputHashMode = "flat";
  }
  ''
    (
      set -e
      mkdir extracted
      icotool -x -o extracted "${src}"
      args=()
      for f in extracted/*.png; do
        oxipng ${pngLosslessFlags.oxipng 4} "$f"
        optipng ${pngLosslessFlags.optipng} "$f"
        advpng ${pngLosslessFlags.advpng} "$f"
        args+=(-r "$f")
      done
      icotool -c -o tmp.ico "''${args[@]}"
    ) || rm -f tmp.ico
    ${guardSizeTail "tmp.ico" src}
  ''
