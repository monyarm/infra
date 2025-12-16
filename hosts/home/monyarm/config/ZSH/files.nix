{ config, lib, ... }:
{
  home.file = {
    "${config.programs.zsh.dotDir}/.zprofile".source = ./.zprofile;
    "${config.programs.zsh.dotDir}/p10k.zsh".source = ./.p10k.zsh;
    ".controller_config".source = ./.controller_config;
  };

  home.shell.enableZshIntegration = true;
  home.shell.enableBashIntegration = true;

  programs.zsh.initContent = lib.mkOrder 550 ''
    source ~/.controller_config

    # Powerlevel10k prompt
    source "${config.programs.zsh.dotDir}/p10k.zsh"
    if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
      source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
    fi
    powerline-daemon -q
  '';
}
