{
  pkgs,
  lib,
  dispatchExt,
  ...
}:
let
  caAttrs = {
    __contentAddressed = true;
    outputHashAlgo = "sha256";
    outputHashMode = "flat";
  };
  flipsHandler =
    p: f:
    pkgs.runCommand (lib.getName f) ({ nativeBuildInputs = [ pkgs.flips ]; } // caAttrs) ''
      flips --apply "${p}" "${f}" "$out"
    '';
  xdeltaHandler =
    p: f:
    pkgs.runCommand (lib.getName f) ({ nativeBuildInputs = [ pkgs.xdelta ]; } // caAttrs) ''
      xdelta3 -d -s "${f}" "${p}" "$out"
    '';
  patchHandler =
    p: f:
    pkgs.runCommand (lib.getName f) ({ nativeBuildInputs = [ pkgs.gnupatch ]; } // caAttrs) ''
      patch "${f}" -i "${p}" -o "$out"
    '';
in
patch: file:
dispatchExt {
  ".ips" = flipsHandler;
  ".bps" = flipsHandler;
  ".ups" = flipsHandler;
  ".xdelta" = xdeltaHandler;
  ".vcdiff" = xdeltaHandler;
  ".diff" = patchHandler;
  ".patch" = patchHandler;
  "_" =
    p: _f:
    throw "patchFile: unsupported patch format for '${p.name or (toString p)}' (supported: ips, bps, ups, xdelta, vcdiff, diff, patch)";
} patch file
