{
  config,
  pkgs,
  ...
}:
{
  stylix = {
    enable = true;
    polarity = "dark";
    opacity = {
      terminal = 0.65;
      desktop = 0.80;
      popups = 0.85;
      applications = 0.95;
    };
    image = ./wall.jpg;
    cursor = {
      name = "macOS";
      package = pkgs.apple-cursor;
      size = 24;
    };
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.fira-code;
        name = "FiraCode Nerd Font Mono";
      };
      serif = config.stylix.fonts.monospace;
      sansSerif = config.stylix.fonts.monospace;
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };
  };
}
