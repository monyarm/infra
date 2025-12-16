{
  pkgs,
  lib,
  isNixOS,
  isHomeManager,
  ...
}:

let
  basePackages = with pkgs; [
    # keep-sorted start
    dconf2nix
    nh
    nix
    nix-output-monitor
    #nix-relatex
    nixfmt
    # keep-sorted end
  ];
in
lib.mkMerge [
  # For NixOS
  (lib.optionalAttrs isNixOS {
    environment.systemPackages = basePackages;
  })

  # For home-manager
  (lib.optionalAttrs isHomeManager {
    home.packages = basePackages;
  })
]
