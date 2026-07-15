{
  pkgs,
  fetchSteamCards,
  image,
  ...
}:
with image;
{
  ultraStreetFighterIV = fetchSteamCards {
    appId = 45760;
    cardNames = [
      "poison"
      "hugo"
      "ryu"
      "decapre"
      "cViper"
      "chunli"
      "rolento"
      "elena"
      "yang"
      "cody"
    ];
    sha256 = "sha256-QjxerMcaCPX0rOallZihMb35osCAQx/b0juVWCqpQWw=";
  };

  bunnyGroup =
    pkgs.fetchurl {
      url = "https://cdnb.artstation.com/p/assets/images/images/070/415/761/large/citemer-liu-xiao.jpg";
      sha256 = "sha256-7GXIuge4vq1yQsxObtnDQNlWjAwzcvfRItPlFlmGaZk=";
    }
    |> crop16x9North;

  chunLiDragon = pkgs.fetchurl {
    url = "https://cdna.artstation.com/p/assets/images/images/069/853/256/large/citemer-liu-heng.jpg";
    sha256 = "sha256-MhftoaG32UrAFrZoSECGxTcjkYT0+rfn7d1+bg1R97k=";
  };

  cammyColage = pkgs.fetchurl {
    url = "https://cdnb.artstation.com/p/assets/images/images/068/499/885/large/citemer-liu-cammy-fullxiao.jpg";
    sha256 = "sha256-9Xfbi8i1AZ5/HSiuPpR76K6oeF7JW78kwp6xEyET1nM=";
  };

  juriLounging =
    pkgs.fetchurl {
      url = "https://cdna.artstation.com/p/assets/images/images/070/105/788/large/citemer-liu-1xiao.jpg";
      sha256 = "sha256-n+PIMHX+NaCK36w2BAM9uwP/WUELoteOPq41O04vSGk=";
    }
    |> transform {
      args = "-fuzz 10% -trim";
      nameSuffix = "cropped-white";
    }
    |> grow16x9;
}
