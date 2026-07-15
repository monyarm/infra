{ fetchSteamCards, ... }:
{
  godsTrigger = fetchSteamCards {
    appId = 488730;
    cardNames = [ "onTheRocks" ];
    sha256 = "sha256-fM0zcKAXXcNtBehjJ0NVNtYCUzJPwEfhyEY+eFvytHk=";
  };
}
