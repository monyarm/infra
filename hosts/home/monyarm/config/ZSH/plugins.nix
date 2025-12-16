{ lib, ... }:
let
  # Generate Oh-My-Zsh plugins with defer
  OMZP = lib.map (name: "ohmyzsh/ohmyzsh path:plugins/${name} kind:defer");
in
{
  programs.zsh.antidote = {
    enable = true;
    plugins = [
      # git-related
      "getantidote/use-omz"
      "ohmyzsh/ohmyzsh path:lib"
      "ohmyzsh/ohmyzsh path:plugins/git"
    ]
    # Oh-My-Zsh plugins (deferred)
    ++ OMZP [
      "command-not-found"
      "encode64"
      "jsontools"
      "sudo"
      "vscode"
      "web-search"
    ]
    ++ [
      "ohmyzsh/ohmyzsh path:plugins/colored-man-pages"

      # Other Plugins
      "mafredri/zsh-async"
      "chrissicool/zsh-256color"
      "zpm-zsh/colors"
      "zpm-zsh/colorize"
      "zdharma-continuum/fast-syntax-highlighting kind:defer"
      "zsh-users/zsh-history-substring-search kind:defer"
      "mfaerevaag/wd kind:defer"
      "romkatv/powerlevel10k"
      "Aloxaf/fzf-tab kind:defer"

      # Completions
      "zsh-users/zsh-completions"
    ]
    # Oh-My-Zsh completions
    ++ OMZP [
      "compleat"
      "gradle"
      "pip"
      "python"
      "ruby"
      "vagrant"
    ]
    ++ [
      "lukechilds/zsh-better-npm-completion kind:defer"
      "akoenig/gulp.plugin.zsh kind:defer"
      "zsh-users/zsh-autosuggestions kind:defer"
    ];
    useFriendlyNames = false;
  };
}
