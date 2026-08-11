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
  # packages/minijson.nix's drowse.instantiate step. Only the outer
  # (hosts/modules/lib.nix) call site needs this -- dynamic-inner.nix's own
  # sandbox never builds minijson itself, it receives an already-built
  # minijsonPath the same way it already does for wadptr/rpatool.
  drowseSrc,
}:
[
  (
    final: prev:
    import packagesPath {
      pkgs = final;
      inherit (prev) lib;
      inherit sources libPath drowseSrc;
    }
  )
  (_final: _prev: { nix = determinateNix; })
]
