{ fetchSteamCards, ... }:
{
  mightMagicFatesTCG = fetchSteamCards {
    appId = 3918850;
    cardNames = [
      "spiritBoundDjinn"
      "abyssalLord"
      "agrael"
      "blackGuard"
      "warriorSeraph"
      "slava"
      "phiras"
      "ignatius"
      "taweretWarrior"
      "sandro"
      "titan"
      "shiNoShi"
      "anastasya"
      "nur"
      "greaterAirElemental"
    ];
    sha256 = "sha256-jMCrVvNYUDZ42x1EyKxidrADewKbB2bllS+HzwOPj7c=";
  };
  heroesOfMightMagicOldenEra = fetchSteamCards {
    appId = 3105440;
    cardNames = [
      "tavi"
      "vatawna"
      "shadespinnerOona"
      "ylwari"
      "theEyeCollective"
      "zenith"
    ];
    sha256 = "sha256-8Qc4GcEknHISa+1RIMTyJR1gJPkE/l7RiYEA0jemKhc=";
  };
}
