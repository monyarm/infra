{
  fetchGOG,
  fetchSteam,
  splitFiles,
  ...
}:
{
  witcherEnhancedEdition =
    fetchGOG {
      game = "the_witcher";
      fileId = 10473;
      sha256 = "sha256-11hvE9kpEPsQgghyAQx7iMBMfnhx+FbkBtv7dR/GzAU=";
    }
    |> splitFiles [
      "The_Witcher_wallpapers/1920 x 1080/The_Witcher_Mutant.jpg"
      "The_Witcher_wallpapers/1920 x 1080/The_Witcher_Geralt_1.jpg"
      "The_Witcher_wallpapers/1920 x 1080/The_Witcher_Driad.jpg"
      "The_Witcher_wallpapers/1920 x 1080/The_Witcher_Geralt_2.jpg"
      "The_Witcher_wallpapers/1920 x 1080/The_Witcher_Shtriga_3.jpg"
      "The_Witcher_wallpapers/1920 x 1080/The_Witcher_Medallion.jpg"
      "The_Witcher_wallpapers/1920 x 1080/The_Witcher_Igni.jpg"
      "The_Witcher_wallpapers/1920 x 1080/The_Witcher_Forest.jpg"
      "The_Witcher_wallpapers/1920 x 1080/The_Witcher_Shtriga_1.jpg"
      "The_Witcher_wallpapers/1920 x 1080/The_Witcher_Caer_a'Muirehen.jpg"
      "The_Witcher_wallpapers/1920 x 1080/The_Witcher_Lover.jpg"
      "The_Witcher_wallpapers/1920 x 1080/The_Witcher_Confrontation.jpg"
      "The_Witcher_wallpapers/1920 x 1080/The_Witcher_Courtesan.jpg"
      "The_Witcher_wallpapers/1920 x 1080/The_Witcher_Tombs.jpg"
      "The_Witcher_wallpapers/1920 x 1080/The_Witcher_Sorceress.jpg"
      "The_Witcher_wallpapers/1920 x 1080/The_Witcher_The_Road.jpg"
      "The_Witcher_wallpapers/1920 x 1080/The_Witcher_Toruviel.jpg"
      "The_Witcher_wallpapers/1920 x 1080/The_Witcher_Shtriga_2.jpg"
    ];
  witcher2 =
    let
      files = [
        "Wallpapers/1920x1080/TheWitcher2_artwork_1920x1080.jpg"
        "Wallpapers/1920x1080/TheWitcher2_artwork_2_1920x1080.jpg"
        "Wallpapers/1920x1080/TheWitcher2_Triss2_1920x1080.jpg"
        "Wallpapers/1920x1080/TheWitcher2_Draug_1920x1080.jpg"
      ];
    in
    fetchSteam {
      appId = 20930;
      depotId = 20932;
      manifestId = 5057251254487652074;
      sha256 = "sha256-0FE3+Xhxsf9ViJDqo9xE6hzKRMF63nz2hjnhIHVvhGk=";
      filelist = files;
    }
    |> splitFiles files;
  witcher3 =
    let
      files = [
        "ARTWORK/The_Witcher_3_Wild_Hunt_Ice_Giant_Cave.jpg"
        "ARTWORK/The_Witcher_3_Wild_Hunt_Port.jpg"
        "ARTWORK/The_Witcher_3_Wild_Hunt_Manufacture.jpg"
      ];
    in
    fetchSteam {
      appId = 292030;
      depotId = 292033;
      manifestId = 5639169236463762487;
      sha256 = "sha256-6poAhcEY7d8dQI8/h8Kl8Keh4/buux/JJdob8jxOeQ8=";
      filelist = files;
    }
    |> splitFiles files;
}
