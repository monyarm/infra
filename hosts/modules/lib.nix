{
  inputs,
  config ? null,
  pkgs,
  lib,
  sources,
  ...
}:

let
  mkOutOfStoreSymlink =
    if (config != null && config ? lib.file) then config.lib.file.mkOutOfStoreSymlink else (_x: { });
  # Separately-pinned pkgs for lib/optimize and lib/compressRom's actual
  # tool invocations (oxipng, ffmpeg, wadptr, ...) -- see the
  # optimize-nixpkgs flake input's own comment in flake.nix. Overlay stack
  # shared with lib/optimize/dynamic.nix's inner reconstruction -- see that
  # file's comment for why it's just the local packages overlay.
  optimizePkgs = import inputs.optimize-nixpkgs {
    inherit (pkgs) system;
    config.allowUnfree = true;
    overlays = import ../../lib/optimize/overlays.nix {
      inherit sources;
      determinateNix = inputs.determinate-nix.packages.${pkgs.system}.nix;
      drowseSrc = inputs.drowse;
    };
  };
  customLib = import ../../lib {
    inherit (pkgs) system lib;
    inherit pkgs mkOutOfStoreSymlink optimizePkgs;
    nixWasmRustPath = inputs.nix-wasm-rust;
    config = if config != null then config else { };
  };
in
{
  _module.args = {
    inherit inputs mkOutOfStoreSymlink;
    shouldFullUpdate = customLib.meta.deviceType != "android" && (builtins.getEnv "FULLUPDATE") != "";
  }
  // customLib;
}
