_: {

  programs.ghostty = {
    enable = true;
    #enableZshIntegration = true; # Handled by global enableZshIntegration
    installBatSyntax = true;
    installVimSyntax = true;
    settings = {
      #background-opacity = 0.65; Set by Stylix
      background-opacity-cells = true;
      faint-opacity = 0.65;
      cursor-opacity = 0.55;
      gtk-wide-tabs = false;
      gtk-toolbar-style = "flat";
      gtk-custom-css = "${./ghostty.css}";
    };
  };

}
