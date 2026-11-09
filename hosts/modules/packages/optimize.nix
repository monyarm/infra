# Build-time tools the game pipeline needs but no output references, so GC
# eats them and the next build refetches/rebuilds. Rooted via a file in the
# HM generation, not on PATH: the optimize pin's coreutils etc. would clash
# with the system's in a buildEnv. HM side: optimizePkgs/customLib are
# already built here; forcing them from NixOS evaluated them a second time.
{
  pkgs,
  lib,
  inputs,
  optimizePkgs,
  optimizeDynamicParts,
  wasm,
  ...
}:
let
  # doom + no fileList = every handler tool real, no dummies; the JSON's
  # string context is the whole tool set (incl. determinate nix, dispatch wasm)
  inherit ((optimizeDynamicParts { prime = false; } { passthru.isDoom = true; })) toolPathsJSON;
  optimizeTools = pkgs.writeText "optimize-tools.json" toolPathsJSON;
  # names only; their pinned builds are rooted via optimizeTools
  optimizeToolNames = lib.attrNames (
    builtins.fromJSON (builtins.unsafeDiscardStringContext toolPathsJSON)
  );

  # lib/optimize/dynamic.nix's own build, on the optimize pin
  optimizeDispatch =
    (import ../../../lib/wasm.nix {
      pkgs = optimizePkgs;
      inherit (optimizePkgs) lib;
      nixWasmRustPath = inputs.nix-wasm-rust-optimize;
    }).dispatchModule;

  # every `pkgs.<name>` in these sources that is a real derivation of pkgSet
  scanRefs =
    pkgSet: paths:
    let
      files = lib.concatMap (
        p: if lib.pathIsDirectory p then lib.filesystem.listFilesRecursive p else [ p ]
      ) paths;
      names = lib.unique (
        lib.concatMap (
          f:
          map lib.head (
            lib.filter lib.isList (builtins.split "pkgs\\.([A-Za-z0-9_-]+)" (builtins.readFile f))
          )
        ) (lib.filter (lib.hasSuffix ".nix") files)
      );
      isDrv = n: (builtins.tryEval (pkgSet ? ${n} && lib.isDerivation pkgSet.${n})).value;
    in
    map (n: pkgSet.${n}) (lib.filter isDrv names);

  # lib parts built on the optimize pin (see lib/default.nix)
  optimizePinRefs = scanRefs optimizePkgs [
    ../../../lib/optimize
    ../../../lib/rom
    ../../../lib/media.nix
    ../../../lib/files.nix
    ../../../lib/scummvm-optimize.nix
    ../../../lib/test.nix
  ];

  # fetchers run on ambient pkgs
  fetcherRefs = scanRefs pkgs [
    ../../../lib/fetchers
    ../../../lib/fetchers.nix
  ];

  # all of packages/ (game extractors, fetch helpers, scan tools), minus the
  # optimize tools: system-pin copies of those are never used. Names from
  # the dir itself, same rule as packages/default.nix -- going through
  # inputs.self.packages forced the flake's perSystem nixpkgs.
  packageNames = lib.mapAttrsToList (n: _: lib.removeSuffix ".nix" n) (
    lib.filterAttrs (n: t: n != "default.nix" && (t == "directory" || lib.hasSuffix ".nix" n)) (
      builtins.readDir ../../../packages
    )
  );
  localPackages = lib.filter lib.isDerivation (
    map (n: pkgs.${n} or null) (lib.subtractLists optimizeToolNames packageNames)
  );

  roots = [
    optimizeTools
    optimizeDispatch
  ]
  # builtins.wasm plugins: eval needs them built
  ++ wasm.modules
  ++ optimizePinRefs
  ++ fetcherRefs
  ++ localPackages;
in
{
  xdg.dataFile."nix-roots/optimize".text = lib.concatMapStrings (p: "${p}\n") roots;
}
