{ lib, ... }:

{
  xdg.configFile."roberta.conf".text = lib.generators.toINI { } {
    confgen = {
      # Set this value to 'true' if you want Roberta to re-create ScummVM
      # configuration on every run.
      force = false;
    };
    scummvm = {
      # Available modes:
      # - screen 0, screen 1, etc:
      #   The game will use fullscreen on selected screen, without changing
      #   the native resolution of your display.  Mouse will be locked to the screen.
      #   Default is 'screen 0', which is your primary display.
      #   You can override this selection per-game with LUX_USE_SCREEN environment
      #   variable, e.g: 'LUXTRON_SCREEN=2 %command%'
      # - default:
      #   Roberta will not attempt to affect the default ScummVM behaviour.
      #   ScummVM uses windowed mode by default; it can be changed in ScummVM
      #   options per-game.
      fullscreenmode = "screen 0";

      # Uncomment following line to specify a different ScummVM command:
      cmd = "/usr/bin/scummvm";
    };
  };
}
