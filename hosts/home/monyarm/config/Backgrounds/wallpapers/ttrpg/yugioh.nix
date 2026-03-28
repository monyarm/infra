{
  fetchSteamCards,
  fetchPixiv,
  image,
  pkgs,
  ...
}:
with image;
{
  duelLinks = fetchSteamCards {
    appId = 601510;
    hash = "sha256-BC6Wbq8zamlJbDXR2q65UEsatGekRU/1pvbPTjAINfo=";
  };
  masterDuel = fetchSteamCards {
    appId = 1449850;
    hash = "sha256-GFRPqudd0Za+Bzy4TR1jKOFs8zBEnHlVo736gOFy6l8=";
  };
  yugiohEarlyDaysCollection = fetchSteamCards {
    appId = 3013550;
    hash = "sha256-V3f4XecmvTTUklRAgQiGVf3TMfeAr4Zg3tP4QyyfWmc=";
  };
  yugiohLegacyOfTheDuelistLinkEvolution = fetchSteamCards {
    appId = 1150640;
    hash = "sha256-0Vu7t5EAt7jDWftsNz5G8O9BkNQ+qkIZWd8wsjSt6Kc=";
  };
  stitchedWallpaper =
    let
      left = fetchPixiv {
        url = "https://i.pximg.net/img-original/img/2015/02/02/00/34/57/48507635_p1.jpg";
        sha256 = "sha256-ze0BlZ9xyUyLTD9ikflHRUn1kpwrQcaqc9p2tuT/MAA=";
      };
      right = fetchPixiv {
        url = "https://i.pximg.net/img-original/img/2015/02/02/00/34/57/48507635_p0.jpg";
        sha256 = "sha256-fFCD4jsiOYWJlI62nx574iAgup/fzf2iUOf/A7gZxNY=";
      };
      canvas = pkgs.runCommand "ygo-canvas.png" {
        buildInputs = [ pkgs.imagemagick ];
      } ''magick -size 3108x1748 canvas:white PNG32:$out'';
    in
    transform {
      args = "${left} -geometry +0+0 -composite ${right} -geometry +1868+0 -composite";
      nameSuffix = "stitched";
      extension = "png";
    } canvas;
}
