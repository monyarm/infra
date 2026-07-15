{ fetchSteamCards, ... }:
{
  contraOperationGaluga = fetchSteamCards {
    appId = 2235020;
    cardNames = [ "operationGaluga" ];
    sha256 = "sha256-ZKPzahI7vjFBywccqQMWHl8wcZ/LWJXwnXI2Ck0S7hU=";
  };
}
