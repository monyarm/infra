{ pkgs, user, ... }:
{
  users.users.${user.name}.shell = pkgs.zsh;
  programs.zsh.enable = true;
  # bat/tree live in packages/base.nix; cargo in packages/dev.nix.
  environment.systemPackages = with pkgs; [
    zsh
    nix-prefetch-git
  ];
}
