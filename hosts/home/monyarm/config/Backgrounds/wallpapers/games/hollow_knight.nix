{ fetchSteamCards, ... }:
{
  hollowKnight = fetchSteamCards {
    appId = 367520;
    cardNames = [
      "soulMaster"
      "hollowKnight"
      "quirrel"
      "hornet"
      "brokenShell"
      "zote"
      "dungDefender"
      "mantisLords"
      "falseKnight"
    ];
    sha256 = "sha256-5dX/bMDPTewgiOyaAicuH+fhHy6LS6qL1dEp2ygvv0g=";
  };
  silksong = fetchSteamCards {
    appId = 1030300;
    cardNames = [
      "trobbio"
      "nuu"
      "phantom"
      "shakra"
      "sherma"
      "hornet"
      "grindle"
      "garmondZaza"
      "lace"
    ];
    sha256 = "sha256-tPf8n7fTDSvD4BsIoxt+AwIheUDmW8Bw0lHqXycqTV8=";
  };
}
