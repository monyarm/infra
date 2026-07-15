{
  image,
  fetchzipSelective,
  splitFilesBaseName,
  lib,
  ...
}:
with image;
{
  princeOfPersiaFanKit =
    let

      keepFiles = [
        "WALLPAPERS/Hi-Rez/POP_TheLostCrown_Hi rez_walpaper_3840x2160.png"
        "WALLPAPERS/Key Art/POP_TheLostCrown_Key art_walpaper_3840x2160.png"
        "WALLPAPERS/Key Art 2/POP_TheLostCrown_Key_Art_2_wallpaper_3840x2160.png"
      ];
    in
    fetchzipSelective {
      url = "https://ubiservices.cdn.ubi.com/aa6b1778-f274-4b52-8fce-f642173aa0e1/connect/PoP_TheLostCrown_FANKIT.zip";
      sha256 = "sha256-7JytlbzNvo6KWBYyVqIY7ZvZHNp2Kr0R+645qZXFzu4=";
      flatten = true;
      inherit keepFiles;
    }
    |> splitFilesBaseName keepFiles;
}
