# Shared overlay stack for optimize-nixpkgs -- used by both
# hosts/modules/lib.nix's optimizePkgs and dynamic.nix's sandbox
# reconstruction, kept in one place so they stay identical.
#
# Only the local packages overlay (wadptr, scummvm-tools); everything else
# used is stock nixpkgs. No NUR currently.
{
  sources,
  # Overridable: the sandbox only has lib/ on disk, no repo root.
  packagesPath ? ../../packages,
  libPath ? ../.,
  # Determinate Nix, not pkgs.nix -- required for dynamic.nix's `nix
  # derivation add` JSON schema (differs from stock nix 2.31.5's).
  determinateNix,
  # packages/maxima-cli.nix's craneLib.buildPackage -- without this the
  # self-referential `packages` overlay below builds maxima-cli with
  # craneLib = null (packages/default.nix's default) and crashes.
  craneLib,
}:
[
  (
    final: prev:
    import packagesPath {
      pkgs = final;
      inherit (prev) lib;
      inherit
        sources
        libPath
        craneLib
        ;
    }
  )
  (_final: _prev: { nix = determinateNix; })
]
