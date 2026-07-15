{ fetchSteamCards, ... }:
{
  metaphorReFantazio = fetchSteamCards {
    appId = 2679460;
    cardNames = [
      "euphaEtoreika"
      "arvidGrius"
      "leonStrohl"
      "eHulkenberg"
      "heismayNoctule"
      "gallica"
      "neueirusCorax"
      "juaniCygnus"
      "basilioMagnus"
      "travelingBoy"
    ];
    sha256 = "sha256-IsA6w7a8+YCAOMOwNYCv8GOc1IfxtAxCpSGt5NfbgOk=";
  };
}
