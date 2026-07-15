{
  pkgs,
  fetchSteamCards,
  image,
  ...
}:
with image;
{
  hades = fetchSteamCards {
    appId = 1145360;
    cardNames = [
      "lordHades"
      "zeus"
      "msDusa"
      "megaera"
      "thanatos"
      "poseidon"
      "artemis"
      "achilles"
      "zagreus"
      "nyx"
    ];
    sha256 = "sha256-I2rFzJ4x2uZufxpTmBJwJYBQe1hvpXHj+M0DobnuzKA=";
  };
  hades2 = fetchSteamCards {
    appId = 1145350;
    cardNames = [
      "odysseus"
      "charon"
      "schelemeus"
      "nemesis"
      "eris"
      "melino"
      "selene"
      "artemis"
      "hecate"
      "moros"
    ];
    sha256 = "sha256-ihyObhd24wN8/MzTN81Ta2YDPG7BRlRPIgCuBQ419Bo=";
  };

  furies =
    pkgs.fetchurl {
      url = "https://cdna.artstation.com/p/assets/images/images/036/965/440/large/citemer-liu-advange-sister-final-step2-a.jpg";
      sha256 = "sha256-7G0lllC8Oadah/b/9IDy4tHkTjlt5t68EK8F/Q/cNl0=";
    }
    |> crop16x9South;
}
