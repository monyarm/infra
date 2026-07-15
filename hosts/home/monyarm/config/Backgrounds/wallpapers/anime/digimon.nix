{
  fetchSteamCards,
  fetchPixiv,
  image,
  ...
}:
with image;
{
  digimonStoryCyberSleuth = fetchSteamCards {
    appId = 1042550;
    cardNames = [
      "magnamon"
      "gallantmon"
      "crusadermon"
      "kyoko"
      "alphamon"
      "keisuke"
      "chitose"
      "erika"
      "ami"
      "nokia"
      "takumi"
      "leopardmon"
      "arata"
      "ryuji"
      "omnimon"
    ];
    sha256 = "sha256-hNDB75R949JgxIaNGfy/tq6HwQiSbGZiQ0afb/CuXcQ=";
  };

  angeDemon =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2024/05/20/21/15/16/118903027_p1.jpg";
      sha256 = "sha256-BEawXdjRsogC/wYjkiYM8Kn97+cV+tV7NyOYqq/h7oQ=";
    }
    |> crop16x9;
}
