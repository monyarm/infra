{
  pkgs,
  lib,
  isNixOS,
  isHomeManager,
  ...
}:
let
  nix = with pkgs; [
    # keep-sorted start
    dconf2nix
    lix
    nh
    nix-output-monitor
    nix-prefetch
    #nix-relatex
    nixfmt
    nurl
    # keep-sorted end
  ];
in
lib.mkMerge [
  # For NixOS
  (lib.optionalAttrs isNixOS {
    environment.systemPackages = nix;
  })

  # For home-manager
  (lib.optionalAttrs isHomeManager {
    home.packages = nix;
  })
]
