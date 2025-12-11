{ ... }:
{
  imports = [ ./userChrome.nix ];

  stylix.targets.firefox = {
    profileNames = [ "default" ];
    firefoxGnomeTheme.enable = true;
    #colorTheme.enable = true; Disabled until I can figure out how to fully manage my extensions and settings without depending on version in nixpkgs and NUR
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
