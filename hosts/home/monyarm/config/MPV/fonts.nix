# config/MPV/fonts.nix
{
  ulyssescaballes-mpv-config,
  uosc,
  ...
}:

{
  xdg.configFile = {
    # keep-sorted start
    # Fonts from ulyssescaballes-mpv-config
    "mpv/fonts/DynaPuff SemiBold.ttf".source =
      "${ulyssescaballes-mpv-config}/fonts/DynaPuff SemiBold.ttf";
    "mpv/fonts/Futura PT Medium.otf".source =
      "${ulyssescaballes-mpv-config}/fonts/Futura PT Medium.otf";
    "mpv/fonts/Neuton.ttf".source = "${ulyssescaballes-mpv-config}/fonts/Neuton.ttf";
    "mpv/fonts/O Sans Medium.ttf".source = "${ulyssescaballes-mpv-config}/fonts/O Sans Medium.otf";
    "mpv/fonts/Roboto.ttf".source = "${ulyssescaballes-mpv-config}/fonts/Roboto.ttf";
    "mpv/fonts/RolandBecker.ttf".source = "${ulyssescaballes-mpv-config}/fonts/RolandBecker.ttf";
    "mpv/fonts/Squidgy Sweets.ttf".source = "${ulyssescaballes-mpv-config}/fonts/Squidgy Sweets.ttf";
    # keep-sorted end
    # keep-sorted start
    # uosc fonts
    "mpv/fonts/uosc_icons.otf".source = "${uosc.src}/src/fonts/uosc_icons.otf";
    "mpv/fonts/uosc_textures.ttf".source = "${uosc.src}/src/fonts/uosc_textures.ttf";
    # keep-sorted end
  };
}
