# Desktop GUI applications. Home-manager only -- not for the server host.
{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    feh
    geeqie
    # Driven by Flatpak.nix's activation script.
    flatpak
    nemo
    scrcpy
    transmission_4
    winetricks
    wine
    wtype
  ];
}
