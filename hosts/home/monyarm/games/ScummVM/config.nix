{
  lib,
  dirs,
  mkScummVMGame,
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
      browser_lastpath = "${dirs.Games}/ScummVM/Leisure Suit Larry 1: In the Land of the Lounge Lizards";
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

  }
  // (mkScummVMGame {
    gameid = "samnmax";
    extra = "CD";
    engineid = "scumm";
    enable_enhancements = true;
    guioptions = "gameOption2";
    description = "Sam & Max Hit the Road";
  })
  // (mkScummVMGame {
    gameid = "ft";
    extra = "Version A";
    engineid = "scumm";
    guioptions = "sndNoMIDI";
    description = "Full Throttle";
  })
  // (mkScummVMGame {
    gameid = "dig";
    engineid = "scumm";
    guioptions = "sndNoMIDI";
    description = "The Dig";
  })
  // (mkScummVMGame {
    engineid = "sword25";
    english_speech = true;
    guioptions = "sndNoMIDI noAspect gameOption1";
    description = "Broken Sword 2.5";
  })
  // (mkScummVMGame {
    engineid = "drascula";
    originalsaveload = true;
    guioptions = "sndNoMIDI sndLinkSpeechToSfx gameOption1";
    description = "Drascula: The Vampire Strikes Back";
  })
  // (mkScummVMGame {
    gameid = "dreamweb_cd";
    extra = "CD";
    engineid = "dreamweb";
    tts_enabled_speech = false;
    originalsaveload = true;
    tts_enabled_objects = false;
    guioptions = "sndNoMIDI gameOption1 gameOption2";
    bright_palette = true;
    description = "DreamWeb";
  })
  // (mkScummVMGame {
    engineid = "griffon";
    platform = "windows";
    guioptions = "sndNoMIDI gameOption1";
    description = "The Griffon Legend";
    tts_enabled = false;
  })
  // (mkScummVMGame {
    engineid = "lure";
    extra = "EGA";
    guioptions = "sndNoSpeech gameOption1";
    tts_narrator = false;
    description = "Lure of the Temptress";
  })
  // (mkScummVMGame {
    gameid = "sfinx";
    engineid = "cge2";
    extra = "Freeware v1.1";
    tts_enabled_speech = false;
    tts_enabled_objects = false;
    guioptions = "gameOption1 gameOption2 gameOption3";
    description = "Sfinx";
    enable_color_blind = false;
  })
  // (mkScummVMGame {
    engineid = "cge";
    extra = "Freeware v1.0";
    guioptions = "gameOption1 gameOption2";
    description = "Soltys";
  })
  // (mkScummVMGame {
    engineid = "parallaction";
    extra = "Multi-lingual";
    guioptions = "sndNoSpeech launchNoLoad";
    description = "Nippon Safes Inc.";
    language = "";
  })
  // (mkScummVMGame {
    categoryId = "hires1_apple2";
    gameid = "hires1";
    engineid = "adl";
    extra = "Public Domain";
    color = true;
    platform = "apple2";
    scanlines = false;
    monotext = true;
    guioptions = "sndNoMIDI gameOption1 gameOption2 gameOption4 gameOption5";
    description = "Hi-Res Adventure #1: Mystery House";
    ntsc = true;
  })
  ;
in
{
  games.scummvm.config = scummvmConfig;
}
