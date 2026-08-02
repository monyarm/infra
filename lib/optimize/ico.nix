# Windows .ico: icoutils' icotool can extract every frame as PNG (even
# ones stored as raw BMP internally -- verified pixel-identical via
# imagemagick's `compare -metric AE` against a real fetched icon,
# LegendOfDoom.pk3's Zelda.ico) and repack with -r ("Vista icons") to keep
# them PNG-encoded instead of icotool's default of re-inflating to raw BMP.
# Each extracted frame gets the same lossless oxipng/optipng/advpng chain
# as png.nix's prime path (same CLI tools/args, just run directly in a
# loop here rather than through IFD) -- verified on the real icon: 9
# frames, all pixel-identical, 217743 -> 93023 bytes (~57% smaller).
{ pkgs, guardSize, getName, ... }:
src:
guardSize (pkgs.runCommand "${getName src}-icomin.ico"
  {
    nativeBuildInputs = [ pkgs.icoutils pkgs.oxipng pkgs.optipng pkgs.advancecomp ];
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
        oxipng -o4 --strip all --alpha "$f"
        optipng -o7 -quiet "$f"
        advpng -z -4 "$f"
        args+=(-r "$f")
      done
      icotool -c -o "$out" "''${args[@]}"
    ) || cp "${src}" "$out"
  ''
) src
