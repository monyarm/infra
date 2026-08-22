{ fetchGOG, getFile, ... }:
{
  eschalonBookI =
    fetchGOG {
      game = "eschalon_book_i";
      fileId = 22543;
      sha256 = "sha256-GEWfL9Uq1Lz+T4rMRnSFNgxx3I0bzvHt/j2KIZimNFU=";
    }
    |> getFile "eschalon_book_1_wallpaper/Wallpaper  Eschalon - Book 1 1920x1080.jpg";
}
