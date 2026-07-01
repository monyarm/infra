{
  config,
  lib,
  isHomeManager,
  isHomeManagerInNixOS,
  ...
}:
{
  home.file = {
    "${config.programs.zsh.dotDir}/p10k.zsh".source = ./.p10k.zsh;
    ".controller_config".source = ./.controller_config;
  };

  home.shell.enableZshIntegration = true;
  home.shell.enableBashIntegration = true;

  programs.zsh = {
    initContent = lib.mkOrder 550 ''
      source ~/.controller_config

      # Powerlevel10k prompt
      source "${config.programs.zsh.dotDir}/p10k.zsh"
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi
      powerline-daemon -q
    '';
    profileExtra = ''
      if [[ -o login ]]; then
        [[ -f ~/.bashrc ]] && source ~/.bashrc
    ''
    + lib.optionalString isHomeManagerInNixOS ''
      [[ -t 0 && $(tty) == /dev/tty1 && ! $DISPLAY ]] && exec $(which niri-session) -l > ~/niri.log 2>&1
    ''
    + lib.optionalString (isHomeManager && !isHomeManagerInNixOS) ''
      [[ -t 0 && $(tty) == /dev/tty1 && ! $DISPLAY ]] && exec dbus-run-session /usr/bin/niri --session > ~/niri.log 2>&1
    ''
    + ''
      fi
    '';
  };
}
