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
    # stylix's own palette from wall.jpg, frozen: generating it is an IFD
    # over a Haskell build every eval. Regenerate if wall.jpg changes.
    base16Scheme = builtins.fromJSON (builtins.readFile ./palette.json);
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
