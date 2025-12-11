{
  lib,
  dirs,
  ...
}:

with lib;

let
  languageMap = {
    # keep-sorted start
    "" = "";
    en = "English";
    jp = "Japanese";
    # Add other languages as needed
    # keep-sorted end
  };

  platformMap = {
    # keep-sorted start
    apple2 = "Apple II";
    pc = "DOS";
    windows = "Windows";
    # Add other platforms as needed
    # keep-sorted end
  };

  mkScummVMGame =
    {
      categoryId ? gameid,
      gameid ? engineid,
      engineid,
      description ? "", # Base description
      path ? "${dirs.Games}/ScummVM/${description}", # Path derived from base description
      platform ? "pc",
      extra ? "",
      guioptions ? "",
      language ? "en",
      ...
    }@args:
    assert (languageMap ? ${language} || language == "");
    let

      mappedPlatform = if (platform != "") then (platformMap.${platform} or null) else null;

      # Construct the bracketed part of the description
      # Only include parts if they are not empty
      bracketedParts = filter (s: s != "") [
        (if extra != "" then extra else "")
        (if mappedPlatform != null then mappedPlatform else "")
        (if language != "" then languageMap.${language} else "")
      ];

      # Combine bracketed parts into a single string, e.g., " (CD/DOS/English)"
      bracketedString =
        if bracketedParts != [ ] then " (" + (concatStringsSep "/" bracketedParts) + ")" else "";

      # Append the bracketed string to the base description
      finalDescription = "${description}${bracketedString}";

    in
    {
      "${categoryId}" = {
        inherit
          gameid
          engineid
          path
          platform
          extra
          language
          ;
        guioptions = "${guioptions}" + optionalString (language != "") "lang_${languageMap.${language}}";
        description = finalDescription;
      }
      // (removeAttrs args [
        "categoryId"
        "gameid"
        "description"
        "path"
        "engineid"
        "platform"
        "extra"
        "guioptions"
        "language"
      ]);
    };

  mkManiac =
    version:
    mkScummVMGame rec {
      categoryId = "maniac_v${toString version}";
      gameid = "maniac";
      engineid = "scumm";
      extra = "V${toString version}";
      enable_enhancements = true;
      guioptions = "sndNoSpeech sndNoMIDI midiAdLib gameOption2";
      description = "Maniac Mansion";
      path = "${dirs.Games}/ScummVM/${description}/${extra}";
    };

  mkMissionSupernova =
    version:
    mkScummVMGame rec {
      categoryId = "msn${toString version}";
      engineid = "supernova";
      guioptions = "sndNoMIDI gameOption1 gameOption2";
      description = "Mission Supernova ${toString version}";
      improved = true;
      tts_enabled = false;
    };

  mkAdventureInternationalGame =
    args:
    mkScummVMGame (
      args
      // {
        engineid = "glk";
        guioptions = "sndNoSubs sndNoMusic";
        path = "${dirs.Games}/ScummVM/Adventure International/AdamsGames";
      }
    );

  mkSavageIslandGame =
    version:
    mkAdventureInternationalGame rec {
      gameid = "savageisland${toString version}";
      filename = "adv${toString (10 + version - 1)}.dat";
      description = "Savage Island, Part ${toString version}";
    };

  mkMarvelAdventureGame =
    version:
    mkAdventureInternationalGame rec {
      gameid = "marveladventure${if version == 1 then "" else toString version}";
      filename = "quest${toString version}.dat";
      description = "Marvel Adventure #${toString version}";
    };

  mkLslGame =
    version: args:
    mkScummVMGame (
      {
        gameid = "lsl${toString version}";
        engineid = "sci";
        originalsaveload = true;
        rgb_rendering = true;
        prefer_digitalsfx = true;
        disable_dithering = true;
        tts_enabled = false;
        midi_mode = 0;
      }
      // args
    );

  mkGlkCommonGame =
    args:
    mkScummVMGame (
      {
        engineid = "glk";
        speak = false;
        speak_input = false;
        guioptions = "sndNoSubs sndNoMusic";
        filename = "G0";
      }
      // args
    );

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
      browser_lastpath = "/mnt/Games/ScummVM/Leisure Suit Larry 1: In the Land of the Lounge Lizards";
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
    engineid = "sky";
    extra = "v0.0372 cd";
    description = "Beneath a Steel Sky";
    alt_intro = false;
  })
  // (mkScummVMGame {
    engineid = "draci";
    description = "Draci Historie";
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
    engineid = "queen";
    extra = "Talkie";
    guioptions = "gameOption1";
    description = "Flight of the Amazon Queen";
    alt_intro = false;
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
    categoryId = "atlantis-steam-win";
    gameid = "atlantis";
    engineid = "scumm";
    extra = "Steam";
    gui_saveload_last_pos = 0;
    enable_enhancements = true;
    mute = false;
    platform = "windows";
    talkspeed = 170;
    original_gui_text_status = 1;
    subtitles = true;
    music_volume = 192;
    guioptions = "ega gameOption2 gameOption4";
    sfx_volume = 192;
    description = "Indiana Jones and the Fate of Atlantis";
    speech_volume = 192;
    speech_mute = false;
  })
  // (mkScummVMGame {
    gameid = "lure_1";
    engineid = "lure";
    extra = "VGA";
    guioptions = "sndNoSpeech gameOption1";
    tts_narrator = false;
    description = "Lure of the Temptress";
  })
  // (mkScummVMGame {
    engineid = "parallaction";
    extra = "Multi-lingual";
    guioptions = "sndNoSpeech launchNoLoad";
    description = "Nippon Safes Inc.";
    language = "";
  })
  // (mkScummVMGame {
    categoryId = "indy3-steam-win";
    gameid = "indy3";
    engineid = "scumm";
    extra = "Steam";
    enable_enhancements = true;
    platform = "windows";
    guioptions = "sndNoSpeech sndNoMIDI gameOption2";
    description = "Indiana Jones and the Last Crusade";
  })
  // (mkManiac 1)
  // (mkManiac 2)
  // (mkScummVMGame rec {
    gameid = "lsl1";
    engineid = "agi";
    extra = "1.00 1987-06-01 5.25\"/3.5\"";
    originalsaveload = true;
    guioptions = "sndNoSpeech gameOption1 gameOption3 gameOption4 gameOption5";
    description = "Leisure Suit Larry 1: In the Land of the Lounge Lizards";
    mousesupport = true;
    herculesfont = true;
    commandpromptwindow = true;
  })
  // (mkLslGame 2 {
    palette_mods = true;
    guioptions = "sndNoSpeech gameOption1 gameOption2 gameOption3 gameOption7 gameOptionE gameOptionF gameOptionH";
    description = "Leisure Suit Larry 2: Goes Looking for Love (in Several Wrong Places)";
  })
  // (mkLslGame 3 {
    guioptions = "sndNoSpeech gameOption1 gameOption2 gameOption3 gameOption7 gameOptionE gameOptionH";
    description = "Leisure Suit Larry 3: Passionate Patti in Pursuit of the Pulsating Pectorals";
  })
  // (mkLslGame 6 {
    categoryId = "lsl6_cd";
    extra = "CD";
    guioptions = "gameOption1 gameOption2 gameOption3 gameOptionE";
    description = "Leisure Suit Larry 6: Shape Up or Slip Out!";
  })
  // (mkLslGame 7 {
    enable_hq_video = true;
    guioptions = "sndNoMIDI noAspect gameOption2 gameOption9 gameOptionA gameOptionC";
    enable_black_lined_video = true;
    enable_larryscale = true;
    description = "Leisure Suit Larry 7: Love for Sail!";
  })
  // (mkLslGame 5 {
    guioptions = "sndNoSpeech gameOption1 gameOption2 gameOption3 gameOptionE gameOptionH";
    description = "Leisure Suit Larry 5: Passionate Patti Does a Little Undercover Work";
  })
  // (mkScummVMGame {
    gameid = "thesavageempire_enh";
    engineid = "ultima";
    description = "Worlds of Ultima: The Savage Empire - Enhanced";
  })
  // (mkScummVMGame {
    gameid = "ultima4_enh";
    engineid = "ultima";
    guioptions = "sndNoSpeech";
    description = "Ultima IV - Quest of the Avatar - Enhanced";
  })
  // (mkScummVMGame {
    engineid = "teenagent";
    extra = "Alt version";
    guioptions = "sndNoSpeech sndNoMIDI";
    description = "Teen Agent";
  })
  // (mkAdventureInternationalGame {
    categoryId = "adventureland_1";
    gameid = "adventureland";
    filename = "adv01.dat";
    description = "Adventureland";
  })
  // (mkAdventureInternationalGame {
    gameid = "buckaroobanzai";
    filename = "adv14b.dat";
    description = "Buckaroo Banzai";
  })
  // (mkAdventureInternationalGame {
    gameid = "claymorguesorcerer";
    filename = "adv13.dat";
    description = "Sorcerer of Claymorgue Castle";
  })
  // (mkAdventureInternationalGame {
    gameid = "ghosttown";
    filename = "adv09.dat";
    description = "Ghost Town";
  })
  // (mkAdventureInternationalGame {
    gameid = "goldenvoyage";
    filename = "adv12.dat";
    description = "The Golden Voyage";
  })
  // (mkMarvelAdventureGame 1)
  // (mkMarvelAdventureGame 2)
  // (mkAdventureInternationalGame {
    gameid = "missionimpossible";
    filename = "adv03.dat";
    description = "Mission Impossible";
  })
  // (mkAdventureInternationalGame {
    gameid = "mysteryfunhouse";
    filename = "adv07.dat";
    description = "Mystery Fun House";
  })
  // (mkAdventureInternationalGame {
    gameid = "pirateadventure";
    filename = "adv02.dat";
    description = "Pirate Adventure";
  })
  // (mkAdventureInternationalGame {
    gameid = "pirateisle";
    filename = "adv14a.dat";
    description = "Return to Pirate Isle";
  })
  // (mkAdventureInternationalGame {
    gameid = "pyramidofdoom";
    filename = "adv08.dat";
    description = "Pyramid Of Doom";
  })
  // (mkSavageIslandGame 1)
  // (mkSavageIslandGame 2)
  // (mkAdventureInternationalGame {
    gameid = "scottsampler";
    filename = "sampler1.dat";
    description = "Adventure International's Mini-Adventure Sampler";
  })
  // (mkAdventureInternationalGame {
    gameid = "strangeodyssey";
    filename = "adv06.dat";
    description = "Strange Odyssey";
  })
  // (mkAdventureInternationalGame {
    gameid = "thecount";
    filename = "adv05.dat";
    description = "The Count";
  })
  // (mkAdventureInternationalGame {
    gameid = "voodoocastle";
    filename = "adv04.dat";
    description = "Voodoo Castle";
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
  // (mkGlkCommonGame {
    gameid = "transylvaniav2";
    description = "Transylvania (V2)";
  })
  // (mkGlkCommonGame {
    gameid = "ootopos";
    description = "OO-Topos";
  })
  // (mkGlkCommonGame {
    gameid = "crimsoncrown";
    filename = "CC1.GDA";
    description = "Crimson Crown";
  })
  // (mkGlkCommonGame {
    gameid = "talisman";
    description = "Talisman: Challenging the Sands of Time";
  })
  // (mkScummVMGame {
    gameid = "softporn";
    engineid = "glk";
    extra = "971018";
    speak = false;
    speak_input = false;
    guioptions = "sndNoSubs sndNoMusic sndNoSFX";
    filename = "softporn.z5";
    description = "Softporn Adventure";
  })
  // (mkScummVMGame {
    gameid = "hugo1";
    engineid = "hugo";
    description = "Hugo 1: Hugo's House of Horrors";
  })
  // (mkMissionSupernova 1)
  // (mkMissionSupernova 2);
in
{
  xdg.configFile."scummvm/scummvm.ini".text = generators.toINI { } scummvmConfig;
}
