{ fetchSteamCards, ... }:
{
  noMoreHeroes = fetchSteamCards {
    appId = 1420290;
    cardNames = [
      "master"
      "showtime"
      "aPlaceToDie"
      "assassinWithAMission"
      "schoolSInSession"
      "misterCosplay"
      "disasterBlaster"
      "homeRun"
      "mindBlowingVictory"
      "drunkenMentor"
      "rankingAgent"
      "goldenPipes"
      "brilliantInventor"
      "lifeInTheFastLane"
    ];
    sha256 = "sha256-TWQhAagtGAQR2P/UtQvaz+2hrh4Y46TSBSZ5uAA1jZQ=";
  };
}
