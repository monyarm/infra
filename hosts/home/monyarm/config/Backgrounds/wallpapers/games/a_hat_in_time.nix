{ fetchSteamCards, ... }:
{
  aHatInTime = fetchSteamCards {
    appId = 253230;
    cardNames = [ "theKidWithTheHat" ];
    sha256 = "sha256-nGo51jSMJjNcaLilGFD9BF7kmee4Bx+Z9Su4Kjcdb4s=";
  };
}
