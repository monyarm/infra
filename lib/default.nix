{
  pkgs,
  lib,
  system,
  mkOutOfStoreSymlink,
  config,
  # Separately-pinned pkgs for lib/optimize and lib/compressRom's actual
  # tool invocations -- see optimize-nixpkgs in flake.nix and
  # hosts/modules/lib.nix's construction of this. Everything else in this
  # file keeps using the ambient `pkgs` above. Defaults to the ambient pkgs
  # for callers that don't care about the pin distinction (e.g.
  # packages/default.nix's own internal customLib, used only for unrelated
  # utility functions).
  optimizePkgs ? pkgs,
  # Overridable so lib/optimize/dynamic.nix's isolated inner evaluation
  # (inside a recursive-nix sandbox, no relative-path access to the repo
  # root) can supply this via a NIX_PATH-resolved value instead. Every other
  # caller keeps today's behavior unchanged.
  sources ? import ../sources.nix,
  # lib/wasm.nix's Cargo path dependency source -- see flake.nix's
  # nix-wasm-rust input. Optional/lazy: nothing forces wasm.crc32's
  # underlying derivation unless a caller actually uses it, so callers that
  # don't touch wasm.* (most of them) never need this.
  nixWasmRustPath ? null,
  ...
}:
let
  format = import ./format.nix ({ inherit pkgs lib wasm; } // strings);
  constants = import ./constants.nix { inherit lib; };
  nixSettings = import ./nixSettings.nix { inherit lib; };
  strings = import ./strings.nix ({ inherit pkgs lib; } // constants // misc);
  imp = import ./imports.nix ({ inherit pkgs lib; } // misc);
  files = import ./files.nix (
    {
      inherit
        pkgs
        lib
        mkOutOfStoreSymlink
        config
        ;
    }
    // strings
    // misc
  );
  media = import ./media.nix ({ inherit pkgs lib; } // strings // misc);
  meta = import ./meta.nix {
    inherit pkgs;
    inherit (pkgs) lib system;
  };
  fetchers = import ./fetchers.nix (
    { inherit pkgs sources; } // constants // strings // imp // files
  );
  optimize = import ./optimize (
    {
      pkgs = optimizePkgs;
      inherit (optimizePkgs) lib;
      inherit nixWasmRustPath;
    }
    // files
    // imp
    // strings
    // format
    // misc
  );
  scummvmOptimize = import ./scummvm-optimize.nix (
    {
      inherit pkgs;
      inherit (pkgs) lib;
    }
    // files
    // imp
    // strings
    // format
    // misc
    // optimize
  );
  compressRom = import ./compressRom (
    {
      inherit pkgs;
      inherit (pkgs) lib;
    }
    // files
    // imp
    // strings
    // format
    // misc
  );
  misc = import ./misc.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };
  wasm = import ./wasm.nix { inherit pkgs lib nixWasmRustPath; };
  all = {
    inherit
      format
      constants
      nixSettings
      strings
      imp
      files
      media
      meta
      fetchers
      optimize
      scummvmOptimize
      compressRom
      misc
      wasm
      ;
  }
  // format
  // constants
  // nixSettings
  // strings
  // imp
  // files
  // media
  // meta
  // fetchers
  // optimize
  // scummvmOptimize
  // compressRom
  // misc;
in
{
  customLib = all;
}
// all
