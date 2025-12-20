{ fetchVideo, extractFrames, ... }:
{
  mightyNein =
    extractFrames
      (fetchVideo {
        url = "https://www.youtube.com/watch?v=LhFETREAvhc";
        sha256 = "sha256-F7oBxUkIlnG+BRPjJgsO+Cj53um8fuhWMdiAbf9X1a8=";
      })
      [
        "12.045"
        "13.380"
        "14.948"
        "16.583"
        "23.423"
        "25.623"
        "29.162"
        "31.365"
        "31.965"
        "37.204"
        "43.544"
        "45.145"
        "46.513"
        "47.347"
        "48.982"
        "51.418"
        "51.952"
        "56.490"
        "57.257"
        "1:00.093"
        "1:03.130"
        "1:07.401"
        "1:10.604"
        "1:15.909"
        "1:18.211"
        "1:19.780"
        "1:20.747"
        "1:21.682"
        "1:22.316"
        "1:22.783"
        "1:23.350"
        "1:23.850"
        "1:24.284"
        "1:28.655"
      ];

  mightyNeinReunited =
    extractFrames
      (fetchVideo {
        url = "https://www.youtube.com/watch?v=CeB6ZQn4tUU";
        sha256 = "sha256-Kx7rR82EbmD7EmtrdiUlcZUZltRJD8PqQ8gj26EZSOM=";
      })
      [
        "1:10.571"
        "1:21.682"
        "1:22.249"
        "1:22.749"
        "1:23.216"
        "1:23.750"
        "1:24.217"
        "1:28.522"
      ];

  bellsHells =
    extractFrames
      (fetchVideo {
        url = "https://www.youtube.com/watch?v=KpMtE4UzKM8";
        sha256 = "sha256-YtPVkOXWuKoBFLJHzNKf/7x2QRJZ7efRGuzBgT7kByw=";
      })
      [
        "6.340"
        "10.777"
        "15.315"
        "24.057"
        "26.360"
        "28.996"
        "34.835"
        "35.435"
        "38.205"
        "38.405"
        "45.412"
        "47.915"
        "51.685"
        "57.124"
        "1:04.598"
        "1:13.407"
        "1:29.489"
        "1:30.457"
      ];

  legendOfVoxMachinaS3 =
    extractFrames
      (fetchVideo {
        url = "https://www.youtube.com/watch?v=MCmiaV3Lxm4";
        sha256 = "sha256-/GbJ3djMRWNAGcilKIVMsuD+8g4vNbbIPK+IfLmfcG4=";
      })
      [
        "21.104"
        "23.540"
        "24.524"
        "28.695"
        "30.631"
        "36.737"
        "39.723"
        "47.397"
        "49.583"
        "52.569"
        "59.593"
      ];

  mightyNeinTrailer =
    extractFrames
      (fetchVideo {
        url = "https://www.youtube.com/watch?v=vjo4OuRH12A";
        sha256 = "sha256-9oVCfErUoZ8E0k2TK9Nh2OA/w4i7b+gP4+SOfgXMdl4=";
      })
      [
        "0.001"
        "22.105"
        "28.779"
        "29.780"
        "31.281"
        "55.764"
        "1:16.785"
      ];
}
