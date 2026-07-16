{
  pkgs,
  fetchSteamCards,
  ...
}:
{
  quickie = fetchSteamCards {
    appId = 1517850;
    cardNames = [
      "maiAhane"
      "toshikoAhane"
      "victoriaHolland"
      "ariaIto"
      "reikaMatsumoto"
      "professorBelmont"
      "satomiTanaka"
      "saraNakano"
    ];
    sha256 = "sha256-qg2MwjRogsEGEz0t1Iovzd3DGsAKjzr09LushmAr6k4=";
  };
  saniYang = fetchSteamCards {
    appId = 3464370;
    cardNames = [
      "clinicSani"
      "datingNamo"
      "elegantSani"
      "alluringKiwi"
      "cryingKiwi"
      "maskNamo"
    ];
    sha256 = "sha256-xCSeaBxupc6wOc7a5VKLudH9+nbpx6pOioarxhzX4VY=";
  };
  kaijuPrincess = fetchSteamCards {
    appId = 2291680;
    cardNames = [
      "amber"
      "flora"
      "hana"
      "daigneux"
      "aika"
      "iris"
      "helena"
    ];
    sha256 = "sha256-LzN0QZLsIXQf3XZdAS8LliKkFfLez+SrqnoetIUZCPs=";
  };
  hornyWarp = fetchSteamCards {
    appId = 1539160;
    cardNames = [
      "camelia"
      "bunny"
      "noelle"
      "lilyan"
      "demetra"
      "kukiAndLou"
    ];
    sha256 = "sha256-eh5A7CGxK9sW6odDCd3pWtMAIpTBiNRRPDUZoE+jujM=";
  };
  slimySextet = fetchSteamCards {
    appId = 1189070;
    cardNames = [
      "mary"
      "celeste"
      "adalyn"
      "quinn"
      "flare"
      "yumi"
    ];
    sha256 = "sha256-WoAjlAsuXyATzcmcp/A4XUvuJ22xQoKHWmwHBOEgUOU=";
  };
  girlsInGlasses = fetchSteamCards {
    appId = 942990;
    cardNames = [
      "irohaNenegawaSchool"
      "kanaMebusaki"
      "kotomiGarei"
      "irohaNenegawa"
      "kotomiGareiSchool"
      "kenTanaka"
      "kanaMebusakiSchool"
    ];
    sha256 = "sha256-FdcWWbXLQCbaJVL6FffNlJ6hYn3jd8CmxSP3OBLBDd0=";
  };
  succubusFarm = fetchSteamCards {
    appId = 1455220;
    cardNames = [
      "est"
      "luna"
      "rapti"
      "estAndRapti"
      "raptiAndLuna"
    ];
    sha256 = "sha256-rEUJXZK3Nnb1dC/pWx4aAuhriXZT4EeNpJiD/9yVUao=";
  };
  steamySextet = fetchSteamCards {
    appId = 1154110;
    cardNames = [
      "knight"
      "foxgirl"
      "demonQueen"
      "mage"
      "princess"
    ];
    sha256 = "sha256-rTbFyrN32iRg8a4Q+THSFO6EjedAfM41Hv9SlswQvGc=";
  };
  steinsGateMyDarlingsEmbrace = fetchSteamCards {
    appId = 970560;
    cardNames = [
      "mayushii"
      "assistant"
      "moeNyan"
      "luka"
      "catgirl"
      "partTimeWarrior"
    ];
    sha256 = "sha256-azbXR1n67S/LlpExZzfBRRp3/fYZZ1btqKnHqHJ9Mj0=";
  };
  steinsGate = fetchSteamCards {
    appId = 412830;
    cardNames = [
      "hashidaItaru"
      "shiinaMayuri"
      "makiseKurisu"
      "kiryuMoeka"
      "farisNyanNyan"
      "okabeRintaro"
      "amaneSuzuha"
      "urushibaraLuka"
    ];
    sha256 = "sha256-zTKgS/4xoyDu/CZakKc6AH4sqeq6N0dGREzllJUB/cc=";
  };
  nekopara0 = fetchSteamCards {
    appId = 385800;
    cardNames = [
      "minadukiFamily"
      "chocola"
      "vanilla"
      "maple"
      "cinnamon"
      "shigure"
      "coconut"
      "azuki"
    ];
    sha256 = "sha256-V8dT34Us2pvXGmJkKipc3JfBJgjUy3+Pf7eZBLBszDQ=";
  };
  nekopara1 = fetchSteamCards {
    appId = 333600;
    cardNames = [
      "chocola"
      "vanilla"
      "maple"
      "cinnamon"
      "shigure"
      "coconut"
      "azuki"
      "chocolaVanilla"
    ];
    sha256 = "sha256-SP+xcXQNuWLUVolO9gVDtkiba81IR8CnYT2MrzkcqW8=";
  };
  nekopara2 = fetchSteamCards {
    appId = 420110;
    cardNames = [
      "chocola"
      "vanilla"
      "maple"
      "cinnamon"
      "shigure"
      "coconut"
      "milk"
      "azuki"
    ];
    sha256 = "sha256-2el5y0KHZzkf8MbsQUxhFg69h8UBE392fB69jM4m9+c=";
  };
  nekopara3 = fetchSteamCards {
    appId = 602520;
    cardNames = [
      "chocola"
      "vanilla"
      "soleil"
      "maple"
      "cinnamon"
      "shigure"
      "coconut"
      "azuki"
    ];
    sha256 = "sha256-va3kglbgt+R6BrqW5thn3QzSStQqRJhec8w7NYToQeU=";
  };
  nekopara4 = fetchSteamCards {
    appId = 1406990;
    cardNames = [
      "nekoparaVol4Azuki"
      "nekoparaVol4Chocola"
      "nekoparaVol4Coconut"
      "nekoparaVol4Maple"
      "nekoparaVol4Shigure"
      "nekoparaVol4Cinnamon"
      "nekoparaVol4Vanilla"
      "nekoparaVol4Fraise"
    ];
    sha256 = "sha256-MlxqXM8GklMBjU/ERpLQUoS+pyUkYiyA82HDcPEjpUk=";
  };
  nurseLoveAddiction = fetchSteamCards {
    appId = 485040;
    cardNames = [
      "poster2"
      "sakuyaItsuki"
      "poster1"
      "shootingStar"
      "natsumatsuri"
      "asukaNao"
      "magicCharm"
      "summer"
      "pockyGame"
      "training"
    ];
    sha256 = "sha256-1/vrOKRcln4JSBNvQ4SSDq9hO/Utb6tpMMH6OicyjXQ=";
  };
  longLiveTheQueen = fetchSteamCards {
    appId = 251990;
    cardNames = [
      "drowned"
      "choked"
      "runThrough"
      "shot"
      "monsters"
      "poisoned"
      "bledOut"
      "blownUp"
      "bludgeoned"
      "magicalBlast"
      "soulDrain"
    ];
    sha256 = "sha256-PuKibX3XYYul8xC0r10w0UtxJpwm/coh6R73fBXAnlM=";
  };

  the-key-to-home = pkgs.fetchurl {
    url = "https://media.rawg.io/media/resize/1920/-/screenshots/4ed/4eda4f7188b6e506c239ba0b22e8a87b.jpg";
    hash = "sha256-Rs5VUQBtxMkYaajG9/tO48YJjBfu9cXpLoS/NuUFQAA=";
  };
  # Mirror for http://hadashi.product.co.jp/gallery/image/201312a.png
  threePingLoversLoloEdwarRumines = pkgs.fetchurl {
    url = "https://cdn.donmai.us/original/fa/00/__lolo_edwar_and_rumines_3ping_lovers_drawn_by_sakagami_umi__fa00ab93dc2c610470e6e68bb3ef9af7.png";
    hash = "sha256-pzNEVV88bodmzl90jkbF0ZtzQvtEAYdR7vWGLohwVw0=";
  };
  # Mirror for http://hadashi.product.co.jp/gallery/image/201312b.png
  threePingLoversFrayRinggitAliceErzan = pkgs.fetchurl {
    url = "https://cdn.donmai.us/original/47/43/__fray_ringgit_and_alice_erzan_3ping_lovers_drawn_by_ino_magloid__4743f832d13bfdfbbc539e2f2a4d4a90.png";
    hash = "sha256-NOlm+4lAe6gJLSLdg4GeqODh9d0AWhXouDHPPk4PWdI=";
  };
}
