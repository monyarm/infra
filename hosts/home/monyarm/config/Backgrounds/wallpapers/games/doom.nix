{
  pkgs,
  image,
  fetchSteamCards,
  ...
}:
with image;
{
  doomTheDarkAges01 = pkgs.fetchurl {
    url = "https://images.mweb.bethesda.net/_images/doom-the-dark-ages/DOOM-TheDarkAges_Standard_16x9.jpg?f=jpg&h=1080&w=1920&s=054JKPMrjKcGy9s7w1Sp9UAgh2cVlBUs7BA8Zle8PvQ";
    sha256 = "09inc0zxiv8irny65mjqci6cisz52j78c2q7fkzx45x80zirds6v";
    name = "doomTheDarkAges01.jpg";
  };

  doomTheDarkAges02 = pkgs.fetchurl {
    url = "https://images.mweb.bethesda.net/_images/doom-the-dark-ages/DOOM-TheDarkAges_Premium_16x9.jpg?f=jpg&h=1080&w=1920&s=f9Awx-Q6HRyi7V8Df2t3ya5K8QXavBEwTwy4VJvCtDs";
    sha256 = "026jzsykv27fkg3rcfnsjnfg3paff9q59rkf87smrq561bcxxj7v";
    name = "doomTheDarkAges02.jpg";
  };

  doomTheDarkAges03 = pkgs.fetchurl {
    url = "https://images.mweb.bethesda.net/_images/doom-the-dark-ages/DOOM-TheDarkAges_Premium_16x9.jpg?f=jpg&h=1080&w=1920&s=f9Awx-Q6HRyi7V8Df2t3ya5K8QXavBEwTwy4VJvCtDs";
    sha256 = "0dr4b0m2bgj3gk92x88jkn82v1pvxsgjac6m2438lajwd27b7pnq";
    name = "doomTheDarkAges03.jpg";
  };

  slayer =
    pkgs.fetchurl {
      url = "https://images.ctfassets.net/rporu91m20dc/23b13yxAzU77zBlooII0hU/ef1abf418fec4609fe995fb1a206d298/The_DOOM_Slayer_Wallpaper_5654x2763.jpg";
      hash = "sha256-3SM4UGxTOjvl0wwVpnF21xP4Lq8zKNhHGYd5G+Ga8os=";
    }
    |> crop16x9;
  doomEternal = fetchSteamCards {
    appId = 782330;
    hash = "sha256-qTQzG71/Y5JNEOsAtX0CP0IUr1EXf1BacHHBsPivJIg=";
  };
}
