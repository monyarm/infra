{ lib, dirs, ... }:
let

  # Games whose AutoExec points at the shared per-engine autoexec.cfg.
  autoExecGames = [
    "Doom"
    "Heretic"
    "Hexen"
    "Strife"
    "Chex"
  ];

  # Wad files to automatically load depending on the game and IWAD you are
  # playing. You may have files that are loaded for all similar IWADs (the
  # game) and files that only load for particular IWADs. For example, files
  # under 'doom.Autoload' load for any version of Doom, but files under
  # 'doom.doom2.Autoload' only load for a Doom 2 based game (doom2.wad,
  # tnt.wad or plutonia.wad), and files under 'doom.doom2.commercial.Autoload'
  # only when playing doom2.wad.
  autoloadCategories = [
    "doom"
    "doom.id"
    "doom.id.doom2"
    "doom.id.doom2.commercial"
    "doom.id.doom2.commercial.french"
    "doom.id.doom2.commercial.xbox"
    "doom.id.doom2.unity"
    "doom.id.doom2.bfg"
    "doom.id.doom2.plutonia"
    "doom.id.doom2.plutonia.unity"
    "doom.id.doom2.tnt"
    "doom.id.doom2.tnt.unity"
    "doom.id.doom1"
    "doom.id.doom1.registered"
    "doom.id.doom1.ultimate"
    "doom.id.doom1.ultimate.xbox"
    "doom.id.wadsmoosh"
    "doom.id.doom1.unity"
    "doom.id.doom1.bfg"
    "doom.freedoom"
    "doom.freedoom.demo"
    "doom.freedoom.phase1"
    "doom.freedoom.phase2"
    "doom.freedoom.freedm"
    "heretic"
    "heretic.heretic"
    "heretic.shadow"
    "blasphemer"
    "hexen"
    "hexen.deathkings"
    "hexen.hexen"
    "strife"
    "strife.strife"
    "strife.veteran"
    "chex"
    "chex.chex1"
    "chex.chex3"
    "urbanbrawl"
    "hacx"
    "hacx.hacx1"
    "hacx.hacx2"
    "harmony"
    "square"
    "square.squareware"
    "square.square"
    "delaweare"
    "woolball"
    "woolball.rotwb"
    "doom.id.doom2.wadsmoosh"
  ];

  # `engine` selects which ZDoom-family engine this config is generated for
  # (its config dir under ~/.config, /usr/share/<engine>, and the
  # fluid_patchset/midi_config/timidity_config resource-set name all follow
  # the engine's own name, not a fixed "gzdoom").
  mkDoomConf =
    engine:
    lib.generators.toINI { listsAsDuplicateKeys = true; } (
      {
        # These are the directories to automatically search for IWADs.
        # Each directory should be on a separate line, preceded by Path=
        "IWADSearch.Directories" = {
          Path = [
            "."
            "$DOOMWADDIR"
            "${dirs.xdg.config}/${engine}"
            "/usr/local/share/doom"
            "/usr/local/share/games/doom"
            "/usr/share/doom"
            "/usr/share/games/doom"
            "${dirs.Games}/WAD/*"
            "${dirs.SteamLibrarySSD}/steamapps/common/Ultimate Doom/base"
            "${dirs.SteamLibrarySSD}/steamapps/common/Doom 2/base"
          ];
        };

        # These are the directories to search for wads added with the -file
        # command line parameter, if they cannot be found with the path
        # as-is. Layout is the same as for IWADSearch.Directories
        "FileSearch.Directories" = {
          Path = [
            "${dirs.xdg.config}/${engine}"
            "/usr/share/${engine}"
            "/usr/local/share/doom"
            "/usr/local/share/games/doom"
            "/usr/share/doom"
            "/usr/share/games/doom"
            "$DOOMWADDIR"
            "${dirs.Games}/WAD"
          ];
        };

        # These are the directories to search for soundfonts that get listed in
        # the menu. Layout is the same as for IWADSearch.Directories
        "SoundfontSearch.Directories" = {
          Path = [
            "${dirs.xdg.config}/${engine}/soundfonts"
            "${dirs.xdg.config}/${engine}/fm_banks"
            "/usr/share/${engine}/soundfonts"
            "/usr/share/${engine}/fm_banks"
            "/usr/local/share/doom/soundfonts"
            "/usr/local/share/doom/fm_banks"
            "/usr/local/share/games/doom/soundfonts"
            "/usr/local/share/games/doom/fm_banks"
            "/usr/share/doom/soundfonts"
            "/usr/share/doom/fm_banks"
            "/usr/share/games/doom/soundfonts"
            "/usr/share/games/doom/fm_banks"
            "/usr/share/soundfonts"
            "${dirs.Games}/WAD"
          ];
        };

        # Files to automatically execute when running the corresponding game.
        # Each file should be on its own line, preceded by Path=
      }
      // lib.genAttrs (map (game: "${game}.AutoExec") autoExecGames) (_: {
        Path = "${dirs.xdg.config}/${engine}/autoexec.cfg";
      })
      // {
        # WAD files to always load. These are loaded after the IWAD but before
        # any files added with -file. Place each file on its own line,
        # preceded by Path=
        "Global.Autoload" = {
          # Empty for now, as there are no paths listed
        };
      }
      // lib.listToAttrs (map (category: lib.nameValuePair "${category}.Autoload" { }) autoloadCategories)
      // {
        LastRun = {
          Version = 223;
        };

        # Only settings that differ from this engine's compiled-in defaults are
        # listed below (verified against the UZDoom 4.14.3 source, the version
        # pinned by pkgs.uzdoom) — anything matching the default is omitted so
        # this reflects actual customization rather than a full dump.
        GlobalSettings = {
          defaultiwad = "The Ultimate DOOM";
          fluid_chorus_level = 1;
          fluid_patchset = engine;
          freelook = false;
          gl_particles_style = 2;
          gl_seamless = false;
          gl_texture_filter = 4;
          gl_texture_filter_anisotropic = 8;
          inter_subtitles = false;
          longsavemessages = true;
          m_sensitivity_x = 3;
          m_simpleoptions = true;
          m_use_mouse = 2;
          midi_config = engine;
          # Not a recognized cvar in current UZDoom source (possibly stale
          # from an older engine version) — kept rather than guessed at.
          mus_gainoffset = 0;
          snd_mastervolume = 1;
          snd_musicvolume = 0.5;
          timidity_config = engine;
          vid_defheight = 1080;
          vid_defwidth = 1920;
          vid_maxfps = 200;
          vid_preferbackend = 0;
          vid_scale_customheight = 400;
          vid_scale_customwidth = 640;
          win_h = 864;
          win_maximized = true;
          win_w = 1536;
          win_x = 258;
          win_y = 133;
        };

        # GZDoom's own bucket for cvars it didn't recognize when this ini was
        # last loaded; m_filter isn't a cvar in current UZDoom, so there's no
        # default to compare against — left as-is.
        "GlobalSettings.Unknown" = {
          m_filter = false;
        };

        # Every other Doom.Player cvar matches the engine default (autoaim=35,
        # color=0x40cf00, skin="base", playerclass="Fighter", etc) except
        # gender, which defaults to "neutral".
        "Doom.Player" = {
          gender = "male";
        };

        "Doom.ConsoleVariables" = {
          addrocketexplosion = false;
          am_colorset = 0;
          cl_rockettrails = 1;
          gl_enhanced_nightvision = true;
          gl_fogmode = 1;
          gl_fuzztype = 0;
          gl_lightmode = 3;
          gl_spriteclip = 1;
          hud_aspectscale = false;
          hud_scale = 0;
          st_scale = 0;
        };

        # Fully matches engine defaults.
        "Doom.LocalServerInfo" = { };

        "Doom.ConfigOnlyVariables" = { };

        "Doom.UnknownConsoleVariables" = { };

        "Doom.ConsoleAliases" = { };

        # Custom keysection from a specific mod (Splatterhouse 3D), not an
        # engine default — left untouched.
        "Doom.spdivk_keysection.Bindings" = {
          Z = "ad2_drop";
        };

        "Doom.spdivk_keysection.DoubleBindings" = { };

        # Every other binding matches the engine's default
        # wadsrc/static/engine/{def,common}binds.txt; Pad_Start/Pad_Back are
        # swapped relative to the default (pad_start=menu_main,
        # pad_back=pause) and kept as the real customization.
        "Doom.Bindings" = {
          Pad_Start = "pause";
          Pad_Back = "menu_main";
        };

        "Doom.DoubleBindings" = { };

        # Fully matches the default automap bindings in
        # wadsrc/static/engine/commonbinds.txt.
        "Doom.AutomapBindings" = { };

        # Custom cvars from the "Adventures of Square" mod, not engine
        # settings — left untouched.
        "Doom.Player.Mod" = {
          square_jabber_chance = 15;
          square_subtitles = false;
        };

        "Doom.LocalServerInfo.Mod" = {
          square_hints = false;
        };

        "Doom.ConfigOnlyVariables.Mod" = { };
      }
    );

  mkEngineConfigs = engines: {
    xdg.configFile = lib.listToAttrs (
      map (engine: lib.nameValuePair "${engine}/${engine}.ini" { text = mkDoomConf engine; }) engines
    );
  };

in
mkEngineConfigs [
  "zdoom"
  "gzdoom"
  "uzdoom"
]
