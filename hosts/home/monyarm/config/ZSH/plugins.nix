{ lib, ... }:
let
  # Generate Oh-My-Zsh plugins with defer
  omzpDefer = lib.map (name: "OMZP::${name} kind:defer");

  # Generate Oh-My-Zsh completion plugins with defer
  omzpCompletions = lib.map (name: "OMZP::${name}");
in
{
  programs.zsh.antidote = {
    enable = true;
    plugins = [
      # git-related
      "OMZL::git.zsh"
      "OMZP::git atload:unalias grv"
    ]
    # Oh-My-Zsh plugins (deferred)
    ++ omzpDefer [
      "command-not-found"
      "encode64"
      "jsontools"
      "sudo"
      "vscode"
      "web-search"
    ]
    ++ [
      "OMZP::colored-man-pages"

      # Other Plugins
      "mafredri/zsh-async"
      "chrissicool/zsh-256color"
      "zpm-zsh/autoenv"
      "zpm-zsh/colors"
      "zpm-zsh/colorize"
      "zdharma-continuum/fast-syntax-highlighting kind:defer"
      "zsh-users/zsh-history-substring-search kind:defer"
      "mfaerevaag/wd kind:defer"
      "romkatv/powerlevel10k"
      "Aloxaf/fzf-tab kind:defer"

      # Programs
      "xvoland/Extract kind:defer"

      # Completions
      "zsh-users/zsh-completions"
    ]
    # Oh-My-Zsh completions
    ++ omzpCompletions [
      "compleat"
      "gradle"
      "pip"
      "python"
      "ruby"
      "vagrant"
    ]
    ++ [
      "lukechilds/zsh-better-npm-completion"
      "akoenig/gulp.plugin.zsh"
      "zsh-users/zsh-autosuggestions kind:defer"
    ];
    useFriendlyNames = false;
  };
}
