{ fetchSteamCards, ... }:
{
  cloudMeadow = fetchSteamCards {
    appId = 1223750;
    cardNames = [
      "brontide"
      "fio"
      "eve"
      "camellia"
      "evan"
      "kreyton"
      "yonten"
    ];
    sha256 = "sha256-YoT53MtfmC3EEv3+6qZKRd33BngWr5J3wTkVhTrzPTw=";
  };
}
