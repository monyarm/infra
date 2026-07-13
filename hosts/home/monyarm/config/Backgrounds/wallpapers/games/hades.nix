{
  pkgs,
  fetchSteamCards,
  image,
  ...
}:
with image;
{
  hades = fetchSteamCards {
    appId = 1145360;
    hash = "sha256-oTwcQS2duatvbQflU811bztXXrra2hrwXYsxTik/HaU=";
  };
  hades2 = fetchSteamCards {
    appId = 1145350;
    hash = "sha256-Do6EVLW+NnkSwhIQxmypwJS32fzvCYBMrBVut9hMEko=";
  };

  furies =
    pkgs.fetchurl {
      url = "https://cdna.artstation.com/p/assets/images/images/036/965/440/large/citemer-liu-advange-sister-final-step2-a.jpg";
      sha256 = "sha256-7G0lllC8Oadah/b/9IDy4tHkTjlt5t68EK8F/Q/cNl0=";
    }
    |> crop16x9South;
}
