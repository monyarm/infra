{
  config,
  lib,
  fetchSteam,
  pkgs,
  compressScummvmGame,
  getFiles,
  ...
}:
let
  mkLslGame =
    version: args:
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
    // args;

  mkManiac =
    version: args:
    {
      categoryId = "maniac_v${toString version}";
      gameid = "maniac";
      engineid = "scumm";
      extra = "V${toString version} Steam";
      enable_enhancements = true;
      guioptions = "sndNoSpeech sndNoMIDI midiAdLib gameOption2";
      description = "Maniac Mansion";
    }
    // args;

  alphaPolaris =
    fetchSteam {
      appId = 405780;
      depotId = 405781;
      manifestId = 131643505400606065;
      # The depot duplicates every file under a "1280x768/" subfolder plus the
      # root; restrict to the root copy of the two .dcp packages ScummVM's
      # wintermute engine actually needs, skipping the .exe/.dll launcher files.
      filelist = [
        "regex:^(data\\.dcp|english speech pack\\.dcp)$"
      ];
      sha256 = "sha256-XyGU+ydnRduM5MJRJq2rAFbFZO74u5/zljk/MgHTQqM=";
    }
    |> compressScummvmGame "wintermute";

  artOfMurder1 =
    fetchSteam {
      appId = 809000;
      depotId = 809002;
      manifestId = 5682759667480301174;
      sha256 = "sha256-XjdTjPMG9Mp7/wVCsQU3S+re07UAiPrqKXOogC8sYVY=";
    }
    |> compressScummvmGame "wintermute";

  ashinaRedWitch =
    fetchSteam {
      appId = 1259140;
      depotId = 1259141;
      manifestId = 7304502370705097563;
      sha256 = "sha256-CDzSfJadKWhUpZeYcB+EzmfwO9nGawnwW/h0tFTiDDw=";
    }
    |> compressScummvmGame "ags";

  barrowHillDarkPath =
    fetchSteam {
      appId = 520990;
      depotId = 520991;
      manifestId = 7732106364668340045;
      os = "windows";
      sha256 = "sha256-MALn6trj1yp8VmoRR3w8sRziYpdOPlpezF6QEXkNYWg=";
    }
    |> compressScummvmGame "wintermute";

  kingOfDragonPass =
    fetchSteam {
      appId = 352220;
      depotId = 352221;
      manifestId = 4517013077217297009;
      os = "windows";
      sha256 = "sha256-jlJ0vfKJTapiiTcWhMqT1uPcMBAet0wBYZtEt+Zw/WA=";
    }
    |> compressScummvmGame "mtropolis";

  littleBigAdventureDl = fetchSteam {
    appId = 397330;
    depotId = 397338;
    manifestId = 606382556722002081;
    os = "windows";
    sha256 = "sha256-UOeE+ua13AuZSZiLED5PyTfXzOfSWzUdSoahCAlpYs8=";
  };

  # ScummVM's twine engine needs every .HQR file in one flat directory, but
  # the remaster's classic-mode text (TEXT.HQR) lives in a separate
  # CommonClassic/ folder from the rest of the classic resources in Common/.
  # Merge (and thus narrow away every other sibling in the depot -- HD
  # assets, the remaster's own engine binaries) before compressScummvmGame
  # walks the tree, instead of after.
  littleBigAdventure =
    pkgs.runCommand "lba-classic-merged"
      {
        __contentAddressed = true;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        mkdir -p $out
        cp -r ${littleBigAdventureDl}/Common/* $out/
        cp ${littleBigAdventureDl}/CommonClassic/TEXT.HQR $out/
      ''
    |> compressScummvmGame "twine";

  littleBigAdventure2 =
    fetchSteam {
      appId = 398000;
      depotId = 398008;
      manifestId = 6898977048178414927;
      os = "windows";
      sha256 = "sha256-69Abh4aNEJvglt9mcgXePZNQtoxhOgNV2FXIRv5t/6Q=";
    }
    |> compressScummvmGame "twine";

  myBigSisterRemastered =
    fetchSteam {
      appId = 2118540;
      depotId = 2118541;
      manifestId = 4556488665416661391;
      os = "windows";
      sha256 = "sha256-LlQakl+s3nnWe+ouZhTfJuVs1/w3LnRCaopXQnZLS0M=";
    }
    |> compressScummvmGame "ags";

  reversion1 =
    fetchSteam {
      appId = 270570;
      depotId = 270572;
      manifestId = 842084957891672528;
      os = "windows";
      sha256 = "sha256-bWaNV7el0vzlX6uzgm9n8JnQSEwNvZ99jN/QvsSI7qA=";
    }
    |> compressScummvmGame "wintermute";

  reversion2 =
    fetchSteam {
      appId = 281060;
      depotId = 281061;
      manifestId = 5690544705524244198;
      os = "windows";
      sha256 = "sha256-s6vMvU8Jcu3tOkFkg2SeDEsCg3gWSopspKTbXv61TUs=";
    }
    |> compressScummvmGame "wintermute";

  reversion3 =
    fetchSteam {
      appId = 281080;
      depotId = 281082;
      manifestId = 6387913456714868142;
      os = "windows";
      sha256 = "sha256-jbtX2t3cCS3e6BsLUhDsz2culKqu2+DDgL6Ccbc1eRs=";
    }
    |> compressScummvmGame "wintermute";

  # This depot ships both the ScummVM-ready folder and a bunch of unrelated
  # siblings (DOSBox layer, redistributables); narrow before
  # compressScummvmGame walks the tree, instead of after.
  curseOfMonkeyIsland =
    fetchSteam {
      appId = 730820;
      depotId = 730824;
      manifestId = 6035470325928818097;
      os = "windows";
      sha256 = "sha256-w1TLqJnXd1P16iXOnQNYAN11ebitYsl2bkUodFC7Xf0=";
    }
    |> getFiles [ "ScummVM/monkey3" ]
    |> compressScummvmGame "scumm";

  lastExpressDl = fetchSteam {
    appId = 252710;
    depotId = 252712;
    manifestId = 136184711608217470;
    os = "windows";
    sha256 = "sha256-A8DMdL4FR9hJjJWhBUggXrx2AKLUFunF5ISPUAb6oTg=";
  };

  # This Gold Edition repackages the original 1997 CD data as one zip per
  # resource category (BG/DATA/LNK/NIS/SBE/SEQ/SND/TGA) instead of shipping
  # it already unpacked; ScummVM needs it all merged into one directory.
  lastExpress =
    pkgs.runCommand "tle-merged"
      {
        nativeBuildInputs = [ pkgs.unzip ];
        __contentAddressed = true;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        mkdir -p $out
        for category in NIS SBE SEQ LNK SND TGA BG DATA; do
          unzip -oq ${lastExpressDl}/roms/$category.zip -d $out
        done
      ''
    |> compressScummvmGame "lastexpress";

  fateOfAtlantis =
    fetchSteam {
      appId = 6010;
      depotId = 6011;
      manifestId = 8584153416851488924;
      os = "windows";
      sha256 = "sha256-dRLdjsOwqEHLyX6a1OSh90ud4U3Ji8Ff6cxK0FbZEpk=";
    }
    |> getFiles [ "ATLANTIS" ]
    |> compressScummvmGame "scumm";

  # Both maniacMansionV1 and V2 read out of this one depot's ScummVM/
  # subfolder (original + enhanced), so narrow to just that instead of the
  # whole depot before compressing -- one compressed copy still covers both
  # games below.
  maniacMansionDl =
    fetchSteam {
      appId = 529890;
      depotId = 529891;
      manifestId = 4552517924922056300;
      os = "windows";
      sha256 = "sha256-CRMGTYDrYUpwI/0SgwcYBy3LMYpdnt6htOiPr5xFo7I=";
    }
    |> getFiles [
      "ScummVM/original"
      "ScummVM/enhanced"
    ]
    |> compressScummvmGame "scumm";

  lsl1 =
    fetchSteam {
      appId = 763970;
      depotId = 763971;
      manifestId = 6067288779454216216;
      os = "windows";
      sha256 = "sha256-MxUuW5kQ+lW97tBDQDuHUQe4inrndEn0jdPHy7+4iJE=";
    }
    |> compressScummvmGame "agi";

  lsl2 =
    fetchSteam {
      appId = 765840;
      depotId = 765841;
      manifestId = 8306539708319125167;
      os = "windows";
      sha256 = "sha256-55h5ymBJleE00RoHq+hhEiX4CPV1xT6lryXBii3YFFg=";
    }
    |> compressScummvmGame "sci";

  lsl3 =
    fetchSteam {
      appId = 765850;
      depotId = 765851;
      manifestId = 7288709448665407579;
      os = "windows";
      sha256 = "sha256-8YasS/tg0FnTYlsE/dsRdx0U2UOD3xkhKAOIgGcP1P8=";
    }
    |> compressScummvmGame "sci";

  lsl5 =
    fetchSteam {
      appId = 765860;
      depotId = 765861;
      manifestId = 7170853141795138447;
      os = "windows";
      sha256 = "sha256-7odJV6PHvJH/KkiaSIttF1347XvyW7fG6JFvhyoBmWo=";
    }
    |> compressScummvmGame "sci";

  lsl6 =
    fetchSteam {
      appId = 765910;
      depotId = 765911;
      manifestId = 6538076485632756933;
      os = "windows";
      sha256 = "sha256-zu/gEB4g6qPw5JdegKCTYo8+gUUh68C/1zhE/6A/rNg=";
    }
    |> compressScummvmGame {
      engineid = "sci";
      sciSupported = true; # SCI1.1 CD, pre-SCI32 -- compress_sci is safe here.
    };

  # SCI32 -- compress_sci is explicitly NOT compatible (upstream), so this
  # never sets sciSupported.
  lsl7 =
    fetchSteam {
      appId = 765890;
      depotId = 765891;
      manifestId = 8709297254560218806;
      os = "windows";
      sha256 = "sha256-7EhzrLJyYLJedQ9duqDXE81495TAG2x2Tt5RBIPF/DY=";
    }
    |> compressScummvmGame "sci";

  sanitarium =
    fetchSteam {
      appId = 284050;
      depotId = 284051;
      manifestId = 2197383176086176404;
      os = "windows";
      filelist = [ "regex:^Data/EN/.*$" ];
      sha256 = "sha256-skT+f2qJOFSPEadeFYSNLYJrjzbvE6iJPpwXU6gh2IY=";
    }
    |> compressScummvmGame "asylum";

  # tenta.cle is a DoubleFine LPAK bundle holding both the HD remaster's
  # assets/engine and the original 1993 SCUMM data together in one opaque
  # blob -- filelist can't narrow inside a single file, so the whole bundle
  # is fetched, then pkgs.untangle (packages/untangle.nix, sourced via
  # sources.toml) pulls out just the classic/en/ subset ScummVM's scumm
  # engine needs.
  dottDl = fetchSteam {
    appId = 388210;
    depotId = 388211;
    manifestId = 8150331470367542821;
    os = "windows";
    filelist = [ "tenta.cle" ];
    sha256 = "sha256-70W9NcCB4gDKbJp55wAwvHfmkw7z3MibYvUW/sWSZEk=";
  };

  dott =
    pkgs.runCommand "dott-classic-extracted"
      {
        nativeBuildInputs = [ pkgs.untangle ];
        __contentAddressed = true;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        untangle -x -F 'classic/en/*' ${dottDl}/tenta.cle
        mkdir -p $out
        cp classic/en/* $out/
      ''
    |> compressScummvmGame "scumm";

  lastCrusade =
    fetchSteam {
      appId = 32310;
      depotId = 32311;
      manifestId = 1410091949724710807;
      os = "windows";
      sha256 = "sha256-M+1TMlSW0xVxDFQbFzEXXGqRJ4bBg4+1OVKjQVACnR4=";
    }
    |> getFiles [ "INDY3" ]
    |> compressScummvmGame "scumm";
in
lib.mkIf config.games.scummvm.enable {
  games.scummvm.games.alphaPolaris = {
    gameid = "alphapolaris";
    engineid = "wintermute";
    extra = "Steam";
    description = "Alpha Polaris";
    path = "${alphaPolaris}";
    steamAppId = 405780;
    steamCdnImagesHash = "sha256-I6suEDTQ69BzjKfXOQVWZYSn911fGe8QvB9LBOn3TiU=";
  };

  games.scummvm.games.artOfMurder1 = {
    gameid = "artofmurder1";
    engineid = "wintermute";
    extra = "Steam";
    description = "Art of Murder 1: FBI Confidential";
    path = "${artOfMurder1}";
    steamAppId = 809000;
    steamCdnImagesHash = "sha256-T9d3J4Ol8lHCtV2eXtaOC0EqPB0gpfJLjmK57qjuzLc=";
  };

  games.scummvm.games.ashinaRedWitch = {
    gameid = "ashinaredwitch";
    engineid = "ags";
    extra = "Steam";
    description = "Ashina: The Red Witch";
    path = "${ashinaRedWitch}";
    steamAppId = 1259140;
    steamCdnImagesHash = "sha256-m30cR3hRlqZhyu+vsAuTQlO3s93CkbhY+laE6HqF4J0=";
  };

  games.scummvm.games.barrowHillDarkPath = {
    gameid = "barrowhilldp";
    engineid = "wintermute";
    extra = "Steam";
    description = "Barrow Hill - The Dark Path";
    path = "${barrowHillDarkPath}";
    steamAppId = 520990;
    steamCdnImagesHash = "sha256-ilh3ZH3xGRQEaeyPI1G04A09vWNUCg5rDCVVGbOOC+0=";
  };

  games.scummvm.games.kingOfDragonPass = {
    gameid = "kingofdragonpass";
    engineid = "mtropolis";
    extra = "Steam";
    description = "King of Dragon Pass";
    path = "${kingOfDragonPass}";
    steamAppId = 352220;
    steamCdnImagesHash = "sha256-J9ppm7WGN7RXKl7vyi5LK0uVcV34WoytKJlBozIEZAc=";
  };

  games.scummvm.games.littleBigAdventure = {
    gameid = "lba";
    engineid = "twine";
    extra = "Steam";
    description = "Little Big Adventure";
    path = "${littleBigAdventure}";
    steamAppId = 397330;
    steamCdnImagesHash = "sha256-aB2g6x8IshbxBNBLJhoYLh5s1oHrbGorvGShbwM4rlI=";
  };

  games.scummvm.games.littleBigAdventure2 = {
    gameid = "lba2";
    engineid = "twine";
    extra = "Steam";
    description = "Little Big Adventure 2";
    path = "${littleBigAdventure2}/Common";
    steamAppId = 398000;
    steamCdnImagesHash = "sha256-UQ1ikxV7sZ/FPS82rrjc0UETo+8lTA1cdhTx798OirM=";
  };

  games.scummvm.games.myBigSisterRemastered = {
    gameid = "mybigsisterrm";
    engineid = "ags";
    extra = "Steam";
    description = "My Big Sister: Remastered";
    path = "${myBigSisterRemastered}";
    steamAppId = 2118540;
    steamCdnImagesHash = "sha256-O+NIb+H9/mks6xhG+VJJiGcdrfqj2L2VR3BKketUtXc=";
  };

  games.scummvm.games.reversion1 = {
    gameid = "reversion1";
    engineid = "wintermute";
    extra = "Steam";
    description = "Reversion: The Escape";
    path = "${reversion1}";
    steamAppId = 270570;
    steamCdnImagesHash = "sha256-UpHHRPn+bqHzle8ZPo9G7HXl1/j6eG8ejotZIybAhkk=";
  };

  games.scummvm.games.reversion2 = {
    gameid = "reversion2";
    engineid = "wintermute";
    extra = "Steam";
    description = "Reversion: The Meeting";
    path = "${reversion2}";
    steamAppId = 281060;
    steamCdnImagesHash = "sha256-xdiWiz5zAVbqgdtmL0UuHd9H1MSxNc+4Cq4c+1F2mb0=";
  };

  games.scummvm.games.reversion3 = {
    gameid = "reversion3";
    engineid = "wintermute";
    extra = "Steam";
    description = "Reversion: The Return";
    path = "${reversion3}";
    steamAppId = 281080;
    steamCdnImagesHash = "sha256-26rO3MeqxxC1cWDUAI3Pab2uF4FHmVxY4fklgWx3F08=";
  };

  games.scummvm.games.curseOfMonkeyIsland = {
    gameid = "comi";
    engineid = "scumm";
    extra = "Steam";
    description = "The Curse of Monkey Island";
    path = "${curseOfMonkeyIsland}/ScummVM/monkey3";
    steamAppId = 730820;
    steamCdnImagesHash = "sha256-hwK2CDIEccs8M2TurPPc/d0HVCfxxnt+5XC9FXoMnV4=";
  };

  games.scummvm.games.lastExpress = {
    engineid = "lastexpress";
    extra = "Steam";
    description = "The Last Express";
    path = "${lastExpress}";
    steamAppId = 252710;
    steamCdnImagesHash = "sha256-4v1k3kbPEje3JYtuoA9pImzbfC72pzXqZsArKW1Ht44=";
  };

  games.scummvm.games.fateOfAtlantis = {
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
    path = "${fateOfAtlantis}/ATLANTIS";
    steamAppId = 6010;
    steamCdnImagesHash = "sha256-oBJqv6qpa5V/RTA3KAwmz+aJawE0OB+rDqc2spAuO0M=";
  };

  # Both classic-engine variants live inside this one Steam depot, but a
  # single Steam library entry can only launch one target; only the
  # Enhanced (V2) version below patches the real app's LaunchOptions, so V1
  # stays a synthetic (non-Steam-linked) shortcut using the same fetch.
  games.scummvm.games.maniacMansionV1 = mkManiac 1 {
    path = "${maniacMansionDl}/ScummVM/original";
  };

  games.scummvm.games.maniacMansionV2 = mkManiac 2 {
    path = "${maniacMansionDl}/ScummVM/enhanced";
    steamAppId = 529890;
    steamCdnImagesHash = "sha256-Du18nbKfyueABTzNsJmCXUuLky52PozbICbipnlXrbw=";
  };

  games.scummvm.games.lsl1 = {
    gameid = "lsl1";
    engineid = "agi";
    extra = "1.00 1987-06-01 5.25\"/3.5\" Steam";
    originalsaveload = true;
    guioptions = "sndNoSpeech gameOption1 gameOption3 gameOption4 gameOption5";
    description = "Leisure Suit Larry 1: In the Land of the Lounge Lizards";
    mousesupport = true;
    herculesfont = true;
    commandpromptwindow = true;
    path = "${lsl1}";
    steamAppId = 763970;
    steamCdnImagesHash = "sha256-nU2uBgXU2AL7XSzx5QTtQpw9kvmf8qv9RP31d4yHF4c=";
  };

  games.scummvm.games.lsl2 = mkLslGame 2 {
    palette_mods = true;
    guioptions = "sndNoSpeech gameOption1 gameOption2 gameOption3 gameOption7 gameOptionE gameOptionF gameOptionH";
    description = "Leisure Suit Larry 2: Goes Looking for Love (in Several Wrong Places)";
    path = "${lsl2}";
    steamAppId = 765840;
    steamCdnImagesHash = "sha256-5gpLiYUMnSwXEop4dHF9cN25CBO8ADLYUxC0AHcw0Ak=";
  };

  games.scummvm.games.lsl3 = mkLslGame 3 {
    guioptions = "sndNoSpeech gameOption1 gameOption2 gameOption3 gameOption7 gameOptionE gameOptionH";
    description = "Leisure Suit Larry 3: Passionate Patti in Pursuit of the Pulsating Pectorals";
    path = "${lsl3}";
    steamAppId = 765850;
    steamCdnImagesHash = "sha256-FWVRw0MxbTxYXlM/hbI/lIxh22dyUn2NcdmaKqH0kW4=";
  };

  games.scummvm.games.lsl5 = mkLslGame 5 {
    guioptions = "sndNoSpeech gameOption1 gameOption2 gameOption3 gameOptionE gameOptionH";
    description = "Leisure Suit Larry 5: Passionate Patti Does a Little Undercover Work";
    path = "${lsl5}";
    steamAppId = 765860;
    steamCdnImagesHash = "sha256-KOetaJMpMD98IDQxDeslvKfjbFvNIMmPIqfkoY0m+Io=";
  };

  games.scummvm.games.lsl6 = mkLslGame 6 {
    categoryId = "lsl6_cd";
    extra = "CD Steam";
    guioptions = "gameOption1 gameOption2 gameOption3 gameOptionE";
    description = "Leisure Suit Larry 6: Shape Up or Slip Out!";
    path = "${lsl6}";
    steamAppId = 765910;
    steamCdnImagesHash = "sha256-qilysgCGVGuzmoBfe0icxJ37m1b4XRIKD1bAStS/kVo=";
  };

  games.scummvm.games.lsl7 = mkLslGame 7 {
    enable_hq_video = true;
    guioptions = "sndNoMIDI noAspect gameOption2 gameOption9 gameOptionA gameOptionC";
    enable_black_lined_video = true;
    enable_larryscale = true;
    description = "Leisure Suit Larry 7: Love for Sail!";
    path = "${lsl7}";
    steamAppId = 765890;
    steamCdnImagesHash = "sha256-pvOwjwJUaZDuIdQa5OuWh7P0RdX9WzyCFtGzq2LScPI=";
  };

  games.scummvm.games.lastCrusade = {
    categoryId = "indy3-steam-win";
    gameid = "indy3";
    engineid = "scumm";
    extra = "Steam";
    enable_enhancements = true;
    platform = "windows";
    guioptions = "sndNoSpeech sndNoMIDI gameOption2";
    description = "Indiana Jones and the Last Crusade";
    path = "${lastCrusade}/INDY3";
    steamAppId = 32310;
    steamCdnImagesHash = "sha256-tHyEF3rgAvlUyCF8gD3UOoM8x2z1JL/XHbZtPQLkBYk=";
  };

  games.scummvm.games.sanitarium = {
    engineid = "asylum";
    description = "Sanitarium";
    path = "${sanitarium}/Data/EN";
    steamAppId = 284050;
    steamCdnImagesHash = "sha256-l3KKfVLE9KyajpfHMPspnK4Srw0+LPJmGx6Z0JXGh3g=";
  };

  games.scummvm.games.dott = {
    gameid = "tentacle";
    engineid = "scumm";
    extra = "Steam";
    description = "Day of the Tentacle";
    path = "${dott}";
    steamAppId = 388210;
    steamCdnImagesHash = "sha256-xN9rcc5XSp7V7Vusucvf9nkoYe22X5xncwyNb9WP0Es=";
  };
}
