# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ dirs, ... }:

{
  imports = [
    "${dirs.modules}/base"
    "${dirs.modules}/misc"
    "${dirs.modules}/packages"
    "${dirs.modules}/services"
    "${dirs.modules}/services/tailscale.nix"
    "${dirs.modules}/services/syncthing.nix"
    "${dirs.modules}/programs/steam"
    "${dirs.modules}/programs/shell.nix"
    "${dirs.modules}/config/doas.nix"
  ];

  networking.networkmanager.enable = true;
  system.stateVersion = "24.11";

}
