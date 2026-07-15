{
  pkgs,
  lib,
  isNixOS,
  isHomeManager,
  inputs,
  ...
}:
let
  nix = with pkgs; [
    # keep-sorted start
    dconf2nix
    hyperfine
    inputs.determinate-nix.packages."x86_64-linux".nix
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
