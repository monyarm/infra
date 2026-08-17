# Fresh isolated `nix-instantiate` inside dynamic.nix's sandbox -- no shared
# state with the outer evaluator, only strings/paths via --argstr. One call
# handles the whole folder, not one call per file, so the resulting
# derivation graph stays normal and `nix build` parallelizes it.
#
# pkgs is reconstructed with a minimal, direct overlay, not
# lib/optimize/overlays.nix's full packages/default.nix machinery, since
# that needs all of lib/default.nix just to build wadptr/rpatool/minijson.
# toolPathsJSON's paths are already-built store paths from dynamic.nix's
# own ambient pkgs (optimizePkgs overlay, hosts/modules/lib.nix), so
# nothing gets fetched/built in here.
{
  optimizeNixpkgsPath,
  optimizeLibPath,
  # JSON attrset of prebuilt tool store paths (wadptr/rpatool/minijson/nix,
  # plus nixWasmRust which may be JSON null) -- see dynamic.nix's
  # toolPathsJSON comment. `nix` here must be Determinate: a nested archive
  # recurses through optimizeFolderDynamic -> dynamic.nix, which reads
  # pkgs.nix from *this* reconstructed pkgs, and stock nixpkgs nix doesn't
  # support builtins.parallel (misc.nix's `parallel`).
  toolPathsJSON,
  targetSystem,
  # The folder's own store path (already realized on disk by the time this
  # runs -- dynamic.nix's build script only invokes us after extraction).
  folderSrc,
  prime,
  # True only while walking a pk3-family archive's extracted contents (see
  # archive.nix's `passthru.isDoom` tagging and dynamic.nix's own `doom`).
  doom ? false,
  # Space-separated extensions to drop entirely; "" means keep everything.
  droppedExtensions ? "",
}:
let
  toolPaths = builtins.fromJSON toolPathsJSON;
  pkgs = import optimizeNixpkgsPath {
    system = targetSystem;
    config.allowUnfree = true;
    overlays = [
      (
        _final: _prev:
        builtins.mapAttrs (_: builtins.storePath) (
          removeAttrs toolPaths [
            "nixWasmRust"
            "dispatchWasm"
          ]
        )
      )
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
      dispatchWasmPath = "${builtins.storePath toolPaths.dispatchWasm}/nix_wasm_plugin_dispatch.wasm";
      # Same store path, undereferenced -- threaded into a nested
      # optimizeFolderDynamic call (recursive archive) so it reuses this
      # already-built module instead of rebuilding from ../wasm.nix source,
      # which isn't even present in this sandbox's trimmed lib copy.
      dispatchWasmDir = builtins.storePath toolPaths.dispatchWasm;
    }
    // files
    // strings
    // misc
  );
  inherit (strings) sanitizeName;

  folderSrcPath = builtins.storePath folderSrc;

  # Lowercased once here, not per-file inside isDropped.
  droppedExtsLower = map (ext: ".${lib.toLower ext}") (
    lib.filter (s: s != "") (lib.splitString " " droppedExtensions)
  );
  isDropped =
    relpath:
    let
      lower = lib.toLower relpath;
    in
    lib.any (suffix: lib.hasSuffix suffix lower) droppedExtsLower;

  # Recursively enumerate folderSrcPath at eval time -- safe here, unlike
  # at the outer flake's eval, because the folder is already extracted to
  # disk by the time this expression runs.
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
        else if type == "regular" || type == "symlink" then
          [ rel ]
        else
          [ ]
      ) entries
    );
  keptRelPaths = lib.filter (p: !(isDropped p)) (walk "");

  # One batched wasm call resolves every kept file's dispatch handler up
  # front, instead of each processOne call resolving its own live. Keyed
  # by base (sanitized basename), not relpath -- dispatch resolution is a
  # pure function of the basename alone, so files sharing a basename
  # across subdirectories correctly share one lookup.
  keptBases = map (relpath: sanitizeName (baseNameOf relpath)) keptRelPaths;
  batchResults = customLib.batchResolveDispatch { inherit prime doom; } keptBases;

  # builtins.path hashes on (name, content) only, so an unchanged file
  # keeps the same store path across archive updates regardless of its
  # siblings, and Nix skips rebuilding it.
  processOne =
    relpath:
    let
      base = sanitizeName (baseNameOf relpath);
      added = builtins.path {
        path = folderSrcPath + "/${relpath}";
        name = base;
      };
      result = customLib.optimizeWith {
        inherit prime doom;
        knownFile = true;
        knownName = base;
        knownHandler = batchResults.${base};
      } added;
      finalResult = result;
    in
    {
      inherit relpath;
      result = finalResult;
    };

  # builtins.parallel only WHNF-forces this list, which doesn't touch
  # .result's own lazy value -- forced explicitly here so the real
  # per-file work doesn't stay deferred until copyScript reads it later,
  # single-threaded. toString (not deepSeq): forces only what copyScript's
  # "${f.result}" interpolation needs; deepSeq would stack-overflow on
  # self-referential attrs some stdenv derivations carry.
  fileResults = misc.parallel (map (
    relpath:
    let
      r = processOne relpath;
    in
    builtins.seq (builtins.toString r.result) r
  )) keptRelPaths;

  coreutilsBin = "${pkgs.coreutils}/bin";
  # One JSON blob (passAsFile'd -- can't embed thousands of interpolated
  # store paths straight into `args`, execve's ARG_MAX blows up) instead of
  # one mkdir+cp shell line per file -- both the .drv text and the number
  # of forked processes used to scale with file count.
  pairsJSON = builtins.toJSON (
    map (f: {
      src = "${f.result}";
      dest = f.relpath;
    }) fileResults
  );
in
derivation {
  name = "optimized-dir";
  system = targetSystem;
  builder = "${pkgs.bash}/bin/bash";
  args = [
    "-c"
    ''
      set -eo pipefail
      ${coreutilsBin}/mkdir -p "$out"
      cores=$(( NIX_BUILD_CORES > 0 && NIX_BUILD_CORES < 8 ? NIX_BUILD_CORES : 8 ))
      ${pkgs.jq}/bin/jq -j '.[] | .src, "\u0000", .dest, "\u0000"' "$pairsJSONPath" \
        | ${pkgs.findutils}/bin/xargs -0 -n2 -P"$cores" ${pkgs.bash}/bin/sh -c '
            dest="$out/$2"
            ${coreutilsBin}/mkdir -p -- "$(${coreutilsBin}/dirname -- "$dest")"
            ${coreutilsBin}/ln -s -- "$1" "$dest"
          ' _
    ''
  ];
  inherit pairsJSON;
  passAsFile = [ "pairsJSON" ];
  __contentAddressed = true;
  allowSubstitutes = false;
  preferLocalBuild = true;
  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  # __noChroot = true;
}
