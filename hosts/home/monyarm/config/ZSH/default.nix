{ dirs, ... }:
{

  home.shell.enableZshIntegration = true;
  home.shell.enableBashIntegration = true;
  imports = [
    ./alias.nix
    ./nognu.nix
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    dotDir = "${dirs.HOME}/.config/zsh";
    history.size = 10000;
  };
}
