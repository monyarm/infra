{ fetchSteamCards, ... }:
{
  suikodenIandII = fetchSteamCards {
    appId = 1932640;
    cardNames = [
      "heroIi"
      "cleo"
      "pahn"
      "nanami"
      "flik"
      "ted"
      "jowy"
      "heroI"
      "viktor"
      "gremio"
    ];
    sha256 = "sha256-jNsQMFtLUINdsNxWlTjN+/P9EmSw6XcPU1hSYHXdvuI=";
  };
}
