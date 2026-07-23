{ pkgs, urlEncode, ... }:
{
  fetchChaosium =
    {
      game,
      name,
      sha256,
    }:
    pkgs.fetchurl {
      url = "https://www.chaosium.com/content/Backgrounds/${urlEncode game}%20Background%20-%20${urlEncode name}.jpg";
      inherit sha256;
    };
}
