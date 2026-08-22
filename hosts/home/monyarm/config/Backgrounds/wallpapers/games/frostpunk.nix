{ fetchSteam, splitFiles, ... }:
{
  frostpunk =
    let
      files = [
        "Frostpunk Original Soundtrack-HQ/Additional Content/Wallpapers/Frostpunk Generator Wallpaper 4k.jpg"
        "Frostpunk Original Soundtrack-HQ/Additional Content/Wallpapers/Frostpunk City Wallpaper 4k.jpg"
        "Frostpunk Original Soundtrack-HQ/Additional Content/Wallpapers/Frostpunk Storm Wallpaper 4k.jpg"
        "Frostpunk Original Soundtrack-HQ/Additional Content/Wallpapers/Frostpunk Expedition Wallpaper 4k.jpg"
        "Frostpunk Original Soundtrack-HQ/Additional Content/Wallpapers/Frostpunk Cover Wallpaper 4k.jpg"
        "Frostpunk Original Soundtrack-HQ/Additional Content/Wallpapers/Frostpunk Winterhome Wallpaper 4k.jpg"
      ];
    in
    fetchSteam {
      appId = 966350;
      depotId = 966351;
      manifestId = 1813556746725907077;
      sha256 = "sha256-GurGMAGtOEoPuAxC1NLx2NadmvWp13HFQ45phNATM+M=";
      filelist = files;
    }
    |> splitFiles files;
  frostpunkExpansions =
    let
      files = [
        "Frostpunk Expansions Original Soundtrack/Additional Content/Wallpapers/Frostpunk Expansions Wilderness Wallpaper 4k.jpg"
        "Frostpunk Expansions Original Soundtrack/Additional Content/Wallpapers/Frostpunk Expansions Airship Wallpaper 4k.jpg"
        "Frostpunk Expansions Original Soundtrack/Additional Content/Wallpapers/Frostpunk Expansions Hunters Wallpaper 4k.jpg"
        "Frostpunk Expansions Original Soundtrack/Additional Content/Wallpapers/Frostpunk Expansions Beacon Wallpaper 4k.jpg"
      ];
    in
    fetchSteam {
      appId = 1606200;
      depotId = 1606202;
      manifestId = 265353319750358963;
      sha256 = "sha256-l4OVjvaxTBD9Tu6KlXBj02mSg3eSupju8rG+W87TVUg=";
      filelist = files;
    }
    |> splitFiles files;
}
