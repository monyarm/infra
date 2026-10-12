# PSP toolchain overlay. Separate from the NixOS/Home Manager overlay list so
# console eval stays independent of those hosts.
{ inputs }:

let
  # Upstream's own scope, recomputed so psp-newlib's src can be pinned.
  # Must come after their overlay so it wins.
  pspScope =
    final: _prev:
    import ./psp/scope.nix {
      pkgs = final;
      pspdev = inputs.pspdev-nix;
    };
in
[
  inputs.pspdev-nix.overlays.default
  pspScope
]
