{ fetchGOG, getFile, ... }:
{
  alanWake =
    fetchGOG {
      game = "alan_wake";
      fileId = 14263;
      sha256 = "sha256-dc9AA/I/iPFla2RR4VTxcxcylX7Ss7lZtlwG/DYJLEM=";
    }
    |> getFile "alan_wake_wallpaper/AlanWake_1920x1080.jpg";
}
