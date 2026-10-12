# Re-implementation of pspdev-nix's nix/packages/default.nix scope.
#
# Upstream builds its scope as `pkgs // packages`, and toolchain/default.nix
# instantiates psp-newlib through that scope. `packages` wins over `pkgs`, so
# every psp-newlib override is shadowed for the whole chain
# (pthread -> pspsdk -> sysroot -> gcc). Reaching the packages is the only way
# in without vendoring their repo.
#
# Kept structurally identical to upstream; only psp-newlib's src differs.
{ pkgs, pspdev }:

let
  nixDir = "${pspdev.outPath}/nix";

  callPackage = pkgs.lib.callPackageWith (
    pkgs
    // packages
    // {
      inherit pspMkDerivation pspMkLibraryDerivation;
    }
  );

  pspMkDerivation = callPackage "${nixDir}/psp-mk-derivation.nix" { };
  pspMkLibraryDerivation = callPackage "${nixDir}/psp-mk-library-derivation.nix" { };

  raw =
    import "${nixDir}/packages/toolchain" { inherit callPackage; }
    // import "${nixDir}/packages/build-tools" { inherit callPackage; }
    // import "${nixDir}/packages/libraries" { inherit callPackage; }
    // import "${nixDir}/packages/debug" { inherit callPackage; }
    // import "${nixDir}/packages/custom-firmware" { inherit callPackage; }
    // import "${nixDir}/packages/homebrew" { inherit callPackage; };

  packages = raw // {
    # Upstream fetches newlib by branch name: `rev = version`, version =
    # "allegrex-v4.5.0". Branch moved, recorded hash no longer matches.
    # Every other toolchain source pins a sha; this is the only one that does not.
    # Pin sha. Source stops drifting.
    psp-newlib = raw.psp-newlib.overrideAttrs (_: {
      src = pkgs.fetchFromGitHub {
        owner = "pspdev";
        repo = "newlib";
        rev = "09d1adaf18bdac953fc401deb3c04e41ae9ee510";
        hash = "sha256-heKqialblnuN01j1xWN/nOZRO3VxC2X/QL5IK319P4s=";
      };
    });
  };
in
packages
