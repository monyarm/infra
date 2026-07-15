{ fetchSteamCards, ... }:
{
  danganronpaTriggerHappyHavoc = fetchSteamCards {
    appId = 413410;
    cardNames = [
      "ultimateHeroes"
      "ultimateTerror"
      "ultimateAlienAbduction"
      "ultimateThrottle"
      "ultimateIdolConcert"
      "ultimateHeroines"
      "ultimateReadingRoom"
      "ultimateSaunaShowdown"
      "ultimatePlotTwist"
    ];
    sha256 = "sha256-n5Ajfs2C/+qTX1/dy0zi4uC5Mh1/JLkLbBZlKdLsK9w=";
  };
  danganronpa2GoodbyeDespair = fetchSteamCards {
    appId = 413420;
    cardNames = [
      "ultimateSuspiciousGlare"
      "ultimateMagicalGirl"
      "ultimatePensiveStare"
      "ultimateHopefulGaze"
      "ultimateConcert"
      "ultimateFunInTheSun"
      "ultimateHouseParty"
      "ultimateLaughRiot"
      "ultimateBikini"
    ];
    sha256 = "sha256-nFgKWQhgqws/QyEawBmWkX47o09W3TuSj1WGXDNTqtk=";
  };
  danganronpaV3KillingHarmony = fetchSteamCards {
    appId = 567640;
    cardNames = [
      "despair"
      "selflessDevotion"
      "lies"
      "truth"
      "newWorld"
      "friendship"
      "moonlight"
      "rituals"
      "training"
    ];
    sha256 = "sha256-NO3njnybH+CnkIys4YLzSJniINOo1pk8NK94CxeUVeE=";
  };
  danganronpaSUltimateSummerCamp = fetchSteamCards {
    appId = 1691970;
    cardNames = [
      "junkoAndKyoko"
      "akaneAndMonokuma"
      "nagito"
      "aoiAndMonomi"
      "tenkoAndSakura"
      "rantaroSayakaAndKotoko"
      "mikanAndRyoma"
      "k1B0AndKokichi"
      "ibukiAndMaki"
    ];
    sha256 = "sha256-a0vECnrH/uM4VhKzG6nlMR7flrL65EHXNrn1aFerqCc=";
  };
}
