{ fetchGOG, getFile, ... }:
{
  dungeonKeeper =
    fetchGOG {
      game = "dungeon_keeper";
      fileId = 11233;
      sha256 = "sha256-LjH96X03lri6DQ/2rE87Jz7WS4Tk1doPOHermgonXeo=";
    }
    |> getFile "wallpaper/DungeonKeeper_1920x1080.jpg";
}
