{
  config,
  lib,
  getFile,
  fetchMega,
  patchFile,
  mkRom,
  ...
}:
let
  inherit (config.games.emulation) marchive;

  # DeadSkullzJr, romhacking.net topic 33506 -- restores audio the
  # Castlevania Advance Collection stripped from the GBA data (replaced
  # with external WMA playback); mgba soft-patches these in automatically.
  audioPatches = fetchMega {
    url = "https://mega.nz/folder/gRgTQSaD#ZOHtgMaveITo_f2o_WtC9Q";
    sha256 = "sha256-DlO5B/XfywYDB2xv1a38tIIbhKIeCEsO61ysy0wJF9o=";
  };

  cotm = {
    us = audioPatches |> getFile "Patches/CV-CotM-US-Restored-Audio.ups";
    eu = audioPatches |> getFile "Patches/CV-CotM-EU-Restored-Audio.ups";
    jp = audioPatches |> getFile "Patches/CV-CotM-JP-Restored-Audio.ups";
  };
  hod = {
    us = audioPatches |> getFile "Patches/CV-HoD-US-Restored-Audio.ups";
    eu = audioPatches |> getFile "Patches/CV-HoD-EU-Restored-Audio.ups";
    jp = audioPatches |> getFile "Patches/CV-HoD-JP-Restored-Audio.ups";
  };
  aos = {
    us = audioPatches |> getFile "Patches/CV-AoS-US-Restored-Audio.ups";
    eu = audioPatches |> getFile "Patches/CV-AoS-EU-Restored-Audio.ups";
    jp = audioPatches |> getFile "Patches/CV-AoS-JP-Restored-Audio.ups";
  };

  # Filenames say "patch" but these are the actual ROMs (game's own
  # internal build-tag naming), just missing the collection's WMA-replaced
  # enhanced audio. Restored via UPS sidecar patches.
  patchedGbaRoms = {
    circleOfTheMoon =
      marchive.castlevaniaAdvance |> getFile "01_Circle_US.patch_210614m.bin" |> patchFile cotm.us;
    harmonyOfDissonance =
      marchive.castlevaniaAdvance |> getFile "02_Byakuya_US.patch_210520m.bin" |> patchFile hod.us;
    ariaOfSorrow =
      marchive.castlevaniaAdvance |> getFile "03_Akatsuki_US.patch_210623m.bin" |> patchFile aos.us;
  };
in
lib.mkIf config.games.emulation.enable {
  games.emulation.roms = {
    inherit (patchedGbaRoms) circleOfTheMoon harmonyOfDissonance ariaOfSorrow;

    # regional variants, registered for enumeration only -- not launchable
    circleOfTheMoonEu =
      marchive.castlevaniaAdvance |> getFile "01_Circle_EU.patch_210614m.bin" |> patchFile cotm.eu;
    circleOfTheMoonJp =
      marchive.castlevaniaAdvance |> getFile "01_Circle_JP.patch_210623m.bin" |> patchFile cotm.jp;
    harmonyOfDissonanceEu =
      marchive.castlevaniaAdvance |> getFile "02_Byakuya_EU.patch_210520m.bin" |> patchFile hod.eu;
    harmonyOfDissonanceJp =
      marchive.castlevaniaAdvance |> getFile "02_Byakuya_JP.patch_210520m.bin" |> patchFile hod.jp;
    ariaOfSorrowEu =
      marchive.castlevaniaAdvance |> getFile "03_Akatsuki_EU.patch_210623m.bin" |> patchFile aos.eu;
    ariaOfSorrowJp =
      marchive.castlevaniaAdvance |> getFile "03_Akatsuki_JP.patch_210623m.bin" |> patchFile aos.jp;
  };

  programs.steam.games = with config.games.emulation.roms; {
    CIRCLE_OF_THE_MOON = mkRom {
      name = "Castlevania: Circle of the Moon";
      rom = circleOfTheMoon;
      system = "gba";
    };
    HARMONY_OF_DISSONANCE = mkRom {
      name = "Castlevania: Harmony of Dissonance";
      rom = harmonyOfDissonance;
      system = "gba";
    };
    ARIA_OF_SORROW = mkRom {
      name = "Castlevania: Aria of Sorrow";
      rom = ariaOfSorrow;
      system = "gba";
    };
  };
}
