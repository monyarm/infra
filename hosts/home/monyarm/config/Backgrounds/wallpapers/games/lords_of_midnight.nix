{ fetchGOG, splitFiles, ... }:
{
  lordsOfMidnight =
    fetchGOG {
      game = "the_lords_of_midnight";
      fileId = 24083;
      sha256 = "sha256-mmO6bsfSMnjryZPO6EtNV3kYOKrpVngnpRsiSanxHqA=";
    }
    |> splitFiles [
      "lords_of_midnight_wallpapers/wallpaper-01-The-Lords-of-Midnight.jpg"
      "lords_of_midnight_wallpapers/wallpaper-02-The-Lords-of-Midnight.jpg"
    ];
}
