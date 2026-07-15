{
  lib,
  fetchSteamCards,
  pkgs,
  image,
  fetchzipSelective,
  splitFiles,
  splitFilesBaseName,
  parallel,
  ...
}:
with image;
{
  ezio = pkgs.fetchurl {
    url = "https://i0.hdslb.com/bfs/new_dyn/27ff8e4ee1fe0eed605fdbdfb71682451197454103.jpg";
    hash = "sha256-7CuAtQcS5uaGERbp3sF4T2xYGPsXIJ3Y20gDQCDV/jE=";
  };
  kassandra = pkgs.fetchurl {
    url = "https://i0.hdslb.com/bfs/new_dyn/680b4de0c80e35f8d63ef4f19fbfdb031197454103.jpg";
    hash = "sha256-CGsCDo+LENWbLtKVjgCTqbJUzL2FIOkymCbHmJgUC20=";
  };
  acCollage =
    pkgs.fetchurl {
      url = "https://gamecms-res.sl916.com/official_website_resource/50001/4/PICTURE/20250902/657%202436%C3%971125_fd9454a376e242a18d25c026dc24fa22.jpg";
      hash = "sha256-xV7WrEX/JUNft3/3qFVp5SRfsGLVw5nbUtegSrn/QyM=";
      name = "ac-collage.jpg";
    }
    |> crop16x9South;
  assassinsCreedChroniclesIndia = fetchSteamCards {
    appId = 359610;
    cardNames = [
      "burnes"
      "arbaaz"
      "pyara"
      "hamid"
      "sleeman"
    ];
    sha256 = "sha256-M+tw36QOnoR4WOYH2gkA0ZM7c+dwzW1000sh4d8Yy9g=";
  };
  assassinsCreedChroniclesChina = fetchSteamCards {
    appId = 354380;
    cardNames = [
      "quiju"
      "gaofeng"
      "zhangyong"
      "shaojun"
      "empress"
    ];
    sha256 = "sha256-h0SXeY7MPQDssOUR39SUUXondE2LHepdDX+aKOusGYk=";
  };
  assassinsCreedChroniclesRussia = fetchSteamCards {
    appId = 359600;
    cardNames = [
      "yakovYurovsky"
      "orelov"
      "anastasia"
      "sergei"
      "trotsky"
    ];
    sha256 = "sha256-i/atzpJELCEacT4oX0FA/tquxjQvh6e6OuObU0ndHTE=";
  };
  acBrotherhoodFanKit =
    let
      keepFiles = [
        "3840x2160/AC_LEGACY_JOURNEY_1B_3840x2160.png"
        "3840x2160/AC_LEGACY_JOURNEY_2B_3840x2160.png"
        "3840x2160/AC_LEGACY_JOURNEY_3A_3840x2160.png"
        "3840x2160/ACBrand_AllAssassins_3840x2160.png"
        "3840x2160/ACBrand_HR_Encyclopedie_3840x2160.png"
      ];
    in
    fetchzipSelective {
      url = "https://ubiservices.cdn.ubi.com/aaa9f426-4c3f-4804-8775-1995266f7c8c/reward/ACDREWARD32_downloadable.zip";
      sha256 = "sha256-FJmQUFUz4d6K9vDsuPJHgDbK7H1eh0aHaA59o5g4ttU=";
      inherit keepFiles;
      flatten = true;
    }
    |> splitFilesBaseName keepFiles;
  acIIIFanKit =
    let
      keepFiles = [
        "uPlay_PC_Wallpaper1_1920x1080.jpg"
        "uPlay_PC_Wallpaper2_1920x1080.jpg"
        "uPlay_PC_Wallpaper3_1920x1080.jpg"
        "uPlay_PC_Wallpaper4_1920x1080.jpg"
      ];
    in
    fetchzipSelective {
      url = "https://ubiservices.cdn.ubi.com/4a1562a4-c4d2-4bc5-a85e-f3db588b0072/reward/AC3REWARD01PC_downloadable.zip";
      sha256 = "sha256-3MF7/sHzpV09bDF+E0cDKlyxOwlmqdzauCtg7MB1e0w=";
      stripRoot = false;
      inherit keepFiles;
    }
    |> splitFiles keepFiles;
  ac4FanKit =
    let
      keepFiles = [
        "ac4_Wallpaper1_1920x1080.jpg"
        "ac4_Wallpaper2_1920x1080.jpg"
        "ac4_Wallpaper3_1920x1080.jpg"
        "ac4_Wallpaper4_1920x1080.jpg"
      ];
    in
    fetchzipSelective {
      url = "https://ubiservices.cdn.ubi.com/c8b3f1c6-a246-4ffe-a837-a49d6bb0ce52/reward/ACBFREWARD01PC_downloadable.zip";
      sha256 = "sha256-KfadYB2XiYyOyTBJ/ORXkgVjiJy1vkl7dXX0NuYIGFM=";
      stripRoot = false;
      inherit keepFiles;
    }
    |> splitFiles keepFiles;
  acLiberationFanKit =
    let
      keepFiles = [
        "ACLHD_1920x1080.jpg"
      ];
    in
    fetchzipSelective {
      url = "https://ubiservices.cdn.ubi.com/23f11cd4-ebe8-41c4-8367-20f6502d2ad6/reward/ACLHDREWARD01PC_downloadable.zip";
      sha256 = "sha256-+YQN+w3MoUJ2QCro7vEdA/dP/8QRbi58SGJ3iCBA7IQ=";
      stripRoot = false;
      inherit keepFiles;
    }
    |> splitFiles keepFiles;
  acMirageFanKit =
    let

      keepFiles = [
        "Logo Wallpaper/Horizontal/ACMirage_LogoWall.jpg"
        "Mid-Res/Basim/ACMirage_MR_Basim_Wallpaper.jpg"
        "Mid-Res/Roshan/ACMirage_MR_Roshan_Wallpaper.jpg"
      ];
    in
    fetchzipSelective {
      url = "https://ubiservices.cdn.ubi.com/1d5e4680-e410-432c-af6d-c50d7024ddd0/downloadable/ACMirage_FanKit.zip";
      sha256 = "sha256-ak7SICKfm3ciUn2ULw63IR8yEkunHeXFTTyUmcwTTDM=";
      flatten = true;
      inherit keepFiles;
    }
    |> splitFilesBaseName keepFiles;
  acOriginsFanKit =
    let
      keepFiles = [
        "Desktop Wallpapers/ACO_Wallpapers_Pyramids_2048_1152.jpg"
        "Desktop Wallpapers/ACO_Wallpaper_BayekDesert_2048_1152.jpg"
        "Desktop Wallpapers/ACO_Wallpaper_BayekShield_2048_1152.jpg"
        "Desktop Wallpapers/ACO_Wallpaper_Fight_2048_1152.jpg"
        "Desktop Wallpapers/ACO_Wallpaper_Hetepi_2048_1152.jpg"
        "Desktop Wallpapers/ACO_Wallpaper_Hieroglyphs_2048_1152.jpg"
        "Desktop Wallpapers/ACO_Wallpaper_Hieroglyphs_Light_2048_1152.jpg"
        "Desktop Wallpapers/ACO_Wallpaper_Key Art.jpg"
        "Desktop Wallpapers/ACO_Wallpaper_PyramidSlide_2048_1152.jpg"
        "Desktop Wallpapers/ACO_Wallpaper_RangedCombat_2048_1152.jpg"
        "Desktop Wallpapers/ACO_Wallpaper_SiwaTemple_2048_1152.jpg"
        "Desktop Wallpapers/ACO_Wallpaper_Sphinx_2048_1152.jpg"
        "Desktop Wallpapers/ACO_Wallpaper_Vista_2048_1152.jpg"
        "Desktop Wallpapers/ACO_Wallpaper_Wildlife_2048_1152.jpg"
        # "Concept Art" # Some have the wrong aspect ratio
      ];
    in
    fetchzipSelective {
      url = "https://ubiservices.cdn.ubi.com/bfd34091-6af6-4029-873b-ba7e036464fa/reward/ACEREWARD31_downloadable.zip";
      sha256 = "sha256-+lABJwGm1AJLIUdb9JdKLBMhdv7EkorYm3Md8rcgfZY=";
      stripRoot = false;
      inherit keepFiles;
      flatten = true;
    }
    |> splitFilesBaseName keepFiles;
  acRogueFanKit =
    pkgs.fetchzip {
      url = "https://ubiservices.cdn.ubi.com/3499bde3-6f0e-4ddc-84fb-736f93078be2/reward/ACCMREWARD01PC_downloadable.zip";
      stripRoot = false;
      sha256 = "sha256-4nw3M5KOAw29smuK47ecuDL/pBboO6C2/7oNACl7IaA=";
    }
    |> splitFiles (parallel (map (n: "wallpaper_${toString n}.jpg")) (lib.range 1 9));
  acUnityFanKit =
    let
      keepFiles = [
        "ACU_Notre-Dame_Guillotine_1920x1080.jpg"
        "ACU_Notre-Dame_UnderSiege_1920x1080.jpg"
        "ACU_RiotOfVersailles_1920x1080.jpg"
        "ACU_Versailles_Ransacked_1920x1080.jpg"
      ];
    in
    fetchzipSelective {
      url = "https://ubiservices.cdn.ubi.com/6678eff0-1293-4f87-8c8c-06a4ca646068/reward/OOGACUREWARD06_downloadable.zip";
      sha256 = "sha256-bRqK4pIpb5Y7gWyH0U1bp9IK/fMBNOsT/Z4Qv2ejfrE=";
      stripRoot = false;
      inherit keepFiles;
    }
    |> splitFiles keepFiles;
}
