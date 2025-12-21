{ pkgs, fetchSteamCards, ... }:
{
  oblivionRemastered = pkgs.fetchurl {
    url = "https://res.cloudinary.com/dewzjk72j/image/authenticated/s--LbLvc_X9--/c_lfill,w_2548/f_auto:image,q_auto/JAWS_Hero_KeyArt_FINAL_16x9_l0yj1i";
    sha256 = "1p14jg2q9qdyagmzykh6zcnwizfpgjp70w3n8nh9q6lkdsp317vz";
    name = "oblivionRemastered.jpg";
  };

  skyrim = fetchSteamCards {
    appId = 72850;
    cardNames = [
      "azura"
      "nordicRuins"
      "daedricWarrior"
      "draugrDeathlord"
      "troll"
      "wispmother"
    ];
    hash = "sha256-EFzOmRZYUP+I1yaWqT2P6IPmVJJvghCpeAzn7AovUFM=";
  };

  eso = fetchSteamCards {
    appId = 306130;
    hash = "sha256-6LqWVtHn2U+Q0lhciO6ifVztfiNUGsc/Q9UN8Ttq9uQ=";
  };
}
