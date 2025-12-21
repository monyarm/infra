{ fetchSteamCards, ... }:
{
  aHatInTime = fetchSteamCards {
    appId = 253230;
    cardNames = [ "theKidWithTheHat" ];
    hash = "sha256-JqfcNPCh7o/t0EHyLxN6JjKFUfy9loMILELVnm3ouG8=";
  };
}
