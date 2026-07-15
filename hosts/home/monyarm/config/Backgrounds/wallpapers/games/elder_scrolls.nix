{
  pkgs,
  fetchSteamCards,
  ...
}:
{
  oblivionRemastered = pkgs.fetchurl {
    url = "https://res.cloudinary.com/dewzjk72j/image/authenticated/s--LbLvc_X9--/c_lfill,w_2548/f_auto:image,q_auto/JAWS_Hero_KeyArt_FINAL_16x9_l0yj1i";
    sha256 = "1p14jg2q9qdyagmzykh6zcnwizfpgjp70w3n8nh9q6lkdsp317vz";
    name = "oblivionRemastered.jpg";
  };

  skyrim = fetchSteamCards {
    appId = 72850;
    cardNames = [
      "azura"
      "nordicRuins"
      "daedricWarrior"
      "draugrDeathlord"
      "troll"
      "wispmother"
    ];
    sha256 = "sha256-jVEnlxa8BSGnPzaRd3TuR4wHv9SssA9IaXRXlXml/fE=";
  };

  eso = fetchSteamCards {
    appId = 306130;
    cardNames = [
      "craglorn"
      "ayrenn"
      "molagBal"
      "eastmarch"
      "auridon"
      "jorunn"
      "emeric"
      "bangkorai"
    ];
    sha256 = "sha256-x02GJTFDaqNdx6tIcft6EwzBSJvK41wBuuTvq5BN1So=";
  };

  heroWillRise = pkgs.fetchurl {
    url = "https://shared.fastly.steamstatic.com/community_assets/images/items/2623190/dba06f4b7ec45fe108fb5f49423aa1725e412fcb.jpg";
    sha256 = "sha256-gro+IanS9dU+rjaQkFFN/Rb0uPSBjNiHYdgJ/Ku1PFY=";
  };
}
