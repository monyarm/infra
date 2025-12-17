{ pkgs, ... }:
let
  boson-bin = pkgs.callPackage ./boson.nix { };
in
{
  programs.steam = {
    enable = true;
    protontricks.enable = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
      boson-bin
    ];
  };
}
