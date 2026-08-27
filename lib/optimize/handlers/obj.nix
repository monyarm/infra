{
  pkgs,
  system,
  guardSizeTail,
  getName,
  ...
}:
let
  guardTmpObj = guardSizeTail "tmp.obj";

  # Drops comments/blank lines, reparses numbers via parseFloat -- lossy:
  # trims trailing zeros and loses "-0" sign.
  lossy =
    src:
    derivation {
      name = "${getName src}-objmin";
      inherit system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        ''
          export PATH=${pkgs.coreutils}/bin:${pkgs.nodejs}/bin:${pkgs.gawk}/bin
          node ${../js/objmin.js} "${src}" > tmp.obj || rm -f tmp.obj
          ${guardTmpObj src}
        ''
      ];
      allowSubstitutes = false;
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";
    };

  # Same comment/blank-line stripping, but trailing zeros are trimmed as
  # pure text in a single obj-specific awk pass (see obj-lossless.awk) --
  # no float re-parse, so the exact original digits (and sign, including
  # "-0") are preserved.
  lossless =
    src:
    derivation {
      name = "${getName src}-objlossless";
      inherit system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        ''
          export PATH=${pkgs.coreutils}/bin:${pkgs.nodejs}/bin:${pkgs.gawk}/bin
          gawk -f ${../awk/obj-lossless.awk} "${src}" > tmp.obj || rm -f tmp.obj
          ${guardTmpObj src}
        ''
      ];
      allowSubstitutes = false;
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";
    };
in
{
  normal = lossless;
  prime = lossy;
  extensions = [ "mtl" ]; # same text format as obj
}
