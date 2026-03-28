{
  image,
  fetchzipSelective,
  ...
}:
with image;
{
  acValhallaFanKit = fetchzipSelective {
    url = "https://ubiservices.cdn.ubi.com/c4f15d67-1300-4e9e-bbe3-12e11a148e81/downloadable/ACValhalla_FanKit.zip";
    sha256 = "sha256-bRqK4pIpb5Y7gWyH0U1bp9IK/fMBNOsT/Z4Qv2ejfrE=";
    flatten = true;
    keepFiles = [
      "WALLPAPERS/Hi-Rez/POP_TheLostCrown_Hi rez_walpaper_3840x2160.png"
      "WALLPAPERS/Key Art/POP_TheLostCrown_Key art_walpaper_3840x2160.png"
      "WALLPAPERS/Key Art 2/POP_TheLostCrown_Key_Art_2_wallpaper_3840x2160.png"
    ];
  };
}
