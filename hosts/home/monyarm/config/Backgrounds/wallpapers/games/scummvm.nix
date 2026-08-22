{
  fetchGOG,
  splitFiles,
  getFile,
  ...
}:
{
  beneathASteelSky =
    fetchGOG {
      game = "beneath_a_steel_sky";
      fileId = [
        5983
        5993
      ];
      sha256 = "sha256-YaHzWhcsPfvwrFA3OHobW1V7ESzN7wjR1kobshe8teY=";
    }
    |> splitFiles [
      "Beneath a Steel Sky/Beneath_a_Steel_Sky_logo_1920x1080.jpg"
      "Beneath a Steel Sky/Beneath_a_Steel_Sky_comic_1920x1080.jpg"
    ];
  lastDoor =
    fetchGOG {
      game = "last_door_collectors_edition_the";
      fileId = 31363;
      sha256 = "sha256-e0NRFm0S4MH+4EUWj0ot/PR4D42SwMI8UNPB+bGJBoY=";
    }
    |> getFile "last_door_wallpaper/wallpaper-Last-Door,-The.jpg";
}
