# Build-time tools the game pipeline needs but no output references, so GC
# eats them and the next build refetches/rebuilds. Rooted, not on PATH: the
# optimize pin's coreutils etc. would clash with the system's in a buildEnv.
{
  pkgs,
  lib,
  inputs,
  optimizePkgs,
  optimizeDynamicParts,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;

  # doom + no fileList = every handler tool real, no dummies; the JSON's
  # string context is the whole tool set (incl. determinate nix, dispatch wasm)
  inherit ((optimizeDynamicParts { prime = false; } { passthru.isDoom = true; })) toolPathsJSON;
  optimizeTools = pkgs.writeText "optimize-tools.json" toolPathsJSON;
  # names only; their pinned builds are rooted via optimizeTools
  optimizeToolNames = lib.attrNames (
    builtins.fromJSON (builtins.unsafeDiscardStringContext toolPathsJSON)
  );

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
  # optimize tools: system-pin copies of those are never used
  localPackages = lib.filter (p: p != null) (
    map (n: pkgs.${n} or null) (
      lib.subtractLists optimizeToolNames (lib.attrNames inputs.self.packages.${system})
    )
  );
in
{
  system.extraDependencies = [
    optimizeTools
  ]
  ++ optimizePinRefs
  ++ fetcherRefs
  ++ localPackages;
}
