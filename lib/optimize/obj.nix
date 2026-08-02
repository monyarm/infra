{ pkgs, guardSize, getName, ... }:
let
  # Ported from gameoptimizer (github.com/monyarm/gameoptimizer,
  # src/deps/objmin.js + src/tasks/obj.sh) unmodified: drops "#" comment
  # and blank lines, then reparses every numeric token through
  # parseFloat/toString -- this also trims trailing zeros, but as a side
  # effect of a real float round-trip, which is why it's the lossy path
  # (e.g. "-0.000000" normalizes to "0", losing the sign; arbitrary-length
  # decimals could in principle shift on the round-trip). Same
  # `|| cat "$src"` fallback as the reference shell task.
  lossy =
    src:
    guardSize (pkgs.runCommand "${getName src}-objmin"
      {
        nativeBuildInputs = [ pkgs.nodejs ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        { node ${./objmin.js} "${src}" || cat "${src}"; } > "$out"
      ''
    ) src;

  # Same comment/blank-line stripping, but trailing zeros are trimmed as
  # pure text in a single obj-specific awk pass (see obj-lossless.awk) --
  # no float re-parse, so the exact original digits (and sign, including
  # "-0") are preserved.
  lossless =
    src:
    guardSize (pkgs.runCommand "${getName src}-objlossless"
      {
        nativeBuildInputs = [ pkgs.gawk ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        gawk -f ${./obj-lossless.awk} "${src}" > "$out"
      ''
    ) src;
in
{
  normal = lossless;
  prime = lossy;
}
