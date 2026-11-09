{
  inputs,
  lib,
  pkgs,
  optimizePkgs,
  wasm,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;
  # lib/optimize/dynamic.nix's own build, on the optimize pin
  optimizeDispatch =
    (import ../../../lib/wasm.nix {
      pkgs = optimizePkgs;
      inherit (optimizePkgs) lib;
      nixWasmRustPath = inputs.nix-wasm-rust-optimize;
    }).dispatchModule;
in
{
  # keep repo tooling past GC: direnv shell, `nix fmt`, our flake input sources,
  # builtins.wasm plugins (eval needs them built)
  system.extraDependencies = [
    inputs.self.devShells.${system}.default.inputDerivation
    inputs.self.formatter.${system}
    optimizeDispatch
  ]
  ++ wasm.modules
  ++ lib.mapAttrsToList (_: i: i.outPath) (removeAttrs inputs [ "self" ]);
}
