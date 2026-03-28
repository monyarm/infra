{ fetchSteamCards, ... }:
{
  shovelKnight = fetchSteamCards {
    appId = 250760;
    hash = "sha256-qA3NbwdHYk3wuR53MacEikyTLTYas09PWEe2lfwwCtY=";
  };
  shovelKnightSpecterOfTorment = fetchSteamCards {
    appId = 589510;
    hash = "sha256-BeQwRjMRor1j6ErY5gbZPQENK9ENlUnHgZ5tWC0cmjI=";
  };
  shovelKnightShovelOfHope = fetchSteamCards {
    appId = 589500;
    hash = "sha256-7hZpk9cn5vJ4Eeo7S3QXHmuFoyEM3L3vj44iWk5xvHY=";
  };
}
