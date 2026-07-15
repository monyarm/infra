{ fetchSteamCards, ... }:
{
  civ5 = fetchSteamCards {
    appId = 8930;
    cardNames = [
      "foreign"
      "bismarck"
      "economic"
      "science"
      "military"
      "washington"
      "catherine"
      "elizabethI"
    ];
    sha256 = "sha256-R8PboKbzMif8AUxWmSCJAqfbiKY6a4z4VHat78DXgso=";
  };
}
