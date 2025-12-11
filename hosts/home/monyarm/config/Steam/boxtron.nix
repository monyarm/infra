{ lib, ... }:

{
  xdg.configFile."boxtron.conf".text = lib.generators.toINI { } {
    confgen = {
      # Set this value to 'true' if you want Boxtron to re-create DOSBox
      # configuration on every run.
      force = false;
    };
    midi = {
      # You can disable MIDI support here.
      enable = true;

      # Select preferred software synthesiser here.
      # Can be either 'timidity' or 'fluidsynth'
      synthesiser = "timidity";

      # Boxtron will look for a soundfont in following directories:
      # /usr/share/soundfonts/
      # /usr/share/sounds/sf2/
      # /usr/local/share/soundfonts/
      # /usr/local/share/sounds/sf2/
      # ~/.local/share/sounds/sf2/  (or wherever XDG_DATA_HOME points)
      # ~/.local/share/soundfonts/  (or wherever XDG_DATA_HOME points)
      soundfont = "FluidR3_GM.sf2";
    };
    dosbox = {
      # Available modes:
      # - screen 0, screen 1, etc:
      #   The game will use fullscreen on selected screen, without changing
      #   the native resolution of your display.  Mouse will be locked to the screen.
      #   Default is 'screen 0', which is your primary display.
      #   You can override this selection per-game with BOXTRON_SCREEN environment
      #   variable, e.g: 'BOXTRON_SCREEN=2 %command%'
      # - desktop:
      #   The whole desktop area will be used (all displays) with the game centred,
      #   the native resolution of your displays will be preserved.
      # - disabled:
      #   Start DOSBox in windowed modeby default.
      fullscreenmode = "screen 0";

      # Pick the default scaler, that you want to use for all games.
      # You can override selection per-game by changing option render.scaler in file
      # boxtron_<appid>_<id>.conf in game's installation dir.
      # Here's comparison of different scalers: https://www.dosbox.com/wiki/Scaler
      scaler = "normal3x";

      # Uncomment following line to specify a different DOSBox build:
      cmd = "/usr/bin/dosbox";
    };
  };
}
