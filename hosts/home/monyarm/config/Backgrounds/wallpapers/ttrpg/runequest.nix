{
  image,
  fetchChaosium,
  fetchSteam,
  getFile,
  ...
}:
with image;
let
  fetchRuneQuest = attrs: fetchChaosium (attrs // { game = "RuneQuest"; });
in
{
  prax = fetchRuneQuest {
    name = "Prax";
    sha256 = "sha256-c69Gjb7E9b1egTwjStTcdWkATaJDYbu9wJ17ROMWS+I=";
  };
  theGodsWall = fetchRuneQuest {
    name = "The Gods Wall";
    sha256 = "sha256-obOecppBmfRi7gwRxZD/tZVjNQBxs6AAgl2iRaYDCf4=";
  };
  ritual = fetchRuneQuest {
    name = "Ritual";
    sha256 = "sha256-T0ActN0XMfGflIwdmRY3kn2NuqzFlsOAxPkNNt361FQ=";
  };
  waspRiders = fetchRuneQuest {
    name = "Wasp Riders";
    sha256 = "sha256-8ZzK2ztHRn6YlY3ow5QTHJ9QvNVUf8+XK8L7r+OlNFU=";
  };
  kingOfTheDragonPass =
    let
      file = "kodp_wallpaper/wallpaper_king_of_the_dragon_pass_1920x1080.jpg";
    in
    fetchSteam {
      appId = 352220;
      depotId = 352223;
      manifestId = 7412102077928578515;
      sha256 = "sha256-Sy+Vmoo4ot9awtw+adJGxVamxyFi8XpBatkfjrxuxac=";
      filelist = [ file ];
    }
    |> getFile file;
}
