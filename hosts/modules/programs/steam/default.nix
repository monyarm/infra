{ pkgs, ... }:
let
  boson-bin = pkgs.callPackage ./boson.nix { };
in
{
  programs.steam = {
    enable = true;
    protontricks = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
      nur.repos.forkprince.boxtron-bin
      boson-bin
    ];
  };
}
