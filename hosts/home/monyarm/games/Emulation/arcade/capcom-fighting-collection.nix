{
  config,
  lib,
  pkgs,
  fetchSteam,
  mkArcade,
  ...
}:
let
  # one game_NN.arc per romset; game_9x (Red Earth/Warzard, CPS3) is no-rom upstream
  capcomFightingCollection = fetchSteam {
    appId = 1685750;
    depotId = 1685751;
    manifestId = 6169491907705375777;
    os = "windows";
    filelist = [ "regex:^nativeDX11x64/arc/pc/game_[0-8][01]\\.arc$" ];
    sha256 = "sha256-cTI3/k+tEpoMx4L4DMex+5V0cQOxH+4JS59QrMICRRg=";
  };

  extracted =
    pkgs.runCommand "capcom-fighting-collection-extracted-roms"
      {
        nativeBuildInputs = [ pkgs.game-extraction-toolbox ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        gextoolbox tasks extract --task cfc --srcdir "${capcomFightingCollection}" --destdir $out
      '';

  extractedZip =
    name:
    pkgs.runCommand "${name}.zip"
      {
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        cp "$(find ${extracted} -name ${lib.escapeShellArg "${name}.zip"})" $out
      '';

  # all CRCs mismatch current MAME; upstream says they run in mame 0.139
  mkCfc =
    name: shortname:
    mkArcade {
      inherit name shortname;
      romset = extractedZip shortname;
      emulator = "mame2010";
    };
in
lib.mkIf config.games.emulation.enable {
  programs.steam.games = {
    CFC_DARKSTALKERS = mkCfc "Darkstalkers: The Night Warriors" "dstlku";
    CFC_NIGHT_WARRIORS = mkCfc "Night Warriors: Darkstalkers' Revenge" "nwarru";
    CFC_VAMPIRE_SAVIOR = mkCfc "Vampire Savior: The Lord of Vampire" "vsavu";
    # JP only
    CFC_VAMPIRE_HUNTER_2 = mkCfc "Vampire Hunter 2: Darkstalkers Revenge" "vhunt2";
    CFC_VAMPIRE_SAVIOR_2 = mkCfc "Vampire Savior 2: The Lord of Vampire" "vsav2";
    CFC_CYBERBOTS = mkCfc "Cyberbots: Fullmetal Madness" "cybotsu";
    # US set (spf2tu) has no valid MAME release
    CFC_SPF2T = mkCfc "Super Puzzle Fighter II Turbo" "spf2xj";
    CFC_GEM_FIGHTER = mkCfc "Super Gem Fighter Mini Mix" "sgemf";
    CFC_HSF2 = mkCfc "Hyper Street Fighter II: The Anniversary Edition" "hsf2";

    _capcomFightingCollection = {
      disabled = true;
      appId = 1685750;
    };
  };
}
