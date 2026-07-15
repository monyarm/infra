{
  pkgs,
  fetchSteamCards,
  fetchPixiv,
  ...
}:
{
  persona5ThePhantomX01 = pkgs.fetchurl {
    url = "https://persona5x.com/assets/images/common/fankit/wallpaper/wallpaper01.jpg";
    sha256 = "09d8qc6fqvh4kg9n4034pyg9hp4sc2k0fkixf29ifjwdb85lv3gz";
  };

  jokerArsene = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2018/04/08/01/07/15/68128232_p0.jpg";
    sha256 = "sha256-gOeoqBIdWsHDR4+uuhknSjsHNLCx/4toteuXIHDgXx4=";
  };

  p5GunShopGirls = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2018/07/13/05/24/15/69663340_p0.jpg";
    sha256 = "sha256-9Ch1lrH+TIDCBWVSZfxdhYl52WdBJdGnUjxTr8LWKuc=";
  };

  persona5ThePhantomX02 = pkgs.fetchurl {
    url = "https://persona5x.com/assets/images/common/fankit/wallpaper/wallpaper03.jpg";
    sha256 = "0y7mvjlwffbmp9hbm0r79i2fick627ixscyvr4v3q06bz2whwaxr";
  };

  smashUltimateTrueEnding = pkgs.fetchurl {
    name = "smash-ultimate-true-ending.jpg";
    url = "https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/8aef7915-980a-4d4b-a5b5-656ef9888d35/dcxgor6-a15d647b-3662-4b96-b237-84ab196820e6.jpg?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsIm9iaiI6W1t7InBhdGgiOiIvZi84YWVmNzkxNS05ODBhLTRkNGItYTViNS02NTZlZjk4ODhkMzUvZGN4Z29yNi1hMTVkNjQ3Yi0zNjYyLTRiOTYtYjIzNy04NGFiMTk2ODIwZTYuanBnIn1dXSwiYXVkIjpbInVybjpzZXJ2aWNlOmZpbGUuZG93bmxvYWQiXX0.yleJ4LeSkR35tTccp9ckOfd9qflyqZKRBwqTCoTweiA";
    sha256 = "sha256-IjpsTg2hJ7jRsMoiRnrXRLFglsLp6sAihcnvuDbEij0=";
  };

  persona5RoyalCards = fetchSteamCards {
    appId = 1687950;
    cardNames = [
      "ryujiSakamoto"
      "haruOkumura"
      "goroAkechi"
      "makotoNijima"
      "kasumiYoshizawa"
      "lastSurprise"
      "morgana"
      "futabaSakura"
      "yusukeKitagawa"
      "annTakamaki"
      "hero"
    ];
    sha256 = "sha256-ImrPA1gj3JAFqjYMToShczksi+YJEtn+MyFacWwZcQU=";
  };

  persona4Golden = fetchSteamCards {
    appId = 1113000;
    cardNames = [
      "chieSatonaka"
      "naotoShirogane"
      "neverMore"
      "yosukeHanamura"
      "teddie"
      "riseKujikawa"
      "kanjiTatsumi"
      "yukikoAmagi"
      "yourAffection"
      "hero"
    ];
    sha256 = "sha256-JkcrN4tgMuFgZtV4m99Wsl7PLPYu96M+/o4hN99enxI=";
  };

  persona3Reload = fetchSteamCards {
    appId = 2161700;
    cardNames = [
      "junpeiIori"
      "chidoriYoshino"
      "takayaSakaki"
      "koromaru"
      "fuukaYamagishi"
      "jinShirato"
      "yukariTakeba"
      "shinjiroAragaki"
      "kenAmada"
      "mitsuruKirijo"
      "akihikoSanada"
      "aigis"
      "hero"
    ];
    sha256 = "sha256-34H5VvOnMbAOanEUjz6WRbsaN9GuKBrzcZD+eNbsMJA=";
  };

  persona5Strikers = fetchSteamCards {
    appId = 1382330;
    cardNames = [
      "fox"
      "panther"
      "joker"
      "mona"
      "noir"
      "queen"
      "sophie"
      "oracle"
      "skull"
    ];
    sha256 = "sha256-tbbTg4eBe269C0PGKa1wOhvzUTo2BXEKumk7In3oLsM=";
  };

  persona3Portable = fetchSteamCards {
    appId = 1809700;
    cardNames = [
      "junpeiIori"
      "protagonistM"
      "koromaru"
      "fuukaYamagishi"
      "yukariTakeba"
      "shinjiroAragaki"
      "kenAmada"
      "mitsuruKirijo"
      "akihikoSanada"
      "aigis"
      "protagonistF"
    ];
    sha256 = "sha256-Psk3SCjMCBQvno+q8sW4RYH3bJMOq/EodmIAnkgx9SE=";
  };

  persona5Tactica = fetchSteamCards {
    appId = 2254740;
    cardNames = [
      "shiningGlory"
      "alluringBeauty"
      "anElegantRevenge"
      "nocturnalWings"
      "aPinnacleView"
      "veilOfDawn"
      "skullOfRage"
      "ministryOfWisdom"
      "hiddenBookOfWitchcraft"
      "revolutionInYourHeart"
      "leaderFightingOppression"
      "swordOfTheIncognito"
    ];
    sha256 = "sha256-ULeZehXtyPIa5kutIdn68JkTcpuSJ5hv336jTR9WK+M=";
  };

  persona4ArenaUltimax = fetchSteamCards {
    appId = 1602010;
    cardNames = [
      "labrys"
      "chieSatonaka"
      "teddie"
      "mitsuruKirijo"
      "shoMinazuki"
      "akihikoSanada"
      "yuNarukami"
      "aigis"
    ];
    sha256 = "sha256-esG5Ikk5h8nmCsFtO1rgnLzg9T/HgePJuAt6RASja8w=";
  };

  royal = pkgs.fetchurl {
    url = "https://www.playstation.com/content/dam/global_pdc/en/games/wallpapers/persona-5-royal/playstation-wallpapers-persona-5-royal-desktop-wallpaper-01-ps4-27mar20-en-us.jpg";
    sha256 = "sha256-EWRTS4IFZj5kTg5A2smkJrv+9gdaIVCasW2hhDAILyo=";
  };
}
