# icotool extracts every frame as PNG (even raw-BMP frames) and repacks
# with -r to keep them PNG-encoded. Same lossless chain as png.nix.
{
  pkgs,
  system,
  guardSizeTail,
  pngLosslessFlags,
  getName,
  ...
}:
src:
derivation {
  name = "${getName src}-icomin.ico";
  inherit system;
  builder = "${pkgs.bash}/bin/bash";
  args = [
    "-c"
    ''
      export PATH=${pkgs.coreutils}/bin:${pkgs.icoutils}/bin:${pkgs.oxipng}/bin:${pkgs.optipng}/bin:${pkgs.advancecomp}/bin
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
  ];
  allowSubstitutes = false;
  __contentAddressed = true;
  outputHashAlgo = "sha256";
  outputHashMode = "flat";
}
