{ pkgs, ... }:
{
  users.users.monyarm.shell = pkgs.zsh;
  programs.zsh.enable = true;
  environment.systemPackages = with pkgs; [
    zsh
    bat
    tree
  ];
}
