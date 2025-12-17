{ ... }:
{
  imports = [
    ./userChrome.nix
    ./policies.nix
    ./settings.nix
    ./bookmarks.nix
    ./search.nix
  ];

  stylix.targets.firefox = {
    profileNames = [ "default" ];
    firefoxGnomeTheme.enable = true;
    # colorTheme.enable = true;
  };

  programs.firefox = {
    enable = true;
    profileVersion = null; # fixes profile on non-NixOS systems
    profiles = {
      default = {
        id = 0;
        name = "Default User";
        path = "default";
        isDefault = true;
      };
    };
  };
}
