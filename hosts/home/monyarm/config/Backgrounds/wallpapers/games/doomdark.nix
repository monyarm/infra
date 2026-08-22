{ fetchGOG, splitFiles, ... }:
{
  doomdarksRevenge =
    fetchGOG {
      game = "doomdarks_revenge";
      fileId = 28453;
      sha256 = "sha256-2+YAwe/1E1MSURoMIAtkXMWak7SlLydRdtVV+/1ABjI=";
    }
    |> splitFiles [
      "doomdarks_revenge_wallpapers/Wallpaper3 Doomdark's Revenge 1920x1080.jpg"
      "doomdarks_revenge_wallpapers/Wallpaper1 Doomdark's Revenge 1920x1080.jpg"
      "doomdarks_revenge_wallpapers/Wallpaper4 Doomdark's Revenge 1920x1080.jpg"
      "doomdarks_revenge_wallpapers/Wallpaper2 Doomdark's Revenge 1920x1080.jpg"
    ];
}
