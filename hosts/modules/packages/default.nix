{ pkgs, ... }:

{
  # NixOS-level lists only. The user-only package files (dev/media/apps/games)
  # are registered in hosts/default.nix's homeManagerModules instead -- a
  # module imported HERE runs in the NixOS context where isHomeManager is false,
  # so `home.packages` in this tree would never fire.
  imports = [
    ./base.nix
    ./nix.nix
  ];
  environment.systemPackages = with pkgs; [
    vscode
    obsidian
  ];
}
