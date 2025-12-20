{ pkgs, ... }:

{
  imports = [
    ./base.nix
    ./nix.nix
  ];
  environment.systemPackages = with pkgs; [
    vscode
    obsidian
  ];
}
