_:

{
  programs.rofi = {
    enable = true;
    # font = "hack 10";
    # theme = "solarized";
    extraConfig = {
      "combi-modi" = "window,drun,ssh";
      "modi" = "combi";
    };
  };
}
