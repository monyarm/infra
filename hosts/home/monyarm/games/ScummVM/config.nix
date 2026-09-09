{
  lib,
  dirs,
  ...
}:

with lib;

let
  scummvmConfig = {
    scummvm = {
      filtering = false;
      mute = false;
      window_maximized_width = 1920;
      last_fullscreen_mode_width = 1920;
      multi_midi = false;
      music_driver = "auto";
      vsync = true;
      window_maximized = true;
      gui_browser_native = true;
      window_maximized_height = 1062;
      last_fullscreen_mode_height = 1080;
      mt32_device = "mt32";
      last_window_width = 960;
      talkspeed = 60;
      gfx_mode = "opengl";
      gui_scale = 100;
      subtitles = false;
      music_volume = 192;
      opl_driver = "auto";
      aspect_ratio = true;
      autosave_period = 300;
      grouping = "series";
      native_mt32 = false;
      gui_return_to_launcher_at_exit = false;
      fullscreen = false;
      last_window_height = 720;
      gm_device = "alsa_Midi Through";
      sfx_volume = 192;
      lastselectedgame = "atlantis-steam-win";
      temp_selection = "scottsampler";
      gui_saveload_chooser = "grid";
      speech_volume = 192;
      gui_use_game_language = false;
      confirm_exit = false;
      midi_gain = 100;
      tts_voice = -1;
      stretch_mode = "fit";
      tts_enabled = false;
      versioninfo = "2.8.0git";
      speech_mute = false;
      enable_gs = false;
    };

  };
in
{
  games.scummvm.config = scummvmConfig;
}
