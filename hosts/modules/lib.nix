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
  # optimize-nixpkgs flake input's own comment in flake.nix.
  optimizePkgs = import inputs.optimize-nixpkgs {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
    overlays = import ../../lib/optimize/overlays.nix {
      inherit sources;
      determinateNix = inputs.determinate-nix-optimize.packages.${pkgs.stdenv.hostPlatform.system}.nix;
      drowseSrc = inputs.drowse;
      craneLib = inputs.crane.mkLib pkgs;
    };
  };
  customLib = import ../../lib {
    system = pkgs.stdenv.hostPlatform.system;
    inherit (pkgs) lib;
    inherit pkgs mkOutOfStoreSymlink optimizePkgs;
    nixWasmRustPath = inputs.nix-wasm-rust;
    niccupLib = inputs.niccup.lib;
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
