{ fetchMyNintendo, ... }:
{
  prime4Beyond = fetchMyNintendo {
    url = "https://my.nintendo.com/rewards/617c8dd801bffa2f/media/6e2e98b939ce9701";
    sha256 = "sha256-gQs5nPLI1nSgOWylk6x4Yy8+6kuY7/1m+9qE4kPZ+ps=";
    # This rewards URL's last path segment is an opaque hash with no real
    # filename/extension in it, which getFileNameFromUrl's default naming
    # would use verbatim -- optimize's isFolderShaped heuristic (no
    # recognizable extension = must be a folder) then misclassifies the
    # fetched file as a directory. An explicit name with a real extension
    # sidesteps that.
    name = "Metroid_Prime_4_Beyond_wallpaper_1920x1080.jpg";
  };
}
