{
  config,
  lib,
  mkRom,
  getFile,
  ...
}:
let
  inherit (config.games.emulation) marchive;
in
lib.mkIf config.games.emulation.enable {
  games.emulation.roms = {
    contraGb = marchive.contra |> getFile "boy_Contra.gb";
    operationC = marchive.contra |> getFile "boy_OperationC.gb";

    castlevaniaLegends = marchive.castlevaniaAnniversary |> getFile "boy_01_DraculaDensetsu.gb";
    castlevaniaBelmontsRevenge =
      marchive.castlevaniaAnniversary |> getFile "boy_02_DraculaDensetsu2.gb";

    probotectorGb = marchive.contra |> getFile "boy_Probotector.gb";

    # regional variants, registered for enumeration only -- not launchable.
    # "_fake_rom" is MArchiveBatchTool's own naming, not dummy data -- valid
    # GB headers/sizes, just a different revision than castlevaniaLegends/
    # castlevaniaBelmontsRevenge.
    castlevaniaAdventureUs =
      marchive.castlevaniaAnniversary |> getFile "boy_us_01_Castlevaniaadv1_fake_rom.gb";
    castlevaniaBelmontsRevengeUs =
      marchive.castlevaniaAnniversary |> getFile "boy_us_02_Castlevaniaadv2_fake_rom.gb";

    # GBA -- filenames say "patch" but these are the actual ROMs (game's own
    # internal build-tag naming), just missing the collection's WMA-replaced
    # enhanced audio. games.emulation.patches carries the UPS sidecar that
    # restores it.
    circleOfTheMoon = marchive.castlevaniaAdvance |> getFile "01_Circle_US.patch_210614m.bin";
    harmonyOfDissonance = marchive.castlevaniaAdvance |> getFile "02_Byakuya_US.patch_210520m.bin";
    ariaOfSorrow = marchive.castlevaniaAdvance |> getFile "03_Akatsuki_US.patch_210623m.bin";

    circleOfTheMoonEu = marchive.castlevaniaAdvance |> getFile "01_Circle_EU.patch_210614m.bin";
    circleOfTheMoonJp = marchive.castlevaniaAdvance |> getFile "01_Circle_JP.patch_210623m.bin";
    harmonyOfDissonanceEu = marchive.castlevaniaAdvance |> getFile "02_Byakuya_EU.patch_210520m.bin";
    harmonyOfDissonanceJp = marchive.castlevaniaAdvance |> getFile "02_Byakuya_JP.patch_210520m.bin";
    ariaOfSorrowEu = marchive.castlevaniaAdvance |> getFile "03_Akatsuki_EU.patch_210623m.bin";
    ariaOfSorrowJp = marchive.castlevaniaAdvance |> getFile "03_Akatsuki_JP.patch_210623m.bin";
  };

  programs.steam.games =
    with config.games.emulation.roms;
    let
      inherit (config.games.emulation) patches;
    in
    {
      CONTRA_GB = mkRom {
        name = "Contra";
        rom = contraGb;
        system = "gb";
      };
      OPERATION_C = mkRom {
        name = "Operation C";
        rom = operationC;
        system = "gb";
      };

      CASTLEVANIA_LEGENDS = mkRom {
        name = "Castlevania Legends";
        rom = castlevaniaLegends;
        system = "gb";
      };
      CASTLEVANIA_BELMONTS_REVENGE = mkRom {
        name = "Castlevania II: Belmont's Revenge";
        rom = castlevaniaBelmontsRevenge;
        system = "gb";
      };

      CIRCLE_OF_THE_MOON = mkRom {
        name = "Castlevania: Circle of the Moon";
        rom = {
          rom = circleOfTheMoon;
          ups = patches.circleOfTheMoon;
        };
        system = "gba";
      };
      HARMONY_OF_DISSONANCE = mkRom {
        name = "Castlevania: Harmony of Dissonance";
        rom = {
          rom = harmonyOfDissonance;
          ups = patches.harmonyOfDissonance;
        };
        system = "gba";
      };
      ARIA_OF_SORROW = mkRom {
        name = "Castlevania: Aria of Sorrow";
        rom = {
          rom = ariaOfSorrow;
          ups = patches.ariaOfSorrow;
        };
        system = "gba";
      };
    };
}
