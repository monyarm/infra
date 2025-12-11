_:

{
  programs.mpv = {
    bindings = {
      "MBTN_RIGHT" = "cycle pause";
      "SPACE" = "cycle pause";
      "." = "frame-step";
      "," = "frame-back-step";
      "LEFT" = "script-binding evafast/evafast-rewind";
      "RIGHT" = "script-binding evafast/evafast";
      "MBTN_BACK" = "script-binding evafast/evafast-rewind";
      "MBTN_FORWARD" = "script-binding evafast/evafast";
      "UP" = "no-osd seek 84.25";
      "DOWN" = "no-osd seek -84.25";
      "WHEEL_UP" = "no-osd add volume 2";
      "WHEEL_DOWN" = "no-osd add volume -2";
      "MBTN_LEFT_DBL" = "cycle fullscreen";
      "ESC" = "set fullscreen no";
      "`" = "script-binding stats/display-stats-toggle";
      "~" = "script-binding console/enable";
      "p" = "script-binding webtorrent/toggle-info";

      # Anime4K shader bindings
      "CTRL+1" = "no-osd apply-profile \"Anime4K-A\"; show-text \"Anime4K: Mode A (HQ)\"";
      "CTRL+2" = "no-osd apply-profile \"Anime4K-B\"; show-text \"Anime4K: Mode B (HQ)\"";
      "CTRL+3" = "no-osd apply-profile \"Anime4K-C\"; show-text \"Anime4K: Mode C (HQ)\"";
      "CTRL+4" = "no-osd apply-profile \"Anime4K-A+A\"; show-text \"Anime4K: Mode A+A (HQ)\"";
      "CTRL+5" = "no-osd apply-profile \"Anime4K-B+B\"; show-text \"Anime4K: Mode B+B (HQ)\"";
      "CTRL+6" = "no-osd apply-profile \"Anime4K-C+A\"; show-text \"Anime4K: Mode C+A (HQ)\"";
      "CTRL+8" = "no-osd apply-profile \"ArtCNN\"; show-text \"ArtCNN C4F16 + Adaptive Sharpen\"";
      "CTRL+0" = "no-osd apply-profile \"no-shaders\"; show-text \"GLSL shaders cleared\"";
    };

    extraInput = ''
      # List of default binds: https://github.com/mpv-player/mpv/blob/master/etc/input.conf

      # uosc menu
      # script-binding uosc/open-file                                                #! Open file
      # script-binding uosc_youtube_search/open-menu                                 #! YouTube search
      # script-binding memo-history                                                  #! History
      # script-binding uosc/keybinds                                                 #! Keybinds
      # script-binding uosc_video_settings/open-menu                                 #! Video settings
      # script-binding uosc/audio-device                                             #! Audio devices
      # script-binding uosc_subtitle_settings/open-menu                              #! Subtitle settings
      # script-binding uosc/screenshot-menu                                          #! Screenshot
    '';
  };
}
