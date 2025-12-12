{
  programs.zsh.shellAliases = {
    sudo = "doas";
    ls = "eza --colour always --icons -a --group-directories-first";
    cat = "bat --paging=never";
    tree = "st";
  };
}
