{
  pkgs,
  lib,
  system,
  mkOutOfStoreSymlink,
  config,
  # Separately-pinned pkgs for files/media/optimize/compressRom's actual
  # tool invocations -- see optimize-nixpkgs in flake.nix and
  # hosts/modules/lib.nix's construction of this. Required, not defaulted:
  # callers that don't care about the pin (e.g. packages/default.nix's
  # internal customLib) must say so explicitly by passing `pkgs` here too.
  optimizePkgs,
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
  # niccup's system-independent `lib` output (github:embedding-shapes/niccup)
  # -- see flake.nix's niccup input. Optional/lazy like nixWasmRustPath above.
  niccupLib ? null,
  ...
}:
let
  format = import ./format.nix ({ inherit pkgs lib wasm; } // strings);
  constants = import ./constants.nix { inherit lib; };
  math = import ./math.nix { inherit lib; };
  nixSettings = import ./nixSettings.nix ({ inherit lib; } // math);
  strings = import ./strings.nix ({ inherit pkgs lib; } // constants // misc);
  imp = import ./imports.nix ({ inherit pkgs lib; } // misc);
  # optimizePkgs, not ambient pkgs: files.nix's functions (getFile, getFiles,
  # removeFiles, packArchive, derefSymlinks, rename, patchFile, ...) are all
  # file conversion/copying/compression tool invocations (p7zip, rpatool,
  # ...), so they always run through the pin -- regardless of whether the
  # caller is a game def (ScummVM/Doom) or the optimize/compressRom chains.
  files = import ./files.nix (
    {
      pkgs = optimizePkgs;
      inherit (optimizePkgs) lib;
      inherit mkOutOfStoreSymlink config;
    }
    // strings
    // misc
  );
  # optimizePkgs, not ambient pkgs: media.nix's tool invocations (imagemagick,
  # ffmpeg-headless) get the same pin as files.nix above.
  media = import ./media.nix (
    {
      pkgs = optimizePkgs;
      inherit (optimizePkgs) lib;
    }
    // strings
    // misc
  );
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
      pkgs = optimizePkgs;
      inherit (optimizePkgs) lib;
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
      pkgs = optimizePkgs;
      inherit (optimizePkgs) lib;
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
  niccup = niccupLib;
  all = {
    inherit
      format
      constants
      math
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
      niccup
      ;
  }
  // format
  // constants
  // math
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
