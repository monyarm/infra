{
  fetchSteam,
  splitFiles,
  image,
  ...
}:
with image;
{
  necrodancer =
    let
      files = [
        "Launcher/Sprites/Backgrounds/Back-012.jpg"
        "Launcher/Sprites/Backgrounds/Back-017.jpg"
        "Launcher/Sprites/Backgrounds/Back-013.jpg"
        "Launcher/Sprites/Backgrounds/Back-016+.jpg"
        "Launcher/Sprites/Backgrounds/Back-020+.jpg"
        "Launcher/Sprites/Backgrounds/Back-014.jpg"
        "Launcher/Sprites/Backgrounds/Back-005.jpg"
        "Launcher/Sprites/Backgrounds/Back-010.jpg"
        "Launcher/Sprites/Backgrounds/Back-006.jpg"
        "Launcher/Sprites/Backgrounds/Back-009.jpg"
        "Launcher/Sprites/Backgrounds/Back-022.jpg"
        "Launcher/Sprites/Backgrounds/Back-003+.jpg"
        "Launcher/Sprites/Backgrounds/Back-002+.jpg"
        "Launcher/Sprites/Backgrounds/Back-008.jpg"
        "Launcher/Sprites/Backgrounds/Back-001+.jpg"
        "Launcher/Sprites/Backgrounds/Back-007.jpg"
        "Launcher/Sprites/Backgrounds/Back-021.jpg"
        "Launcher/Sprites/Backgrounds/Back-015+.jpg"
        "Launcher/Sprites/Backgrounds/Back-011+.jpg"
        "Launcher/Sprites/Backgrounds/Back-004+.jpg"
        "Launcher/Sprites/Backgrounds/Back-018.jpg"
        "Launcher/Sprites/Backgrounds/Back-019+.jpg"
      ];
    in
    fetchSteam {
      appId = 1882240;
      depotId = 1882241;
      manifestId = 1729058584393149004;
      sha256 = "sha256-ZM9ipYOwI0YlMoOsM1XAUjpTSykNW2qFrNZ53NACtjE=";
      filelist = files;
    }
    |> splitFiles files
    |> map crop16x9;
}
