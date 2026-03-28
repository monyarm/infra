{ fetchSteamCards, ... }:
{
  contraOperationGaluga = fetchSteamCards {
    appId = 2235020;
    hash = "sha256-PgFAR8dZW9qtpgZRk4w0q33Y+4RExz9aFsjjgHSi5D0=";
    cardNames = [ "operationGaluga" ];
  };
}
