{ pkgs, fetchSteamCards, ... }:
let
  dnd50thZip = pkgs.fetchzip {
    url = "https://media.dndbeyond.com/compendium-images/marketing/50th-anniversary-desktop-wallpapers.zip";
    sha256 = "191zys4qav2kn4n23nxdqcxi8zqm8yfznzjz2cfifisqymvihgdk";
  };

  dndHolidayHaulZip = pkgs.fetchzip {
    url = "https://media.dndbeyond.com/compendium-images/marketing/dnd-holiday-haul-wallpaper.zip";
    hash = "sha256-/qdRSo6WKp/57ULOsqyTmQtuWiHj5dbYBmTgu82UkFw=";
    stripRoot = false;
  };
in
{
  dnd50thDesktop = "${dnd50thZip}/Desktop Wallpaper/D&D_50th_Wallpaper_Desktop-3840x2140.jpg";
  dndHolidayHaul = "${dndHolidayHaulZip}/D&D Holiday Wallpaper_1920x1080 1.jpg";

  PHB = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/2pui27Vw8m7PTg7qbn7Iez/5049ae63f58ee50f1e47cd0fe2ce9c72/PHB_1920x1080.jpeg";
    hash = "sha256-YyCpc1LAwQBXTS3r/C6I3DRX8XBLkezybyBIdh8sIbk=";
  };

  MM = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/60I3oouRXM8rbBUFfRHK4s/cbcacd497d8dd2c8d724cb8d6463bda9/MM_1920x1080.jpeg";
    hash = "sha256-Cec7O9f/WyH+vgeuTvlyhnXAsNQ1ahUvjgBri6UwQbM=";
  };

  SCAGWallpaper = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/5Laaorxyb0e56mbCqFWc65/ca694253a256d0866c7fdfa3b85f7ef4/SCAG_1920x1080_Wallpaper.jpeg";
    hash = "sha256-/NcuGqTCfxTUyWzYhKbQlvOElHFzGstKzwH2HYDufXk=";
  };

  voloNewWallpaper = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/4ESOCp8aYFNJkSY5BG5yag/4799a4fe39a964459a7ad7031687ac0c/Volo_1920x1080_New_Wallpaper.jpeg";
    hash = "sha256-3+y5daU4QiNauWq0h+VIW0ZfmfhlbulW11nmzO5a7t4=";
  };

  xanatharsWallpaper = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/IDkWUu234TPEXN9SaaTUs/8bf83fadc45ab59c0c4593f4d06d9fdf/Xanathars_Wallpaper_1920x1080.jpeg";
    hash = "sha256-skNjqrFsvkW0waNU3EmAYRDU5dd/esG90JuF1OVGu/o=";
  };

  ToFWallpapertemplate = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/4GipnQzbldATrZFnZHpUv7/a6dd8da893f01782497fbca773d74304/ToF_1920x1080_WallpaperTemplate.jpeg";
    hash = "sha256-VkEoh3vIk1mFV8lAjdOowvfKM8MZTsV3By1OaaSQTYQ=";
  };

  TCoEWallpaper = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/3lwEFqFyhil8tJ3FzGFRrR/5286da6768e05ecee6ade0d0486cd366/TCoE_1920x1080_Wallpaper.jpeg";
    hash = "sha256-p9Ad7muDfhT8rvGRv2pH9fZSpfjxaECTwi/Cp20MYNw=";
  };

  fizbanWallpaper1 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/42WIy9aVykeIS7e9HEbOoz/c8ee80523a912c3c9bd26323e5be2bc8/Fizban_1920x1080_Wallpaper1.jpg";
    hash = "sha256-XG0VKVHzgiFgm6xkbI5qcgCg/gt+nDmpkaUSH76GhOI=";
  };

  fizbanWallpaper2 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/8rypu7wX9ckGvri1e8Xwc/3cc40918c7622447c889e28c2878e097/Fizban_1920x1080_Wallpaper2.jpg";
    hash = "sha256-mRCHPkKdFN3T4cOOpicCbiWKoiO4yMYd94JXfiiusGY=";
  };

  unknown8878721400 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/3lasUZghGHa2IOsxNZSFJB/14b204bfdbd94e83f19792ae6beed767/8878721400_1920x1080.jpg";
    hash = "sha256-xyXrr8NxIW9EHV0N2/J5ZMlJIHNl5JzyNRze1/II2rg=";
  };

  yawningPortalWallpaper = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/59qrpLasCXi8B0OG0qIGXS/4edfc194a66d269c76d6691f7641debe/Yawning_Portal_1920x1080_Wallpaper.jpeg";
    hash = "sha256-TIm6Sk+5O1mDBtcIvIb+8vt1BfaKDZHlzYSJDXF/pFs=";
  };

  wildemountWallpaper = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/2J3LTW8gSiTbxstAWRxo0l/4fccdf3af0725a08abd14fa1fa5068f5/Wildemount_1920x1080_Wallpaper.jpeg";
    hash = "sha256-T49uagn/NjzTjDlhk0O1Ydf39hgTAQL8Wfzayx3VdqQ=";
  };

  tiamat = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/1j8hlQevVWJ5Kicc4i4I97/e635d7510203c6b15168339385c767c0/Tiamat_1920x1080.jpeg";
    hash = "sha256-hUm0WtWyVB9s5l5pDZPc2sCBjcNAs3QMh6AgGOCG4Rs=";
  };

  greenFaceMaskExpansionWallpapertemplate = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/6hOxApYJoERWhxRRAkBNDr/cea7d973d4b526edf0a4ff479b48f6c7/GreenFaceMask_Expansion_1920x1080_WallpaperTemplate.jpeg";
    hash = "sha256-QCYsW5d4Z2TRX0BZSwKxeN/UVQqYHbiDi67hGDJJCJo=";
  };

  MOTWallpaper = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/6tprxZIRx9GY5nChF4i1dg/84d5926f5754d21f5134a63ff991a78c/MOT_1920x1080_Wallpaper.jpeg";
    hash = "sha256-ZKAED/oxTBmMtor4S674U9N08vOFXZRyH7Eu3vQ72nI=";
  };

  curseofStrahdThroneWallpaper = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/6wvq9Q94McXF2Ii7RC2Mvw/ded1f53a730cc09f2cd7713a555d605e/CurseofStrahd_Throne_1920x1080_Wallpaper.jpeg";
    hash = "sha256-YKliOAOk2dnhbzrC0gSBxguVF0DrkxUhoQ36irzRljs=";
  };

  stormGiantWallpapertemplate0 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/7zqsEgRZKPn0sDfZQGMAcU/80938332599b80239f978755f1016121/Storm-Giant_1920x1080_WallpaperTemplate_0.jpeg";
    hash = "sha256-IBkq48ikVVToYA74midYzfOXg/INnuZFsi8weDT182M=";
  };

  saltmarshWallpapertemplate = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/4TcVaNoDqpYwpy4Hvti2Nt/a8502d12a90d5b92745dd8b827c064ef/Saltmarsh_1920x1080_WallpaperTemplate.jpeg";
    hash = "sha256-K7aQiaiFwwnuOUZhqdJyA6a7lEG8+tNjW3VNGqVayN0=";
  };

  madMageExpansionWallpapertemplate = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/3M3i1fX4jBztQ6MAUWNmra/9ac3ee6576f8aebfec1a5e093f55de7b/MadMage_Expansion_1920x1080_WallpaperTemplate.jpeg";
    hash = "sha256-OP1gqHPQWrNUg0OPOgNLzf4DtK0SoBYBpZiMB97IF9c=";
  };

  DNDIdrfmWall1 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/4bGGY1O1d4bbKzamqLakpR/94114da87041ecd73a8567a0af50b798/dnd_idrfm_wall1_1920.jpeg";
    hash = "sha256-F/IhqGEvvIs1cPlcIatZXS1zBblyw1hUU71EVXnDsTg=";
  };

  eberron321888WallpaperOverlay = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/3J9rFv4M7K9ZzhGY4qvl62/23840642e24cf67f1e9dbaa61d77a8fa/Eberron-321888_1920x1080_Wallpaper_Overlay.jpeg";
    hash = "sha256-xg3gGwLLapvOVgVqBrqwXHPihdmHa2wiP+gFPvdGrlg=";
  };

  candlekeepMysteriesAltWallpaper = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/4eEoZ796wjnlCIxi5IbjUZ/950d29f5e30472de96f7d947f7a2a1da/CandlekeepMysteries_alt_1920x1080_Wallpaper.jpeg";
    hash = "sha256-VLOZfRkTMKs16Wubi6SuqTmNU0cHUtYrP4MgjddVCes=";
  };

  candlekeepMysteriesWallpaper = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/39chF1e4vVI7Zq61LUUxVg/bd588361c17baee6e4e8bda4c3f14ba0/CandlekeepMysteries_1920x1080_Wallpaper.jpeg";
    hash = "sha256-XYzs3nhVeKLhAjq2HgsG8UrX5QwtXUtZ2FBE30j2xes=";
  };

  strixhavenWallpaper = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/1mdl0MqZMCCAX0HLuRm9OW/95bc6941c18c629e32baed193640a1b5/Strixhaven_1920x1080_Wallpaper.jpg";
    hash = "sha256-5zvB9ScgK4sdNS+Fzx6JKQM+R3iolDphp8ukAdbTLd0=";
  };

  strixhavenAltWallpaper = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/3aRBCv1A0UrONApzzWqUfr/abcdbf9899bb94dccdec9f255768d54a/StrixhavenAlt_1920x1080_Wallpaper.jpg";
    hash = "sha256-EbEsxfQYazBMEcJQEFBKr66nyq+FhuE9YPXcL2Ll6EY=";
  };

  VRGWallpaper = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/11s9BVfEyp1qLpjWIs61N5/c39bc6dcd70f9c3338193ad18a8a84e9/VRG_1920x1080_Wallpaper.jpg";
    hash = "sha256-SQwEU6k7jwu4lwrUxXDuIawiLcV/rqdAQBlRbgqSKGc=";
  };

  JAM1 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/7CsETrPY1RJ0Men0Hgsx7o/d77d42674023db8855ddb11f428e2ee9/1920x1080-jam-1.jpg";
    hash = "sha256-MTm07sYlsUzYlbbVTbGk6ctlH5ox3Z7HbRm37Bky92s=";
  };

  JAM2 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/6YCOSzDTOo4Cr99vMinxUD/603f7a83df1a81f3c4c42eb054443295/1920x1080-jam-2.jpg";
    hash = "sha256-AO0CGNyBg1VS+Dj3PGIAi0GCX055e+DD4NNevGYwFQQ=";
  };

  JAM3 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/6rx30JN4fKkSaE33ah1TcW/532125173c84ba60a319b2d362b00122/1920x1080-jam-3.jpg";
    hash = "sha256-50Gy+Yu9iQsrQfqgkPMwMsIYSU6CDx1Yo1/hyArq7CU=";
  };

  kubrick = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/69VVMBBFaqmUfQPJ6GioOP/ff21b7b867eea95661e3f9a5aa8b2e6b/1920x1080-kubrick.jpg";
    hash = "sha256-292IBl5ulQZxMNMxOvNrEJ5ooTlkklstaC8Q4dA5V4Y=";
  };

  witchlight1 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/4nySNNueGGsRilOj7bbOhw/f196cef927f3b3bf4ae7a2d32c383a67/Witchlight_1920x1080_1.jpg";
    hash = "sha256-oS0mzIv67GInYD9NoyWhTKPjWJqFh9zaYlttO4mPd3o=";
  };

  witchlight2 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/xQ3870CQJVgXieD6fFuFL/f07251b8e4a833096569b5e1fcce5599/Witchlight_1920x1080_2.jpg";
    hash = "sha256-eHtQNptTXc4wilwOBoap29M9HF6JSPI8mmecLgEFnFA=";
  };

  DRA39 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/3P7j8jwybAqbsA6QCLRivz/a4506c96a739069f2c37973eb1a59261/dra39_1920x1080.jpg";
    hash = "sha256-PxDA5+yBzMOKRCHCotEetu9I0QZrtAZlG95EMFYuUR0=";
  };

  zoomZodiac = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/2iNbazqfA6JueDgB54ZI2y/db69bc176e91a5439bef45c8b51364be/zoom-1920x1080-zodiac.jpg";
    hash = "sha256-3WL6LGqE141fzRiX98kjvba2697eMiseSagc45ICOWI=";
  };

  zodiac2 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/5EIvzePgmOvsxa4FZgtQs9/cd5c60492ecef1684d1179ff54c63a50/1920x1080-zodiac-2.jpg";
    hash = "sha256-Zr8RaKHTSPX4dCk2sp++hhaGKsHl9rNlq7D3deK2Q9M=";
  };

  terrainWa = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/22Xj1YPLa19KYGAOGcAhbb/014bde378bc8e710eb15fb7fc99e5d0c/1920x1080-terrain-wa.jpg";
    hash = "sha256-jHzD3JotR8xL6hMU6Dcrdvhk6AIqnBxR5h7+9k4ICPU=";
  };

  starter = pkgs.fetchurl {
    url = "https://images.ctfassets.net/swt2dsco9mfe/1sM6XUZXHZOP7l9vfJU7PN/d026f03125c3fb337d58de7d23cc16e2/1920x1080-starter.jpg";
    hash = "sha256-Ay9MabgUZsjx+MUnVy91A1YM4f4gXcvdswwmOmbmRsA=";
  };
  baldursGate3 = fetchSteamCards {
    appId = 1086940;
    hash = "sha256-3YDOYoyVRe1yGebGIx3mqj418nobsZ9mrntIvRk7L8s=";
  };
}
