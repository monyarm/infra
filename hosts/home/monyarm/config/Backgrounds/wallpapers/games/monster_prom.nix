{ fetchSteamCards, ... }:
{
  monsterProm = fetchSteamCards {
    appId = 743450;
    cardNames = [
      "rollercoaster"
      "auditorium"
      "rain"
      "gaming"
      "club"
      "chat"
      "fair"
      "phones"
    ];
    sha256 = "sha256-rg9Sy6w58hDWjP1iifoDswl3p5MfTH6qxAUwU1FLWAQ=";
  };
  monsterProm2 = fetchSteamCards {
    appId = 1140270;
    cardNames = [
      "wolfOutOfControl"
      "anotherRound"
      "sexySigil"
      "ventagram"
      "bucketDahlia"
      "dmitriAndMorty"
      "flodgeApprovesThisCard"
      "pizzaDeliveryGirl"
      "ultimateWeapon"
      "bewareTheBears"
      "fishWithTeeth"
      "divingArmor"
      "boo"
    ];
    sha256 = "sha256-S2njPr6eIveonFMERwpZ/njwqqBAflVy0pff/pb5qMA=";
  };
  monsterProm3 = fetchSteamCards {
    appId = 1665190;
    cardNames = [
      "duchessVicky"
      "viscountessJacqueline"
      "mostFearedGlitch"
      "ladyAmira"
      "sirAdrien"
      "honorableHazel"
      "baronNoodles"
      "lieutenantBrian"
      "sirJuan"
      "dukeOz"
      "abovewaterAmbassadorZoe"
    ];
    sha256 = "sha256-47ij7kNyEoVZwtINajmG+fJ3juMyUTYbXYoKw//QMhY=";
  };
}
