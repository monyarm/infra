{
  pkgs,
  system,
  pngLosslessFlags,
  getName,
  ...
}:
# The whole lossless chain (oxipng -> optipng -> advpng, prefixed by
# pngquant in the prime variant) runs inside ONE raw derivation instead of
# three or four chained CA stages: one builder launch and one store path
# per file instead of one per tool.
#
# Raw `derivation`, not runCommand/mkDerivation: no stdenv machinery in the
# .drv, just the tools and the script.
let
  coreutilsBin = "${pkgs.coreutils}/bin";
  oxipngBin = "${pkgs.oxipng}/bin/oxipng";
  optipngBin = "${pkgs.optipng}/bin/optipng";
  advpngBin = "${pkgs.advancecomp}/bin/advpng";
  pngquantBin = "${pkgs.pngquant}/bin/pngquant";

  # Inlined guardSizeTail, restoring the candidate in place rather than to
  # $out: the merged script keeps its running best in tmp.png, so every
  # stage re-guards against the ORIGINAL src exactly like the old chained
  # stages' own guards did.
  guard = src: ''
    [ ! -e "tmp.png" ] || ${coreutilsBin}/chmod u+w "tmp.png"
    if [ -s "tmp.png" ] && [ "$(${coreutilsBin}/stat -L -c%s "tmp.png")" -le "$(${coreutilsBin}/stat -L -c%s "${src}")" ]; then
      :
    else
      ${coreutilsBin}/cp "${src}" "tmp.png"
    fi
  '';

  # Every tool gets `|| rm -f` (never `|| true`) so a crash can't leave a
  # truncated candidate for the guard to accept -- same rule as before.
  losslessSteps = src: ''
    ${coreutilsBin}/chmod u+w tmp.png
    ${oxipngBin} ${pngLosslessFlags.oxipng 4} tmp.png || rm -f tmp.png
    ${guard src}
    ${coreutilsBin}/chmod u+w tmp.png
    ${optipngBin} ${pngLosslessFlags.optipng} tmp.png || rm -f tmp.png
    ${guard src}
    ${coreutilsBin}/chmod u+w tmp.png
    ${advpngBin} ${pngLosslessFlags.advpng} tmp.png || rm -f tmp.png
    ${guard src}
  '';

  mkPng =
    steps: src:
    derivation {
      name = "${getName src}-optimized.png";
      inherit system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        (
          ''
            export PATH=${coreutilsBin}
            cp "${src}" tmp.png
            chmod +w tmp.png
          ''
          + steps src
          + ''
            ${coreutilsBin}/cp "tmp.png" "$out"
          ''
        )
      ];
      allowSubstitutes = false;
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";
    };
in
{
  # Lossless-only chain, one derivation.
  normal = mkPng losslessSteps;

  # pngquant is lossy-but-bigger-is-rejected: run it first, guard, then the
  # lossless chain over whatever survived -- all in the same derivation.
  prime = mkPng (
    src:
    ''
      ${coreutilsBin}/chmod u+w tmp.png
      ${pngquantBin} --quality=80-98 --skip-if-larger --output tmp-quant.png tmp.png || rm -f tmp-quant.png tmp.png
      [ ! -e tmp-quant.png ] || mv tmp-quant.png tmp.png
      ${guard src}
    ''
    + losslessSteps src
  );
}
