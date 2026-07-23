{ pkgs, user, ... }:
{
  users.users.${user.name}.shell = pkgs.zsh;
  programs.zsh.enable = true;
  environment.systemPackages = with pkgs; [
    zsh
    bat
    tree
  ];
}
