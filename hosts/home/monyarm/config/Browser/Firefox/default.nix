{ bookmarks, ... }:
{
  imports = [
    ./userChrome.nix
    ./policies.nix
    ./settings.nix
    ./search.nix
  ];

  stylix.targets.firefox = {
    profileNames = [ "default" ];
    firefoxGnomeTheme.enable = true;
    # colorTheme.enable = true;
  };

  programs.firefox = {
    enable = true;
    # Keep legacy location for now; migrate to XDG config path later.
    configPath = ".mozilla/firefox";
    profileVersion = null; # fixes profile on non-NixOS systems
    profiles = {
      default = {
        id = 0;
        name = "Default User";
        path = "default";
        isDefault = true;

        # Shared with Chromium -- see ../data/bookmarks.nix
        bookmarks = {
          force = true;
          settings = bookmarks.all;
        };
      };
    };
  };
}
