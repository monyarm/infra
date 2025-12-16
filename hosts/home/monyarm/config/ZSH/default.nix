{ config, lib, ... }:
{
  imports = [
    ./env.nix
    ./paths.nix
    ./devkitpro.nix
    ./files.nix
    ./alias.nix
    ./nognu.nix
    ./plugins.nix
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    history = {
      size = 10000;
      save = 10000;
    };
    autocd = true;
    setOptions = [
      "nomatch"
      "hist_fcntl_lock"
    ];
    defaultKeymap = "emacs";
    completionInit = ''
      autoload -Uz compinit promptinit
      compinit
      promptinit; prompt powerlevel10k
    '';
    initContent = lib.mkMerge [
      (lib.mkOrder 600 ''
        [ -s "$NVM_SOURCE/nvm.sh" ] && . "$NVM_SOURCE/nvm.sh"
        ###-tns-completion-start-###
        if [ -f $HOME/.tnsrc ]; then
            source $HOME/.tnsrc
        fi
        ###-tns-completion-end-###
        if [ -f /usr/share/nvm/init-nvm.sh ]; then
            source /usr/share/nvm/init-nvm.sh
        fi
        eval "$(direnv hook zsh)"
      '')
      (lib.mkOrder 1000 ''
        if stat -t /etc/profile.d/java*.sh >/dev/null 2>&1
        then
            source /etc/profile.d/java*.sh
        fi
        # Nix
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
          . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi
      '')
    ];
  };
}
