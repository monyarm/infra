{
  config,
  lib,
  pkgs,
  fetchSteam,
  splitFiles,
  mkRom,
  ...
}:

let
  sadxSource = fetchSteam {
    filelist = [
      "system/SONIC.PRS"
      "system/SONIC2.PRS"
      "system/SONIC-CH.PRS"
      "system/S-TAIL2.PRS"
      "system/G-SONIC.PRS"
      "system/SPINBALL.PRS"
      "system/LABYLIN.PRS"
      "system/SONICDRI.PRS"
      "system/S-DRIFT2.PRS"
      "system/TAILSADV.PRS"
      "system/SKYPAT.PRS"
      "system/MBMACHIN.PRS"
      "system/SONICTAI.PRS"
      "system/SONIC_TT.PRS"
    ];
    appId = 71250;
    depotId = 71251;
    manifestId = 3248206210397098900;
    sha256 = "sha256-RXVN2hQbU5Zn4SKSnJ72Qy2sOf9NbV6NAmL4vs0ZDfY=";
  };

  sadxDecompressed =
    pkgs.runCommand "sadx-gamegear-decompressed"
      {
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
        nativeBuildInputs = [ pkgs.puyo-tools ];
      }
      ''
        mkdir -p work out
        cp "${sadxSource}"/system/*.PRS work/
        cd work
        PuyoToolsCli compression decompress --input "*.PRS" --overwrite
        for f in *.PRS; do
          name=$(basename "$f" .PRS)
          mv "$f" "../out/$name.gg"
        done
        mv ../out $out
      '';

  prsName = name: "${name}.gg";

  sadxRoms = lib.listToAttrs (
    lib.zipListsWith lib.nameValuePair
      [
        "sonic1"
        "sonic2"
        "sonicChaos"
        "sonicTripleTrouble"
        "sonicBlast"
        "sonicSpinball"
        "sonicLabyrinth"
        "sonicDrift"
        "sonicDrift2"
        "tailsAdventure"
        "tailsSkypatrol"
        "drRobotnikMeanBeanMachine"
        "sonicAndTails"
        "sonicAndTails2"
      ]
      (
        splitFiles (map prsName [
          "SONIC"
          "SONIC2"
          "SONIC-CH"
          "S-TAIL2"
          "G-SONIC"
          "SPINBALL"
          "LABYLIN"
          "SONICDRI"
          "S-DRIFT2"
          "TAILSADV"
          "SKYPAT"
          "MBMACHIN"
          "SONICTAI"
          "SONIC_TT"
        ]) sadxDecompressed
      )
  );
in
lib.mkIf config.games.emulation.enable {
  games.emulation.roms = {
    inherit (sadxRoms)
      sonic1
      sonic2
      sonicChaos
      sonicTripleTrouble
      sonicBlast
      sonicSpinball
      sonicLabyrinth
      sonicDrift
      sonicDrift2
      tailsAdventure
      tailsSkypatrol
      drRobotnikMeanBeanMachine
      sonicAndTails
      sonicAndTails2
      ;
  };

  programs.steam.games = with config.games.emulation.roms; {
    SONIC_1 = mkRom {
      name = "Sonic the Hedgehog";
      rom = sonic1;
      system = "gamegear";
    };
    SONIC_2 = mkRom {
      name = "Sonic the Hedgehog 2";
      rom = sonic2;
      system = "gamegear";
    };
    SONIC_CHAOS = mkRom {
      name = "Sonic Chaos";
      rom = sonicChaos;
      system = "gamegear";
    };
    SONIC_TRIPLE_TROUBLE = mkRom {
      name = "Sonic Triple Trouble";
      rom = sonicTripleTrouble;
      system = "gamegear";
    };
    SONIC_BLAST = mkRom {
      name = "Sonic Blast";
      rom = sonicBlast;
      system = "gamegear";
    };
    SONIC_SPINBALL = mkRom {
      name = "Sonic Spinball";
      rom = sonicSpinball;
      system = "gamegear";
    };
    SONIC_LABYRINTH = mkRom {
      name = "Sonic Labyrinth";
      rom = sonicLabyrinth;
      system = "gamegear";
    };
    SONIC_DRIFT = mkRom {
      name = "Sonic Drift";
      rom = sonicDrift;
      system = "gamegear";
    };
    SONIC_DRIFT_2 = mkRom {
      name = "Sonic Drift 2";
      rom = sonicDrift2;
      system = "gamegear";
    };
    TAILS_ADVENTURE = mkRom {
      name = "Tails Adventure";
      rom = tailsAdventure;
      system = "gamegear";
    };
    TAILS_SKYPATROL = mkRom {
      name = "Tails' Skypatrol";
      rom = tailsSkypatrol;
      system = "gamegear";
    };
    DR_ROBOTNIK_MEAN_BEAN_MACHINE = mkRom {
      name = "Dr. Robotnik's Mean Bean Machine";
      rom = drRobotnikMeanBeanMachine;
      system = "gamegear";
    };

    SADX_SOURCE = {
      disabled = true;
      name = "Sonic Adventure DX";
      steamAppId = 71250;
    };
  };
}
