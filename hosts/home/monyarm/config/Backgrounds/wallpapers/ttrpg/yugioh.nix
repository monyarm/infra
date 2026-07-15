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
    cardNames = [
      "yamiBakura"
      "yamiYugi"
      "joeyWheeler"
      "yamiMarik"
      "setoKaiba"
      "teaGardner"
    ];
    sha256 = "sha256-bi47lwhA2328CfdO8ASinyWNyCtfiWpzM6lpjKzYl/o=";
  };
  masterDuel = fetchSteamCards {
    appId = 1449850;
    cardNames = [
      "monsterArt1"
      "monsterArt5"
      "monsterArt4"
      "monsterArt3"
      "monsterArt6"
      "monsterArt2"
    ];
    sha256 = "sha256-y08f0GyeuucXQAvkVAjBVLYie2zBOpq5T0LtkkxEEsI=";
  };
  yugiohEarlyDaysCollection = fetchSteamCards {
    appId = 3013550;
    cardNames = [
      "dungeonDiceMonsters"
      "theScaredCards"
      "duelMonsters"
      "destinyBoardTraveler"
      "duelMonstersIi"
    ];
    sha256 = "sha256-bM8kiW89lEeNBSNQvKo5AoK8HcO+1ABFSmFz/qmIAm4=";
  };
  yugiohLegacyOfTheDuelistLinkEvolution = fetchSteamCards {
    appId = 1150640;
    cardNames = [
      "darkMagician"
      "elementalHeroNeos"
      "decodeTalker"
      "stardustDragon"
      "oddEyesPendulumDragon"
      "number39Utopia"
    ];
    sha256 = "sha256-LOQTfo6qPOt8em5ub7wuwESZh8fVYyPbdVAhMMs1Sd0=";
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
      } "magick -size 3108x1748 canvas:white PNG32:$out";
    in
    canvas
    |> transform {
      args = "${left} -geometry +0+0 -composite ${right} -geometry +1868+0 -composite";
      nameSuffix = "stitched";
      extension = "png";
    };
}
