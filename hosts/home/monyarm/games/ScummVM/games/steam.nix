{ config, lib, fetchSteam, pkgs, compressScummvmGame, ... }:
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

  alphaPolaris = fetchSteam {
    appId = 405780;
    depotId = 405781;
    manifestId = 131643505400606065;
    # The depot duplicates every file under a "1280x768/" subfolder plus the
    # root; restrict to the root copy of the two .dcp packages ScummVM's
    # wintermute engine actually needs, skipping the .exe/.dll launcher files.
    filelist = [
      "regex:^(data\\.dcp|english speech pack\\.dcp)$"
    ];
    sha256 = "sha256-6fjR0okaN5u9bk87K+dyyuYAgoOEJCQk+Y7aHHXropQ=";
  };

  artOfMurder1 = fetchSteam {
    appId = 809000;
    depotId = 809002;
    manifestId = 5682759667480301174;
    sha256 = "sha256-Bj1eoqRReC4JSXcsB46P5X/layg0GQfHLHdWgdp3h6s=";
  };

  ashinaRedWitch = fetchSteam {
    appId = 1259140;
    depotId = 1259141;
    manifestId = 7304502370705097563;
    sha256 = "sha256-Jglx2yY8fhsUcGFiAhRnAtWN1GWcJED3oKzkMtZU5KA=";
  };

  barrowHillDarkPath = fetchSteam {
    appId = 520990;
    depotId = 520991;
    manifestId = 7732106364668340045;
    os = "windows";
    sha256 = "sha256-7/jYqFtPTWQdpQZtVi1oHnd9MQDlkUeRTxK/wf0SPF8=";
  };

  kingOfDragonPass = fetchSteam {
    appId = 352220;
    depotId = 352221;
    manifestId = 4517013077217297009;
    os = "windows";
    sha256 = "sha256-DU2Ypw5l8JXbt/S54kUQ2+lJYFYKyt+qQHA5H13jxIM=";
  };

  littleBigAdventureDl = fetchSteam {
    appId = 397330;
    depotId = 397338;
    manifestId = 606382556722002081;
    os = "windows";
    sha256 = "sha256-DL67wAk+lt6OwuzHR08fgeEyBwwbL+dTFL82Do0MLU4=";
  };

  # ScummVM's twine engine needs every .HQR file in one flat directory, but
  # the remaster's classic-mode text (TEXT.HQR) lives in a separate
  # CommonClassic/ folder from the rest of the classic resources in Common/.
  littleBigAdventure = pkgs.runCommand "lba-classic-merged"
    {
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "recursive";
    }
    ''
      mkdir -p $out
      cp -rs ${littleBigAdventureDl}/Common/* $out/
      cp -s ${littleBigAdventureDl}/CommonClassic/TEXT.HQR $out/
    '';

  littleBigAdventure2 = fetchSteam {
    appId = 398000;
    depotId = 398008;
    manifestId = 6898977048178414927;
    os = "windows";
    sha256 = "sha256-zrCi6LfG9pylvcIgORKG9yHbWZ9O5Q+RWHqhf2U3ekQ=";
  };

  myBigSisterRemastered = fetchSteam {
    appId = 2118540;
    depotId = 2118541;
    manifestId = 4556488665416661391;
    os = "windows";
    sha256 = "sha256-2rmsV5yuPz9N9GtKaGGjq8QEmpxGeWUMhKTQa8lx4Ik=";
  };

  reversion1 = fetchSteam {
    appId = 270570;
    depotId = 270572;
    manifestId = 842084957891672528;
    os = "windows";
    sha256 = "sha256-isPuANgN7LJxPFa7zw1DKMhbeMcwLScpklbguVUsjM0=";
  };

  reversion2 = fetchSteam {
    appId = 281060;
    depotId = 281061;
    manifestId = 5690544705524244198;
    os = "windows";
    sha256 = "sha256-YHND/jPF2FnQzN+74EJQIWoF+NrMeNTaV3DoERElOog=";
  };

  reversion3 = fetchSteam {
    appId = 281080;
    depotId = 281082;
    manifestId = 6387913456714868142;
    os = "windows";
    sha256 = "sha256-4rFadkJHhrc8nolpyXhtS+bgBLXeW/ck2nCaubLPIK0=";
  };

  curseOfMonkeyIsland =
    fetchSteam {
      appId = 730820;
      depotId = 730824;
      manifestId = 6035470325928818097;
      os = "windows";
      sha256 = "sha256-GKq8jju2Gb2U6Sc8qcSc/6fpDA+PbogFcJwXSlhzOyw=";
    }
    |> compressScummvmGame { engineid = "scumm"; };

  lastExpressDl = fetchSteam {
    appId = 252710;
    depotId = 252712;
    manifestId = 136184711608217470;
    os = "windows";
    sha256 = "sha256-6B8maDiRr7uAiTICjxndvGM5IyWvJe1xAM94NQIlEKE=";
  };

  # This Gold Edition repackages the original 1997 CD data as one zip per
  # resource category (BG/DATA/LNK/NIS/SBE/SEQ/SND/TGA) instead of shipping
  # it already unpacked; ScummVM needs it all merged into one directory.
  lastExpress = pkgs.runCommand "tle-merged"
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
    '';

  fateOfAtlantis =
    fetchSteam {
      appId = 6010;
      depotId = 6011;
      manifestId = 8584153416851488924;
      os = "windows";
      sha256 = "sha256-9l5+6zJ4ofhXw+PJBwHXITDimkPwE4xG5mhrNV8Bz0w=";
    }
    |> compressScummvmGame { engineid = "scumm"; };

  maniacMansionDl =
    fetchSteam {
      appId = 529890;
      depotId = 529891;
      manifestId = 4552517924922056300;
      os = "windows";
      sha256 = "sha256-QiFxLk+J4Q0gf74Ue95/DJyCz7ifMLnyA3C0zF5TiAE=";
    }
    |> compressScummvmGame { engineid = "scumm"; };

  lsl1 = fetchSteam {
    appId = 763970;
    depotId = 763971;
    manifestId = 6067288779454216216;
    os = "windows";
    sha256 = "sha256-DgxTdWwJBdoIAN0+6HYEEAmPnNOxQ+vUHBJIFGcKztk=";
  };

  lsl2 = fetchSteam {
    appId = 765840;
    depotId = 765841;
    manifestId = 8306539708319125167;
    os = "windows";
    sha256 = "sha256-EEZivBnySwsAwNtg5RDBxMaNHivcjTlhxI/RfF82zHU=";
  };

  lsl3 = fetchSteam {
    appId = 765850;
    depotId = 765851;
    manifestId = 7288709448665407579;
    os = "windows";
    sha256 = "sha256-yGo6Cct8zc7vzs0kiot6nbA+qdhMWnlLNB2wJE9c6/4=";
  };

  lsl5 = fetchSteam {
    appId = 765860;
    depotId = 765861;
    manifestId = 7170853141795138447;
    os = "windows";
    sha256 = "sha256-f0JNQI/RzPZ9iR3br0TTWnPtEQc8VQtBU91I4du9Vss=";
  };

  lsl6 = fetchSteam {
    appId = 765910;
    depotId = 765911;
    manifestId = 6538076485632756933;
    os = "windows";
    sha256 = "sha256-HjsVhqxHV6Wd80CEHLpiMdNou9ytZM26X7vZa6OS/6o=";
  };

  lsl7 = fetchSteam {
    appId = 765890;
    depotId = 765891;
    manifestId = 8709297254560218806;
    os = "windows";
    sha256 = "sha256-IPYjPf8gCNBvA1CPsa4O7DtezmwHjtK5QfSITve/dGY=";
  };

  lastCrusade =
    fetchSteam {
      appId = 32310;
      depotId = 32311;
      manifestId = 1410091949724710807;
      os = "windows";
      sha256 = "sha256-NakBoDPFdoF//h54rVOY2tiGI7ucKypKnKAkvyOI1BE=";
    }
    |> compressScummvmGame { engineid = "scumm"; };
in
lib.mkIf config.games.scummvm.enable {
  games.scummvm.games.alphaPolaris = {
    gameid = "alphapolaris";
    engineid = "wintermute";
    extra = "Steam";
    description = "Alpha Polaris";
    path = "${alphaPolaris}";
    steamAppId = 405780;
    steamCdnImagesHash = "sha256-IRSIDWQmwCYJyohiba2CqXYGT5kLFZ8xRlx5RvFfqkw=";
  };

  games.scummvm.games.artOfMurder1 = {
    gameid = "artofmurder1";
    engineid = "wintermute";
    extra = "Steam";
    description = "Art of Murder 1: FBI Confidential";
    path = "${artOfMurder1}";
    steamAppId = 809000;
    steamCdnImagesHash = "sha256-T48G5OvVHHQbqNzyjBecKJQczxVq40jxZ+l3lmZLKLY=";
  };

  games.scummvm.games.ashinaRedWitch = {
    gameid = "ashinaredwitch";
    engineid = "ags";
    extra = "Steam";
    description = "Ashina: The Red Witch";
    path = "${ashinaRedWitch}";
    steamAppId = 1259140;
    steamCdnImagesHash = "sha256-3PRvALJknlt/YBFT7hHJ8NwZFLks5+RHHu68Y5SX9QM=";
  };

  games.scummvm.games.barrowHillDarkPath = {
    gameid = "barrowhilldp";
    engineid = "wintermute";
    extra = "Steam";
    description = "Barrow Hill - The Dark Path";
    path = "${barrowHillDarkPath}";
    steamAppId = 520990;
    steamCdnImagesHash = "sha256-rvNIPTaRRmAxwrYK/ca+Zgy+eSNTg1OlhPBHyK7qd7w=";
  };

  games.scummvm.games.kingOfDragonPass = {
    gameid = "kingofdragonpass";
    engineid = "mtropolis";
    extra = "Steam";
    description = "King of Dragon Pass";
    path = "${kingOfDragonPass}";
    steamAppId = 352220;
    steamCdnImagesHash = "sha256-9dymPjUrTEebc2f/TNWx7SocejOjhkluvxok2E1d8N4=";
  };

  games.scummvm.games.littleBigAdventure = {
    gameid = "lba";
    engineid = "twine";
    extra = "Steam";
    description = "Little Big Adventure";
    path = "${littleBigAdventure}";
    steamAppId = 397330;
    steamCdnImagesHash = "sha256-w0fLXqpBaTk/4yl9/ijJpR4rOusXHr0kdrOZh74y2i8=";
  };

  games.scummvm.games.littleBigAdventure2 = {
    gameid = "lba2";
    engineid = "twine";
    extra = "Steam";
    description = "Little Big Adventure 2";
    path = "${littleBigAdventure2}/Common";
    steamAppId = 398000;
    steamCdnImagesHash = "sha256-39CNaSyoM8mgh9KcI8CVSxhUGXDhYUEGNBXlcUZRBO0=";
  };

  games.scummvm.games.myBigSisterRemastered = {
    gameid = "mybigsisterrm";
    engineid = "ags";
    extra = "Steam";
    description = "My Big Sister: Remastered";
    path = "${myBigSisterRemastered}";
    steamAppId = 2118540;
    steamCdnImagesHash = "sha256-Jjbon1OdIDS9jCqealZK0KTHef6GACknC/lNzv/Uxto=";
  };

  games.scummvm.games.reversion1 = {
    gameid = "reversion1";
    engineid = "wintermute";
    extra = "Steam";
    description = "Reversion: The Escape";
    path = "${reversion1}";
    steamAppId = 270570;
    steamCdnImagesHash = "sha256-PwvYym0hAzkI7IwtCErR01Rgl1m/3pL2x+eoMNsNdn4=";
  };

  games.scummvm.games.reversion2 = {
    gameid = "reversion2";
    engineid = "wintermute";
    extra = "Steam";
    description = "Reversion: The Meeting";
    path = "${reversion2}";
    steamAppId = 281060;
    steamCdnImagesHash = "sha256-fL+P+v1XgpF1ZgjGcGTi/JZZil+qbJ6GIfatJeni/BY=";
  };

  games.scummvm.games.reversion3 = {
    gameid = "reversion3";
    engineid = "wintermute";
    extra = "Steam";
    description = "Reversion: The Return";
    path = "${reversion3}";
    steamAppId = 281080;
    steamCdnImagesHash = "sha256-PwsfQOUa+ak5dwJsH/K4N4RKee8a2l+aFjtqI9465xk=";
  };

  games.scummvm.games.curseOfMonkeyIsland = {
    gameid = "comi";
    engineid = "scumm";
    extra = "Steam";
    description = "The Curse of Monkey Island";
    path = "${curseOfMonkeyIsland}/ScummVM/monkey3";
    steamAppId = 730820;
    steamCdnImagesHash = "sha256-C/genikl2VB0vIcWWzQK0FhHIwe9ArO//zoel4X7OlM=";
  };

  games.scummvm.games.lastExpress = {
    engineid = "lastexpress";
    extra = "Steam";
    description = "The Last Express";
    path = "${lastExpress}";
    steamAppId = 252710;
    steamCdnImagesHash = "sha256-IbFjMlH0HJjegftDMkE4cAcDd68cZFKfn9GGaORTCfg=";
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
    steamCdnImagesHash = "sha256-7OMty66bcTdP7pDrcmqi1ifn3AITXYdI7kx+rVVaqCE=";
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
    steamCdnImagesHash = "sha256-sF80rLlsSHcmhw9Rnhgnc5KE93hIJx3WXXF3iwsMstg=";
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
    steamCdnImagesHash = "sha256-zjHWGtpRxyPeB3TP7m+/0/ouS6cX+70JrcP6BO4HnDk=";
  };

  games.scummvm.games.lsl2 = mkLslGame 2 {
    palette_mods = true;
    guioptions = "sndNoSpeech gameOption1 gameOption2 gameOption3 gameOption7 gameOptionE gameOptionF gameOptionH";
    description = "Leisure Suit Larry 2: Goes Looking for Love (in Several Wrong Places)";
    path = "${lsl2}";
    steamAppId = 765840;
    steamCdnImagesHash = "sha256-0ik37xw4TjMeBelNWJKRUNy1vzBZJATcQpgA8ry//xE=";
  };

  games.scummvm.games.lsl3 = mkLslGame 3 {
    guioptions = "sndNoSpeech gameOption1 gameOption2 gameOption3 gameOption7 gameOptionE gameOptionH";
    description = "Leisure Suit Larry 3: Passionate Patti in Pursuit of the Pulsating Pectorals";
    path = "${lsl3}";
    steamAppId = 765850;
    steamCdnImagesHash = "sha256-st47GCH+DwjNaOJluXYjvLG3JjzNkx/vuu5BT3fpnD4=";
  };

  games.scummvm.games.lsl5 = mkLslGame 5 {
    guioptions = "sndNoSpeech gameOption1 gameOption2 gameOption3 gameOptionE gameOptionH";
    description = "Leisure Suit Larry 5: Passionate Patti Does a Little Undercover Work";
    path = "${lsl5}";
    steamAppId = 765860;
    steamCdnImagesHash = "sha256-v2qU6xMn7LghpwXtA/MM52zHWHE+Kndsd9jMYvXZygg=";
  };

  games.scummvm.games.lsl6 = mkLslGame 6 {
    categoryId = "lsl6_cd";
    extra = "CD Steam";
    guioptions = "gameOption1 gameOption2 gameOption3 gameOptionE";
    description = "Leisure Suit Larry 6: Shape Up or Slip Out!";
    path = "${lsl6}";
    steamAppId = 765910;
    steamCdnImagesHash = "sha256-jIo5Abvrd+3BTLLnkH1MzxAZj8/QmoOnD5Jickq6I74=";
  };

  games.scummvm.games.lsl7 = mkLslGame 7 {
    enable_hq_video = true;
    guioptions = "sndNoMIDI noAspect gameOption2 gameOption9 gameOptionA gameOptionC";
    enable_black_lined_video = true;
    enable_larryscale = true;
    description = "Leisure Suit Larry 7: Love for Sail!";
    path = "${lsl7}";
    steamAppId = 765890;
    steamCdnImagesHash = "sha256-AV7JUz8g6JC4nbVgcCKoiMy4kO+n8sBysYsz/Sa6tJg=";
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
    steamCdnImagesHash = "sha256-ep5NMWINRWTu4xFhsKA4a/BqEV8fByrmFkJ0KsLeeHg=";
  };
}
