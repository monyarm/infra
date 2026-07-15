{ fetchSteamCards, ... }:
{
  secretOfMana = fetchSteamCards {
    appId = 637670;
    cardNames = [
      "flammie"
      "luka"
      "randi"
      "gemma"
      "dyluck"
      "popoi"
      "primm"
    ];
    sha256 = "sha256-YdqN2gb8TA88AWT9MGiFh7D6rw8IB5Dh9CB6j9MTO/k=";
  };
}
