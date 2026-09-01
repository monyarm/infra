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
  # roms baked as byte ranges inside capcom_disney_afternoon.exe; mmlc-dac-extractor pulls them out
  DAC = fetchSteam {
    filelist = [ "capcom_disney_afternoon.exe" ];
    appId = 525040;
    depotId = 525041;
    manifestId = 5256007417415092342;
    sha256 = "sha256-kOrgNdOBJpLBkseOX2THJ4/KPj+Ej+z6FZILbG33rVM=";
  };

  dacExtracted =
    pkgs.runCommand "dac-extracted-roms"
      {
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        mkdir -p $out
        cp "${DAC}/capcom_disney_afternoon.exe" $out/capcom_disney_afternoon.exe
        cd $out
        ${pkgs.mmlc-dac-extractor}/bin/dac-extractor
        rm capcom_disney_afternoon.exe
      '';

  # Extracted ROMs have all Nintendo references removed, not byte-identical to original cartridges.
  # No known IPS patches exist to restore them.
  dacRomNames = [
    "Chip 'n Dale - Rescue Rangers (Disney Afternoon Collection).nes"
    "Chip 'n Dale - Rescue Rangers 2 (Disney Afternoon Collection).nes"
    "Darkwing Duck (Disney Afternoon Collection).nes"
    "DuckTales (Disney Afternoon Collection).nes"
    "DuckTales 2 (Disney Afternoon Collection).nes"
    "TaleSpin (Disney Afternoon Collection).nes"
  ];

  dacRoms = lib.listToAttrs (
    lib.zipListsWith lib.nameValuePair [
      "chipNDale1"
      "chipNDale2"
      "darkwingDuck"
      "duckTales1"
      "duckTales2"
      "taleSpin"
    ] (splitFiles dacRomNames dacExtracted)
  );
in
lib.mkIf config.games.emulation.enable {
  games.emulation.roms = {
    inherit (dacRoms)
      chipNDale1
      chipNDale2
      darkwingDuck
      duckTales1
      duckTales2
      taleSpin
      ;
  };

  programs.steam.games = with config.games.emulation.roms; {
    CHIP_N_DALE_1 = mkRom {
      name = "Chip 'n Dale - Rescue Rangers";
      rom = chipNDale1;
      system = "nes";
    };
    CHIP_N_DALE_2 = mkRom {
      name = "Chip 'n Dale - Rescue Rangers 2";
      rom = chipNDale2;
      system = "nes";
    };
    DARKWING_DUCK = mkRom {
      name = "Darkwing Duck";
      rom = darkwingDuck;
      system = "nes";
    };
    DUCKTALES_1 = mkRom {
      name = "DuckTales";
      rom = duckTales1;
      system = "nes";
    };
    DUCKTALES_2 = mkRom {
      name = "DuckTales 2";
      rom = duckTales2;
      system = "nes";
    };
    TALE_SPIN = mkRom {
      name = "TaleSpin";
      rom = taleSpin;
      system = "nes";
    };

    DISNEY_AFTERNOON_COLLECTION_SOURCE = {
      disabled = true;
      name = "Disney Afternoon Collection";
      steamAppId = 525040;
    };
  };
}
