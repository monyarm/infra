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
    hash = "sha256-ewRZ5aXBDEZOE6QZKR8rojIqd2NJQyJSh/5mQSnVGiE=";
  };

  angeDemon =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2024/05/20/21/15/16/118903027_p1.jpg";
      sha256 = "sha256-BEawXdjRsogC/wYjkiYM8Kn97+cV+tV7NyOYqq/h7oQ=";
    }
    |> crop16x9;
}
