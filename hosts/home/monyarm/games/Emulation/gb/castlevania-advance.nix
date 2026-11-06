{
  config,
  lib,
  pkgs,
  getFile,
  fetchMega,
  fetchGDrive,
  rename,
  patchFile,
  mkRom,
  sources,
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

  aosDefinitivePatch =
    fetchGDrive sources.patch.ariaofsorrowDefinitive
    |> rename "Aria of Sorrow - Definitive Edition v1.3.ips";

  hodImprovementPatch =
    let
      patchPath =
        lib.findFirst (p: lib.hasSuffix " Localization Fix C-Whip RMenu.ips" p)
          (throw "harmonyOfDissonanceImprovement: Localization Fix C-Whip RMenu.ips not found")
          sources.patch.harmonyOfDissonanceImprovement.files;
    in
    fetchGDrive sources.patch.harmonyOfDissonanceImprovement |> getFile patchPath;

  patches = {
    cotmUsAudio = cotm.us;
    cotmEuAudio = cotm.eu;
    cotmJpAudio = cotm.jp;
    hodUsAudio = hod.us;
    hodEuAudio = hod.eu;
    hodJpAudio = hod.jp;
    aosUsAudio = aos.us;
    aosEuAudio = aos.eu;
    aosJpAudio = aos.jp;
    aosDefinitive = aosDefinitivePatch;
    hodImprovement = hodImprovementPatch;
  };

in
lib.mkIf config.games.emulation.enable {
  games.emulation.roms = {
    # Filenames say "patch" but these are the actual ROMs (game's own
    # internal build-tag naming), just missing the collection's WMA-replaced
    # enhanced audio. Restored via UPS sidecar patches.
    circleOfTheMoon =
      marchive.castlevaniaAdvance
      |> getFile "01_Circle_US.patch_210614m.bin"
      |> rename "CircleOfTheMoon.gba"
      |> patchFile config.games.emulation.patches.cotmUsAudio;
    harmonyOfDissonance =
      marchive.castlevaniaAdvance
      |> getFile "02_Byakuya_US.patch_210520m.bin"
      |> rename "HarmonyOfDissonance.gba"
      |> patchFile config.games.emulation.patches.hodUsAudio;
    ariaOfSorrow =
      marchive.castlevaniaAdvance
      |> getFile "03_Akatsuki_US.patch_210623m.bin"
      |> rename "AriaOfSorrow.gba"
      |> patchFile config.games.emulation.patches.aosUsAudio;

    # regional variants, registered for enumeration only -- not launchable
    circleOfTheMoonEu =
      marchive.castlevaniaAdvance
      |> getFile "01_Circle_EU.patch_210614m.bin"
      |> rename "CircleOfTheMoonEu.gba"
      |> patchFile config.games.emulation.patches.cotmEuAudio;
    circleOfTheMoonJp =
      marchive.castlevaniaAdvance
      |> getFile "01_Circle_JP.patch_210623m.bin"
      |> rename "CircleOfTheMoonJp.gba"
      |> patchFile config.games.emulation.patches.cotmJpAudio;
    harmonyOfDissonanceEu =
      marchive.castlevaniaAdvance
      |> getFile "02_Byakuya_EU.patch_210520m.bin"
      |> rename "HarmonyOfDissonanceEu.gba"
      |> patchFile config.games.emulation.patches.hodEuAudio;
    harmonyOfDissonanceJp =
      marchive.castlevaniaAdvance
      |> getFile "02_Byakuya_JP.patch_210520m.bin"
      |> rename "HarmonyOfDissonanceJp.gba"
      |> patchFile config.games.emulation.patches.hodJpAudio;
    ariaOfSorrowEu =
      marchive.castlevaniaAdvance
      |> getFile "03_Akatsuki_EU.patch_210623m.bin"
      |> rename "AriaOfSorrowEu.gba"
      |> patchFile config.games.emulation.patches.aosEuAudio;
    ariaOfSorrowJp =
      marchive.castlevaniaAdvance
      |> getFile "03_Akatsuki_JP.patch_210623m.bin"
      |> rename "AriaOfSorrowJp.gba"
      |> patchFile config.games.emulation.patches.aosJpAudio;
  };

  games.emulation.patches = patches;

  programs.steam.games =
    with config.games.emulation.roms;
    with config.games.emulation.patches;
    {
      CIRCLE_OF_THE_MOON = mkRom {
        name = "Castlevania: Circle of the Moon";
        rom = circleOfTheMoon;
        system = "gba";
        images = {
          icon = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/icon/b58d60916e2916392e997a6a1d78225e.png";
            sha256 = "sha256-kRi9V88JwxdedNBXAyUFIxyYZ8AqCEvukJp4tsLONU8=";
          };
          hero = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/hero/d90b1c32b55f731e8a2072bfad782fdd.jpg";
            sha256 = "sha256-RaMjNPubx3PmuqQGLqm/liND5uj15SvF87S5lXw1t+g=";
          };
          wide = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/b18013a94e486e26ad4a82f6e8394ddd.png";
            sha256 = "sha256-VM9xjt3wXexoHGYdTIMITnkNgy/h4B+ZtnKUNfci2Es=";
          };
          logo = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/logo/b30958093daeed059670b35173654dc9.png";
            sha256 = "sha256-xaIBo6dMxVtxjlk4g0lcwVzm3whhGPaqxCKetLr10sg=";
          };
          grid = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/98d18f067382e282b98734bf528b4178.png";
            sha256 = "sha256-//TIhsZznaJ3Jb7KzxRTCU9naeAVHnJBISBc4E5esqU=";
          };
        };
      };
      HARMONY_OF_DISSONANCE = mkRom {
        name = "Castlevania: Harmony of Dissonance";
        rom = harmonyOfDissonance;
        system = "gba";
        patch = [ hodImprovement ];
        images = {
          icon = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/icon/80e026bcd09f75afdeadb5effc5ea9da.png";
            sha256 = "sha256-DcBNBmom6st9ILynU4FKY44ZLl7iObgogAlNieI2gAI=";
          };
          hero = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/hero/12d836bf64839f987338414ccbec657f.png";
            sha256 = "sha256-zXsbFqZ7kwJCimcw4oeEoVnqZ5EKitXLVGuyYZBFDWg=";
          };
          wide = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/8b30d77bb6a3144c34f4280585313c9e.png";
            sha256 = "sha256-yhICnsRaCqGPy/qBQzd+nXDhejNJ6sC0eTbvMacbuoI=";
          };
          logo = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/logo/81ed4d7130d22722194f33b1ab0f937c.png";
            sha256 = "sha256-6eLDG4x1b5C7Wd9URTeXg+aDRUjvImufN6nxaIxWcDw=";
          };
          grid = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/5fb2c257c2f52d3592bc27f861e66d7c.png";
            sha256 = "sha256-Ccbsvt0s3kXl5J+GryFCY4TyBEnhEBnTOFsa8/w+a9Q=";
          };
        };
      };
      ARIA_OF_SORROW = mkRom {
        name = "Castlevania: Aria of Sorrow";
        rom = ariaOfSorrow;
        system = "gba";
        patch = [ aosDefinitive ];
        images = {
          hero = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/hero/18b67afe27829441b0845c36bfbc30d1.png";
            sha256 = "sha256-BpOhMVIn2wNCiz5cdrRucry+w6X9TQUbcyksfb9Ceug=";
          };
          wide = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/2d13dd919b0ec4519c4a0967c4c7cd47.png";
            sha256 = "sha256-NVb/hbEi4y+ERep70wTNqZHKDx+V3JST/7HoqpMAnz0=";
          };
          logo = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/logo/2831648e9dac9b4618a0ab63d6a81e64.png";
            sha256 = "sha256-JH6DFplEnJDt++rhzXxshLHBRlPtIByMW4HQVGwlhcA=";
          };
          icon = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/icon/3c965b7c5ab792d1e5ea0ad33e2959a0.png";
            sha256 = "sha256-M3kiXdYpcmU9b00K0xHq4yPjfSObYtKk5voZgeykW+U=";
          };
          grid = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/a9fcbba7da26095ce5010a39b8a36509.png";
            sha256 = "sha256-YqzBbzKOCZ6cN0zjfLp/TUDc28bbTWcTP8bTZmAU31E=";
          };
        };
      };
    };
}
