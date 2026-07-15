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
    cardNames = [
      "kaito"
      "hatsuneMikuV2"
      "meiko"
      "kagamineLen"
      "hatsuneMikuV4x"
      "megurineLuka"
      "kagamineRin"
      "hatsuneMikuV3"
    ];
    sha256 = "sha256-il5wcmSccsQPMrTsoiHLUPqsbs6+e+NWS3RpWIfkAR0=";
  };

  racingMiku =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2023/11/26/21/47/29/113736662_p1.jpg";
      sha256 = "sha256-hGFMaZdeOrA1kTHIlNgtd9xho3YCCUUF7QdKS57Fh3g=";
    }
    |> crop16x9East;
}
