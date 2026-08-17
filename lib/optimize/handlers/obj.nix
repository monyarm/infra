{
  pkgs,
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
    pkgs.runCommand "${getName src}-objmin"
      {
        nativeBuildInputs = [ pkgs.nodejs ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        node ${../js/objmin.js} "${src}" > tmp.obj || rm -f tmp.obj
        ${guardTmpObj src}
      '';

  # Same comment/blank-line stripping, but trailing zeros are trimmed as
  # pure text in a single obj-specific awk pass (see obj-lossless.awk) --
  # no float re-parse, so the exact original digits (and sign, including
  # "-0") are preserved.
  lossless =
    src:
    pkgs.runCommand "${getName src}-objlossless"
      {
        nativeBuildInputs = [ pkgs.gawk ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        gawk -f ${../awk/obj-lossless.awk} "${src}" > tmp.obj || rm -f tmp.obj
        ${guardTmpObj src}
      '';
in
{
  normal = lossless;
  prime = lossy;
  extensions = [ "mtl" ]; # same text format as obj
}
