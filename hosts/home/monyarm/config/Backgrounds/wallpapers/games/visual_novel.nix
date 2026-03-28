{ pkgs, fetchSteamCards, ... }:
{
  quickie = fetchSteamCards {
    appId = 1517850;
    hash = "sha256-CW3xVoA2v7VAFetXpWifWv2BdQQGPOG0kNOURBTt0+A=";
  };
  saniYang = fetchSteamCards {
    appId = 3464370;
    hash = "sha256-wGZeWMmLpWLeImq6gijRhHutXet1pnbIvdNmhdA3iRU=";
  };
  kaijuPrincess = fetchSteamCards {
    appId = 2291680;
    hash = "sha256-B4NtZPMJp6YeWLbOOHcZfIny01jlRGQEmOSEtpW+fqc=";
  };
  hornyWarp = fetchSteamCards {
    appId = 1539160;
    hash = "sha256-d9JHMDlaGIQG4c/ZBnTxUVqxYHM22HrXj134UtcTnpg=";
  };
  slimySextet = fetchSteamCards {
    appId = 1189070;
    hash = "sha256-KLLgExPcfA+4V4yjWrG/ufoiSB5747o9YU08b+G3nQ0=";
  };
  girlsInGlasses = fetchSteamCards {
    appId = 942990;
    hash = "sha256-aC8Y0r9q7K5rjiBkdajocJPvjTEYSl3HmnRmRj8jRKg=";
  };
  succubusFarm = fetchSteamCards {
    appId = 1455220;
    hash = "sha256-ZMlYIWCbpbwNRkf1sEfffElC9TnhglFxnIFIPXU6wm0=";
  };
  steamySextet = fetchSteamCards {
    appId = 1154110;
    hash = "sha256-i8WpyLslkzKdQLIIp0oMgKFQti7G+E+R+ewLqy3oPv8=";
  };
  steinsGateMyDarlingsEmbrace = fetchSteamCards {
    appId = 970560;
    hash = "sha256-l2B0bJHDiMi3qY6PcrGZeTut7aPpY+lzXEJInSjBG7k=";
    cardNames = [
      "mayushii"
      "assistant"
      "moenyan"
      "luka"
      "catgirl"
      "partimeWorker"
    ];
  };
  steinsGate = fetchSteamCards {
    appId = 412830;
    hash = "sha256-uW6u4y6r4cCVlBGzQzS/SofGZtukxZYmYZc2U3f7Hpg=";
  };
  nekopara0 = fetchSteamCards {
    appId = 385800;
    hash = "sha256-lFtHXPQ1aQi5WN4jCOoZYMAk5G0QmJrPa2UPuF11xIc=";
  };
  nekopara1 = fetchSteamCards {
    appId = 333600;
    hash = "sha256-LM/wZGWBzb13vLyXrjoGEuaoiK4vZQd45QTORV6i2xc=";
  };
  nekopara2 = fetchSteamCards {
    appId = 420110;
    hash = "sha256-3bjXE8dMcGFWKogkP1PurPtTIpqZb7cE8MiphysUAlY=";
  };
  nekopara3 = fetchSteamCards {
    appId = 602520;
    hash = "sha256-OchYw1DWHzsYKy60YzyoYELR703Oe9vuJRr/ZMxH8xg=";
  };
  nekopara4 = fetchSteamCards {
    appId = 1406990;
    hash = "sha256-pi7qeTCCzgveC0x4ConKmq56UaKZqznSs7lL55yJSyo=";
  };
  nurseLoveAddiction = fetchSteamCards {
    appId = 485040;
    hash = "sha256-TWESwrU9oXxo6EW91+0RfPXovXboned7ELXAiVsmHFk=";
  };
  longLiveTheQueen = fetchSteamCards {
    appId = 251990;
    hash = "sha256-Bn9zrR2L1VSVGiwZJ50D4fyD3bmeJJUxWwmsCpxco3I=";
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
