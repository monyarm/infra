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
    dotnet-sdk_8
    hyperfine
    inputs.determinate-nix.packages."x86_64-linux".nix
    nh
    nix-output-monitor
    nix-prefetch
    nix-rom
    nixd
    #nix-relatex
    nixfmt
    nurl
    rust-analyzer
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
