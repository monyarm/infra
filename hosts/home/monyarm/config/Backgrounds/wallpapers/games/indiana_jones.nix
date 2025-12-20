{ pkgs, ... }:
{
  indianaJonesGreatCircle01 = pkgs.fetchurl {
    url = "https://indianajones.bethesda.net/_static-indianajones/wallpapers/Keyart2_Wallpaper_2560x1440-01.jpg";
    sha256 = "1w96lnd2kqkpjwif1260jlyzjrj8lgf4l3lzd9xd363xh5k5612c";
  };

  indianaJonesGreatCircle02 = pkgs.fetchurl {
    url = "https://indianajones.bethesda.net/_static-indianajones/wallpapers/Keyart1_Wallpaper_2560x1440-01.jpg";
    sha256 = "09cryslkc6hvhl450bk6hy0i4r48n7180jpihlj9i6vhd3pvv27w";
  };
}
