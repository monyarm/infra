{ fetchVideo, extractFrames, ... }:
{
  palWorldTerraria =
    extractFrames
      (fetchVideo {
        url = "https://www.youtube.com/watch?v=sFVJVWVDIMg";
        sha256 = "sha256-hVKglvEjz4qNhuEI7goIBDJvkVnO9gSYovU6RmFnsuQ=";
      })
      [
        "12"
        "20.467"
        "22.200"
        "38.933"
        "42.900"
      ];
}
