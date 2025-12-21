{ fetchSteamCards, ... }:
{
  hades = fetchSteamCards {
    appId = 1145360;
    hash = "sha256-oTwcQS2duatvbQflU811bztXXrra2hrwXYsxTik/HaU=";
  };
  hades2 = fetchSteamCards {
    appId = 1145350;
    hash = "sha256-Do6EVLW+NnkSwhIQxmypwJS32fzvCYBMrBVut9hMEko=";
  };
}
