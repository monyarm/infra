{
  image,
  fetchChaosium,
  ...
}:
with image;
let
  fetchRuneQuest = attrs: fetchChaosium (attrs // { game = "RuneQuest"; });
in
{
  prax = fetchRuneQuest {
    name = "Prax";
    hash = "sha256-c69Gjb7E9b1egTwjStTcdWkATaJDYbu9wJ17ROMWS+I=";
  };
  theGodsWall = fetchRuneQuest {
    name = "The Gods Wall";
    hash = "sha256-obOecppBmfRi7gwRxZD/tZVjNQBxs6AAgl2iRaYDCf4=";
  };
  ritual = fetchRuneQuest {
    name = "Ritual";
    hash = "sha256-T0ActN0XMfGflIwdmRY3kn2NuqzFlsOAxPkNNt361FQ=";
  };
  waspRiders = fetchRuneQuest {
    name = "Wasp Riders";
    hash = "sha256-8ZzK2ztHRn6YlY3ow5QTHJ9QvNVUf8+XK8L7r+OlNFU=";
  };
}
