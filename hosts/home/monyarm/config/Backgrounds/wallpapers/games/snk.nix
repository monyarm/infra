{ fetchSteamCards, ... }:
{
  snkHeroinesTagTeamFrenzy = fetchSteamCards {
    appId = 794580;
    cardNames = [
      "luon"
      "nakoruru"
      "zarina"
      "terry"
      "loveHeart"
      "kukuri"
      "sylvie"
      "mian"
      "mai"
      "muimui"
      "leona"
      "athena"
      "yuri"
      "shermie"
      "kula"
    ];
    sha256 = "sha256-EN28YAk6AFBy8MSfxy6R9BxcRFmobLfzRpUcvL85PRw=";
  };
}
