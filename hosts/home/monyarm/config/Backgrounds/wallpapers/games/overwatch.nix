{ pkgs, image, ... }:
with image;
let
  bunnyGirl = pkgs.fetchurl {
    url = "https://cdna.artstation.com/p/assets/images/images/003/037/896/large/liang-xing-overwatch-bunny-girl.jpg";
    sha256 = "sha256-mo88iOMOVx9Sc8Jfw+nQSO0jBnG/npjnOaSbAdDv7o4=";
  };
in
{
  hanzoRule63 =
    pkgs.fetchurl {
      url = "https://cdnb.artstation.com/p/assets/images/images/002/864/329/large/liang-xing-hanzo13.jpg";
      sha256 = "sha256-JJoriad6ZNEWhZyDD9mPuE06SiwK4vKRH6ODxgr9nXQ=";
    }
    |> grow16x9North;

  dva15 =
    pkgs.fetchurl {
      url = "https://cdna.artstation.com/p/assets/images/images/002/664/208/large/liang-xing-dva15.jpg";
      sha256 = "sha256-zMtveDWOQsjaoH7jr2yCqh7ue3+SOLJsaqU3UDgUjG8=";
    }
    |> crop16x9North;

  widowmaker12 =
    pkgs.fetchurl {
      url = "https://cdnb.artstation.com/p/assets/images/images/002/743/621/large/liang-xing-widowmaker12.jpg";
      sha256 = "sha256-UB1AX6+n+HOn8HirrdCLYPigV45TJ0BsCU/jqwVBlDY=";
    }
    |> crop16x9North;

  mercy1 =
    pkgs.fetchurl {
      url = "https://cdna.artstation.com/p/assets/images/images/002/815/572/large/liang-xing-mercy1.jpg";
      sha256 = "sha256-Uol/0A8G5xr622eWxH4vLIQuoNSa6PBvm7LldJNVsmo=";
    }
    |> crop16x9North;

  bunnyGirlEast = bunnyGirl |> crop16x9East;

  bunnyGirlWest = bunnyGirl |> crop16x9West;

  ana = pkgs.fetchurl {
    url = "https://cdnb.artstation.com/p/assets/images/images/003/082/815/large/liang-xing-ana.jpg";
    sha256 = "sha256-raTKspkhK82ziJybWh4OQidp16PhN27NFoCCeVHaaIA=";
  };

  genji = pkgs.fetchurl {
    url = "https://cdnb.artstation.com/p/assets/images/images/003/142/481/large/liang-xing-genji.jpg";
    sha256 = "sha256-cjpjj/h0+h7LC7D6DD2lIiqj/66+edqZygHXBXYnz+o=";
  };

  group00 = pkgs.fetchurl {
    url = "https://cdnb.artstation.com/p/assets/images/images/003/175/753/large/liang-xing-00.jpg";
    sha256 = "sha256-KXQzpkp6+LHMT8yKNLLXWlyyVNgfYONQwvYoPy5FQNY=";
  };

  tracer14 = pkgs.fetchurl {
    url = "https://cdnb.artstation.com/p/assets/images/images/003/437/353/large/liang-xing-tracer14.jpg";
    sha256 = "sha256-yX+AIS2pNZlspR8DYq6CxdnAh1vc3c/Renn/rf3ZVV8=";
  };

  pharah = pkgs.fetchurl {
    url = "https://cdnb.artstation.com/p/assets/images/images/004/768/993/large/liang-xing-pharah.jpg";
    sha256 = "sha256-+8imdYbJYQRq7gnxWXafTKQp92QhrapbbpavaQbY9YE=";
  };

  cruiserDva =
    pkgs.fetchurl {
      url = "https://cdna.artstation.com/p/assets/images/images/006/579/472/large/liang-xing-cruiser-d-va-1.jpg";
      sha256 = "sha256-HfhoQglF9gw46pZ4kxz2RZ9iLpaU1wG8YX24cA6aSdo=";
    }
    |> crop16x9North;

  poolParty =
    pkgs.fetchurl {
      url = "https://cdna.artstation.com/p/assets/images/images/007/294/770/large/liang-xing-overwatch-pool-party.jpg";
      sha256 = "sha256-545Sas/7OXNL57s3YJrUMsM870cY5d6K1w9Jqc9JF1Y=";
    }
    |> crop16x9;

  officerMercy =
    pkgs.fetchurl {
      url = "https://cdnb.artstation.com/p/assets/images/images/008/739/857/large/liang-xing-officer-mercy.jpg";
      sha256 = "sha256-yS+xClRgJZoMleS+YqnkJZh06FO2aTP2vMQWFmWqusY=";
    }
    |> crop16x9;

  portrait91366 =
    pkgs.fetchurl {
      url = "https://cdna.artstation.com/p/assets/images/images/012/872/356/large/liang-xing-9-13-6.jpg";
      sha256 = "sha256-+vZ4d0OtZPluRZMwVtrP7n4cS5e3uoSrg6kHF8aC0D8=";
    }
    |> grow16x9;

  ashe = pkgs.fetchurl {
    url = "https://cdna.artstation.com/p/assets/images/images/015/048/836/large/liang-xing-ashe.jpg";
    sha256 = "sha256-e6BNSQFixT37TqCFLMDJry0RCmWGcNSOvWtVpG6533o=";
  };

  dva =
    pkgs.fetchurl {
      url = "https://cdna.artstation.com/p/assets/images/images/024/910/620/large/liang-xing-dva.jpg";
      sha256 = "sha256-5KD/EBBIGgFNSLYsgwMHucAOkyJDFEZgGDSKgJLfI6g=";
    }
    |> crop16x9North;

  racingMercy =
    pkgs.fetchurl {
      url = "https://cdnb.artstation.com/p/assets/images/images/025/030/499/large/liang-xing-racing-mercy.jpg";
      sha256 = "sha256-eN2hrfawBPB8gCGsmkXSjoDyjr6CAr8gLovQ2t8dgFI=";
    }
    |> crop16x9South;

  angel = pkgs.fetchurl {
    url = "https://cdnb.artstation.com/p/assets/images/images/069/407/003/large/kiko-l-jason-liang-le-sserafim-x-overwatch2.jpg";
    sha256 = "sha256-ij22XTZdXqzamZKHHKVt9esX0MhsYV7LAAVUVmDYo7Y=";
  };

  nurse = pkgs.fetchurl {
    url = "https://cdna.artstation.com/p/assets/images/images/070/808/302/large/kiko-l-jason-liang-overwatch-nurse.jpg";
    sha256 = "sha256-jThoVrlbPK+JjYoLd5zy/J4M79uYHM9d7yiyzohKr1M=";
  };

  bunnyGirl2 = pkgs.fetchurl {
    url = "https://cdnb.artstation.com/p/assets/images/images/073/201/239/large/kiko-l-jason-liang-overwatch-bunnygirl.jpg";
    sha256 = "sha256-jq1jbHotyqxgpxc/iDi+kvtGmMqYwCB590W/OOZCigE=";
  };

  untitled1 = pkgs.fetchurl {
    url = "https://cdnb.artstation.com/p/assets/images/images/044/963/791/large/will-murai-untitled-1.jpg";
    sha256 = "sha256-O1WBhjnYAvmrIf2L2V9QpyzNNlKjWls7yD09dgGcHuY=";
  };
}
