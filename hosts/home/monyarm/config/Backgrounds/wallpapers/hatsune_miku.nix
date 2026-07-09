{
  fetchSteamCards,
  fetchPixiv,
  image,
  ...
}:
with image;
{
  hatsuneMikuVR = fetchSteamCards {
    appId = 707300;
    hash = "sha256-ZIFv75pM6GpXHJc8TFQ8vJ+Nv2/+By+MdO67mPWRpTg=";
  };

  racingMiku =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2023/11/26/21/47/29/113736662_p1.jpg";
      sha256 = "sha256-hGFMaZdeOrA1kTHIlNgtd9xho3YCCUUF7QdKS57Fh3g=";
    }
    |> crop16x9East;
}
