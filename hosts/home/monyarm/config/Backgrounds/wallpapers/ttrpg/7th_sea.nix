{
  image,
  fetchChaosium,
  ...
}:
with image;
let
  fetch7thSea = attrs: fetchChaosium (attrs // { game = "7th Sea"; });
in
{
  nighttimeRow = fetch7thSea {
    name = "Nighttime Row";
    sha256 = "sha256-yrjZJWwPhX2UDKqYNyO6/KC+R03VhO8a6N1hfABSMqE=";
  };
  sailingAtSunset = fetch7thSea {
    name = "Sailing at Sunset";
    sha256 = "sha256-l53KXIEv0pD6axNQW9/6YWHaSUsfYuKEfzw09CjCflY=";
  };
  theKey = fetch7thSea {
    name = "The Key";
    sha256 = "sha256-pijD4nZTkPOn9XtyDJshzAuPnvPMgpNFH9N4KXV3fsY=";
  };
  thaeh = fetch7thSea {
    name = "Thaeh";
    sha256 = "sha256-12n/CqHAEfF4EYNsYW+S93g71nMAW9yeS55u7pgH+1E=";
  };
}
