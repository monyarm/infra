{
  pkgs,
  lib,
  options,
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
  (lib.optionalAttrs (options ? environment) {
    environment.systemPackages = basePackages;
  })

  # For home-manager
  (lib.optionalAttrs (options ? home) {
    home.packages = basePackages;
  })
]
