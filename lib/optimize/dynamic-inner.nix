# Fresh isolated `nix-instantiate` inside dynamic.nix's sandbox -- no
# shared state with the outer evaluator, only strings/paths via --argstr,
# so pkgs/lib get re-imported from scratch.
#
# `src`: its own store path (`nix-store --add`ed by dynamic.nix), not an
# archive subpath -- keeps unchanged files at the same hash across archive
# updates, so Nix skips rebuilding them.
{
  optimizeNixpkgsPath,
  optimizeLibPath,
  optimizePackagesPath,
  sourcesPath,
  determinateNixPath,
  # "" sentinel for null, see dynamic.nix's nixWasmRustPathArg.
  nixWasmRustPath ? "",
  targetSystem,
  src,
  prime,
  primeOverrideJSON,
}:
let
  sources = import sourcesPath;
  pkgs = import optimizeNixpkgsPath {
    system = targetSystem;
    config.allowUnfree = true;
    overlays = import (optimizeLibPath + "/optimize/overlays.nix") {
      inherit sources;
      packagesPath = optimizePackagesPath;
      libPath = optimizeLibPath;
      determinateNix = builtins.storePath determinateNixPath;
    };
  };
  lib = pkgs.lib;
  # Runs once per file, thousands of times per pk3 -- wire up only the
  # modules optimizeWith needs, not all of lib/default.nix.
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
      nixWasmRustPath = if nixWasmRustPath == "" then null else builtins.storePath nixWasmRustPath;
    }
    // files
    // strings
    // misc
  );
  primeOverride = builtins.fromJSON primeOverrideJSON;
  srcPath = builtins.storePath src;
  result = customLib.optimizeWith {
    inherit prime primeOverride;
    knownFile = true;
  } srcPath;
  # rename returns `src` unchanged (not a derivation) on passthrough;
  # nix-instantiate needs a real derivation, so wrap it -- never stdenv.
  finalResult =
    if pkgs.lib.isDerivation result then
      result
    else
      derivation {
        name = baseNameOf src;
        system = pkgs.stdenv.hostPlatform.system;
        builder = "${pkgs.bash}/bin/bash";
        args = [
          "-c"
          ''${pkgs.coreutils}/bin/cp "${result}" "$out"''
        ];
        __contentAddressed = true;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      };
in
# knownFile suppresses optimizeWith's own trace, so check isUnhandledExt directly.
if customLib.isUnhandledExt (baseNameOf src) then
  builtins.trace ''optimize: no optimizer for extension "${customLib.extOf (baseNameOf src)}"'' finalResult
else
  finalResult
