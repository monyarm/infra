_:

{
  programs.rofi = {
    enable = true;
    # font = "hack 10";
    # theme = "solarized";
    settings.modes = [
      "drun"
      "window"
      "ssh"
    ];
  };
  # `programs.rofi.font` rename warning comes from stylix; fix pending
  # https://github.com/nix-community/stylix/pull/2501
}
