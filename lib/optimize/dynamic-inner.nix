# Fresh isolated `nix-instantiate` inside dynamic.nix's sandbox -- no
# shared state with the outer evaluator, only strings/paths via --argstr,
# so pkgs/lib get re-imported from scratch. One call handles the *whole*
# folder (not one call per file): pkgs only gets built once, and every
# file's result feeds one ordinary runCommand, so the resulting derivation
# graph is completely normal -- `nix build` parallelizes it like any other.
#
# pkgs is reconstructed with a minimal, direct overlay -- not
# lib/optimize/overlays.nix's full packages/default.nix machinery -- since
# that needs the *entire* lib/default.nix (fetchers.nix, sources.nix, ...)
# just to build wadptr/rpatool/minijson, which would otherwise make this expression's
# result depend on all of that too. toolPathsJSON's paths are already-built
# store paths, built outside this sandbox by dynamic.nix's own ambient pkgs
# (which already has them via the optimizePkgs overlay -- see
# hosts/modules/lib.nix), so no fetching/building of those happens here.
{
  optimizeNixpkgsPath,
  optimizeLibPath,
  # JSON attrset of prebuilt tool store paths (wadptr/rpatool/minijson/nix,
  # plus nixWasmRust which may be JSON null) -- see dynamic.nix's own
  # comment on toolPathsJSON for why this is one blob instead of one
  # --argstr per tool. `nix` (Determinate, not stock pkgs.nix) is needed
  # here -- not just by dynamic.nix's own outer builder script -- because a
  # nested archive inside this folder recurses back through
  # optimizeFolderDynamic -> dynamic.nix, and that nested dynamic.nix reads
  # pkgs.nix from *this* reconstructed pkgs -- without this override it'd
  # fall back to stock nixpkgs nix, which doesn't support parallel-eval /
  # builtins.parallel (misc.nix's `parallel`), unlike Determinate Nix.
  toolPathsJSON,
  targetSystem,
  # The folder's own store path (already realized on disk by the time this
  # runs -- dynamic.nix's build script only invokes us after extraction).
  folderSrc,
  prime,
  primeOverrideJSON,
  # Space-separated extensions to drop entirely, matching the `case` glob
  # dynamic.nix's old bash loop used to do -- "" means keep everything.
  droppedExtensions ? "",
}:
let
  # { wadptr, rpatool, minijson, nix, nixWasmRust (maybe null) } -- see
  # dynamic.nix's toolPathsJSON comment.
  toolPaths = builtins.fromJSON toolPathsJSON;
  pkgs = import optimizeNixpkgsPath {
    system = targetSystem;
    config.allowUnfree = true;
    overlays = [
      (_final: _prev: builtins.mapAttrs (_: builtins.storePath) (removeAttrs toolPaths [ "nixWasmRust" ]))
    ];
  };
  inherit (pkgs) lib;
  misc = import (optimizeLibPath + "/misc.nix") {
    inherit pkgs;
    inherit (pkgs) lib;
  };
  strings = import (optimizeLibPath + "/strings.nix") (
    { inherit pkgs lib; } // import (optimizeLibPath + "/constants.nix") { inherit lib; } // misc
  );
  files = import (optimizeLibPath + "/files.nix") (
    {
      inherit pkgs lib;
      mkOutOfStoreSymlink = _x: { };
      config = { };
    }
    // strings
    // misc
  );
  customLib = import (optimizeLibPath + "/optimize") (
    {
      inherit pkgs lib;
      nixWasmRustPath =
        if toolPaths.nixWasmRust == null then null else builtins.storePath toolPaths.nixWasmRust;
    }
    // files
    // strings
    // misc
  );
  inherit (strings) sanitizeName;

  primeOverride = builtins.fromJSON primeOverrideJSON;
  folderSrcPath = builtins.storePath folderSrc;

  droppedExts = lib.filter (s: s != "") (lib.splitString " " droppedExtensions);
  isDropped =
    relpath:
    let
      lower = lib.toLower relpath;
    in
    lib.any (ext: lib.hasSuffix ".${lib.toLower ext}" lower) droppedExts;

  # Recursively enumerate folderSrcPath *at eval time* -- safe here (unlike
  # at the outer flake's own eval) because by the time this expression runs,
  # the folder is a real, already-extracted directory on disk, not a future
  # build output whose contents are still unknown.
  walk =
    relBase:
    let
      dir = if relBase == "" then folderSrcPath else folderSrcPath + "/${relBase}";
      entries = builtins.readDir dir;
    in
    lib.concatLists (
      lib.mapAttrsToList (
        name: type:
        let
          rel = if relBase == "" then name else "${relBase}/${name}";
        in
        if type == "directory" then
          walk rel
        else if type == "regular" then
          [ rel ]
        else
          [ ]
      ) entries
    );
  keptRelPaths = lib.filter (p: !(isDropped p)) (walk "");

  # builtins.path hashes on (name, content) only -- the same scheme
  # nix-store --add uses -- so an unchanged file keeps the same store path
  # across archive updates regardless of its siblings, and Nix skips
  # rebuilding it. No subprocess needed, unlike the old per-file loop.
  processOne =
    relpath:
    let
      base = sanitizeName (baseNameOf relpath);
      added = builtins.path {
        path = folderSrcPath + "/${relpath}";
        name = base;
      };
      result = customLib.optimizeWith {
        inherit prime primeOverride;
        knownFile = true;
      } added;
      # rename returns `src` unchanged (not a derivation) on passthrough;
      # the copy step below needs a real derivation -- never stdenv.
      finalResult =
        if lib.isDerivation result then
          result
        else
          derivation {
            name = base;
            system = pkgs.stdenv.hostPlatform.system;
            builder = "${pkgs.bash}/bin/bash";
            args = [
              "-c"
              # flat-hash-mode outputs must be non-executable regular files --
              # `cp` alone preserves the source's mode bit, which breaks on
              # any executable passthrough file (e.g. a game's own .exe/.z5).
              ''
                ${pkgs.coreutils}/bin/cp "${result}" "$out"
                ${pkgs.coreutils}/bin/chmod -x "$out"
              ''
            ];
            __contentAddressed = true;
            outputHashAlgo = "sha256";
            outputHashMode = "flat";
          };
    in
    {
      inherit relpath;
      # knownFile suppresses optimizeWith's own trace, so check isUnhandledExt directly.
      result =
        if customLib.isUnhandledExt (baseNameOf relpath) then
          builtins.trace ''optimize: no optimizer for extension "${customLib.extOf (baseNameOf relpath)}"'' finalResult
        else
          finalResult;
    };

  fileResults = misc.parallel (map processOne) keptRelPaths;

  # $out/ prefix is a bare (unescaped) shell expansion; escapeShellArg only
  # covers the relpath -- concatenated with no space, forming one shell word.
  copyScript = lib.concatMapStrings (
    f:
    let
      escapedRel = lib.escapeShellArg f.relpath;
    in
    ''
      mkdir -p -- "$(dirname -- "$out/"${escapedRel})"
      cp -- "${f.result}" "$out/"${escapedRel}
    ''
  ) fileResults;
in
pkgs.runCommand "optimized-dir"
  {
    __contentAddressed = true;
    allowSubstitutes = false;
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  }
  (
    ''
      mkdir -p "$out"
    ''
    + copyScript
  )
