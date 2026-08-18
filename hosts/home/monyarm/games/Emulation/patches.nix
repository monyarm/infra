{
  config,
  lib,
  getFile,
  fetchMega,
  ...
}:
let
  # DeadSkullzJr, romhacking.net topic 33506 -- restores audio the
  # Castlevania Advance Collection stripped from the GBA data (replaced
  # with external WMA playback); mgba soft-patches these in automatically.
  audioPatches = fetchMega {
    url = "https://mega.nz/folder/gRgTQSaD#ZOHtgMaveITo_f2o_WtC9Q";
    sha256 = "sha256-DlO5B/XfywYDB2xv1a38tIIbhKIeCEsO61ysy0wJF9o=";
  };
in
lib.mkIf config.games.emulation.enable {
  games.emulation.patches = {
    circleOfTheMoon = audioPatches |> getFile "Patches/CV-CotM-US-Restored-Audio.ups";
    circleOfTheMoonEu = audioPatches |> getFile "Patches/CV-CotM-EU-Restored-Audio.ups";
    circleOfTheMoonJp = audioPatches |> getFile "Patches/CV-CotM-JP-Restored-Audio.ups";

    harmonyOfDissonance = audioPatches |> getFile "Patches/CV-HoD-US-Restored-Audio.ups";
    harmonyOfDissonanceEu = audioPatches |> getFile "Patches/CV-HoD-EU-Restored-Audio.ups";
    harmonyOfDissonanceJp = audioPatches |> getFile "Patches/CV-HoD-JP-Restored-Audio.ups";

    ariaOfSorrow = audioPatches |> getFile "Patches/CV-AoS-US-Restored-Audio.ups";
    ariaOfSorrowEu = audioPatches |> getFile "Patches/CV-AoS-EU-Restored-Audio.ups";
    ariaOfSorrowJp = audioPatches |> getFile "Patches/CV-AoS-JP-Restored-Audio.ups";
  };
}
