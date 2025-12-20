{ pkgs, ... }:
let
  dnd50thZip = pkgs.fetchzip {
    url = "https://media.dndbeyond.com/compendium-images/marketing/50th-anniversary-desktop-wallpapers.zip";
    sha256 = "191zys4qav2kn4n23nxdqcxi8zqm8yfznzjz2cfifisqymvihgdk";
  };
in
{
  dnd50thDesktop = "${dnd50thZip}/Desktop Wallpaper/D&D_50th_Wallpaper_Desktop-3840x2140.jpg";
}
