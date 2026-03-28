{
  pkgs,
  fetchVideo,
  extractFrames,
  fetchPixiv,
  image,
  ...
}:
with image;
{
  kivaAnthonyRay =
    pkgs.fetchurl {
      url = "https://cdna.artstation.com/p/assets/images/images/020/480/086/large/anthony-ray-kamen-rider-kiva-resize.jpg";
      sha256 = "sha256-rQfkmsuIwa8174AgizDorfskNb+7f/NiqKQ+MJUNlSI=";
    }
    |> crop16x9North;

  ryukiAnthonyRay =
    pkgs.fetchurl {
      url = "https://cdna.artstation.com/p/assets/images/images/020/333/856/large/anthony-ray-ryuki-resize.jpg";
      sha256 = "sha256-CQUuoOTizmOAlMVauoQ6QGQ75HVW+FZHsKrmzGortS8=";
    }
    |> crop16x9North;

  momotarosAnthonyRay =
    pkgs.fetchurl {
      url = "https://cdnb.artstation.com/p/assets/images/images/020/341/871/large/anthony-ray-dynamic-duo-1.jpg";
      sha256 = "sha256-gQxPCd9vQX9g5D/TW9P2Zv49mTPWIOvWod/KBh1TYuo=";
    }
    |> crop16x9North;

  izuZeroTwo =
    pkgs.fetchurl {
      url = "https://cdnb.artstation.com/p/assets/images/images/037/794/011/large/citemer-liu-22xiao.jpg";
      sha256 = "sha256-QenBpX1Xjyi0PVdWA/oO8w3bPm0NK6d6tGkLk6Jxa3U=";
    }
    |> growEdge16x9West;

  kivaEmperorMash =
    pkgs.fetchurl {
      url = "https://cdna.artstation.com/p/assets/images/images/015/736/552/large/mash-pool-kiva7s.jpg";
      sha256 = "sha256-52FgMDyAbP0vpof4NMA810iQCfeQeC0SbwiF08Taq5Y=";
    }
    |> crop16x9;

  kabutoAnthonyRay =
    pkgs.fetchurl {
      url = "https://cdnb.artstation.com/p/assets/images/images/020/340/073/large/anthony-ray-kabuto-resize.jpg";
      sha256 = "sha256-ISQDGm3NofIOr0t9ye2lZa8g+FpJmngBnnYjS+4OQe0=";
    }
    |> crop16x9North;

  hibikiAnthonyRay =
    pkgs.fetchurl {
      url = "https://cdnb.artstation.com/p/assets/images/images/020/339/953/large/anthony-ray-hibiki.jpg";
      sha256 = "sha256-7FPNPJMowwQMP8eMhUbespJwBsvY/AJvgJUnJDVqQrk=";
    }
    |> crop16x9North;

  bladeAnthonyRay =
    pkgs.fetchurl {
      url = "https://cdnb.artstation.com/p/assets/images/images/020/339/987/large/anthony-ray-blade-resize.jpg";
      sha256 = "sha256-VIlO2jMuzVCNGj1kskZhVI1elJkJ1Sb+2lMer4NqoUc=";
    }
    |> crop16x9North;

  faizAnthonyRay =
    pkgs.fetchurl {
      url = "https://cdnb.artstation.com/p/assets/images/images/020/333/899/large/anthony-ray-faiz-resize.jpg";
      sha256 = "sha256-sF+aZZKxcyoVVTezZId3P9nW+DQwR5BEy3uzYfRbuB0=";
    }
    |> crop16x9North;

  agitoAnthonyRay =
    pkgs.fetchurl {
      url = "https://cdnb.artstation.com/p/assets/images/images/020/333/719/large/anthony-ray-agito-resize.jpg";
      sha256 = "sha256-OF8HMTyTmAborW4llIeNsqRKHylcC2h7tT7/lfdMOvs=";
    }
    |> crop16x9North;

  kuugaAnthonyRay =
    pkgs.fetchurl {
      url = "https://cdnb.artstation.com/p/assets/images/images/020/333/383/large/anthony-ray-kuuga-resize-2.jpg";
      sha256 = "sha256-u8BTII1rlC7MSd9Hb/bHFIM4pV9NsGL6rV3U8n0he8Y=";
    }
    |> crop16x9North;

  dreadBothGender =
    pkgs.fetchurl {
      url = "https://cdna.artstation.com/p/assets/images/images/070/649/400/large/samcy-.jpg";
      sha256 = "sha256-OjJeAssDnu0X6yjYa/Ko3ixGKNHJx6PcuJbn+owI2E4=";
    }
    |> crop16x9North;
  fuutoPIOpening =
    extractFrames
      (fetchVideo {
        url = "https://www.youtube.com/watch?v=79phAUXkwsI";
        sha256 = "sha256-AYkLapLRg6CUVfveYheASvtlPWLANhQI10kCYOmSI3g=";
      })
      [
        "00.667"
        "10.385"
        "22.481"
        "1:00.185"
        "1:03.480"
        "1:09.569"
        "1:11.446"
        "1:15.450"
        "1:22.499"
        "1:28.338"
      ];

  zeztzInazumaPlasm = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2025/12/14/15/08/24/138591026_p0.png";
    sha256 = "sha256-GTkJ9rRJ+XCtBA7xDFIziYxRwJiJaEphlYsUCsfNBZw=";
  };

  waifu = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2022/08/18/19/49/06/100581232_p0.png";
    sha256 = "sha256-B+o0pPo1IArZCPc8/PzF+zAWTBQBwR43NEeXSAh88CQ=";
  };

  fuutoPIGroupShot = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2024/12/29/18/07/52/125663494_p0.png";
    sha256 = "sha256-SLJlmeV+781n5mi7k82h+Z+seqvv7vxofK9qdH3yfkA=";
  };

  zeroOne = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2022/08/19/10/52/44/100596267_p0.png";
    sha256 = "sha256-+H7KOqRO7tYfuW0LS8aLvRYeJ4WDed1U153TbpqcFj0=";
  };

  kamenRiderSaber =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2020/09/13/10/05/31/84339180_p0.jpg";
      sha256 = "sha256-DVgQJ13eT9kL4G5o0N1ZJ8XF3dR3rZQ9wCkBYVfXAlk=";
    }
    |> crop16x9North;

  skull =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2020/05/31/10/03/38/81982546_p0.jpg";
      sha256 = "sha256-RiVpSxY2PKrd93b5ebnoCBVtn1Uph+M55+lm+4qAYLo=";
    }
    |> transform {
      args = "-gravity north -crop 100%x66.67%";
      nameSuffix = "top-two-thirds";
    }
    |> grow16x9;

  izu =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2020/03/01/10/02/10/79815198_p0.jpg";
      sha256 = "sha256-rSQ+HyLg4u0XjSqdM+C/h41MsyQk0zgmjJF5Pjkehnk=";
    }
    |> crop16x9;

  grandZiO = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2019/06/23/10/03/58/75363300_p0.jpg";
    sha256 = "sha256-bEL+9TdRYTHzvrgFcJsx42g9dWoqDDmIsOg8CLpLKOY=";
  };

  ziOII =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2019/02/08/21/00/16/73069999_p0.jpg";
      sha256 = "sha256-rH3VEEQ28+kxWmfvcQ8KTvtNhsNkb6Wd5JukRGVJeig=";
    }
    |> crop16x9North;

  faiz = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2018/09/19/07/12/02/70767887_p1.jpg";
    sha256 = "sha256-vG934DqOC0a4PVJ0LPTL9JCOV4CwhtpZySr8VWAYz28=";
  };

  w = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2018/07/03/20/10/42/69522040_p0.jpg";
    sha256 = "sha256-jGVA748HYhQOUuirQ4OzM6FJM5Eto4sXAcBBROQNhKY=";
  };

  tajador = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2018/06/20/19/21/38/69320617_p0.jpg";
    sha256 = "sha256-NaeUfXBnnkq6JhwxaPz82xLQUj8WKNx4UQlV3oOYub8=";
  };

  driveHeart =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2018/03/21/15/22/27/67842644_p0.jpg";
      sha256 = "sha256-bfHImnNbYBUTBcV0VC25i7SnKIdrDYsHqA7SfhsdIdo=";
    }
    |> crop16x9;

  gaimBaron = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2018/04/14/13/31/48/68221283_p0.jpg";
    sha256 = "sha256-rSXfPI+yYXTJXXSLtjsY+MsMt7jtlWYVJjwxUE3B/ic=";
  };

  zeztzMissionStart = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2025/10/19/16/08/36/136458374_p0.jpg";
    sha256 = "sha256-9bFgj3euiXPiDr21/f3/r7nd36SLTfLLspoqKVvTP14=";
  };

  gavvMaster = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2025/05/18/19/47/58/130551231_p0.jpg";
    sha256 = "sha256-othFKMtUVWwFUijr0xKRitgbDlxHOmntRB/1bAVxQqQ=";
  };

  gavvSuper = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2025/04/06/13/05/16/129013986_p0.jpg";
    sha256 = "sha256-OmROINuragPswcbTvkv25ltii+bVD981Jld8zt6edcc=";
  };

  nextV3 = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2025/03/19/23/40/46/128391468_p0.jpg";
    sha256 = "sha256-hDeDjd4tWewgJcaVAOv1JpH5pVEZnTBJJ4J9vXpvBeI=";
  };

  kr001 = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2024/12/25/11/53/21/125519231_p0.jpg";
    sha256 = "sha256-zP2W/lfT6VLufhvCbc2c7KIOVGIdvFUYIAvH6pkVMZo=";
  };

  gavv = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2024/12/10/20/04/14/125069699_p0.jpg";
    sha256 = "sha256-3faPXNQviUeZ+tIonA1JuabI7m5cXUA21Hg/SxxoTFI=";
  };

  zeroOneMetalHopper = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2024/09/26/01/48/41/122774191_p0.jpg";
    sha256 = "sha256-X7C7Yc7ewAFhZuydr8kS4KPHjrKM4ICISxs+ci4x3DE=";
  };

  gotchardRainbow = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2024/06/06/20/53/33/119399621_p0.jpg";
    sha256 = "sha256-mUvVF6u+yUyNWjlO27m8basKoeerEy1h6ozhDJVik0E=";
  };

  gotchardPlatinum = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2024/03/22/01/54/52/117133260_p0.jpg";
    sha256 = "sha256-QqMS7hht5bsDUElZ0nPBgzVEZ2ppLbt7dTzo69waWwI=";
  };

  saberDraconicKnight = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2023/12/09/01/06/29/114063755_p0.jpg";
    sha256 = "sha256-PK6r47ThxHBd7ZUFZ+nn+6a/LikVjexdJ/KkldO0U58=";
  };

  juuga = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2023/10/28/20/06/15/112921799_p0.jpg";
    sha256 = "sha256-aZ8JFe7ayJ9TpYx/zCV4UO/LsGFIJpdUvTaJBLFigRU=";
  };

  tycoonBujinSword = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2023/09/01/00/53/48/111336346_p0.jpg";
    sha256 = "sha256-JjAhihvYR9RaKHgz67f3S4ZxZVno49d38jUOLLw9UTE=";
  };

  geatsBoostIX = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2023/06/18/14/35/10/109119089_p0.jpg";
    sha256 = "sha256-9wxnffEnXKBY2NDSMl4+qNeAyxPRazn34Sr1QXhvBvc=";
  };

  goodMorningRiderGirl = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2025/10/04/11/06/36/135854470_p0.jpg";
    sha256 = "sha256-rIXjUeevh/yPg78E+HxMae8vQ21qh3/o4njzpPpNImA=";
  };

  saberRiderGirl =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2024/12/17/10/45/22/125265203_p11.jpg";
      sha256 = "sha256-ONQ3ksUGuInKFG4A4Inv68Gn4v3hhW5iAD/euZBMomg=";
    }
    |> crop16x9South;

  reviceRiderGirls =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2024/07/17/11/27/07/120607636_p0.jpg";
      sha256 = "sha256-Mw0LKnop0Buc3bTB4hhy5fPZhCr0b3gX658iHwcYccc=";
    }
    |> crop16x9;

  crosszRiderGirl =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2024/02/09/22/56/31/115904378_p0.jpg";
      sha256 = "sha256-L6xs2ysiJAeZvMWyOFpipPZk1SBivpVCCGreC5IeaYA=";
    }
    |> crop16x9;

  saberRiderGirlAlmighty =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2024/02/10/01/08/32/115909134_p0.jpg";
      sha256 = "sha256-ZKhc969eezWexRS2CHY19RcVnsBTtF00CGT8kXZJUE8=";
    }
    |> crop16x9;

  wizardInfinityRiderGirl =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2024/02/14/02/04/17/116033185_p0.jpg";
      sha256 = "sha256-Le/fA3LHvDcEx2mYZIHuPY3eWT5UqaNshX20Ju3/QFc=";
    }
    |> crop16x9South;

  storiusRiderGirl =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2023/10/01/11/18/37/112177659_p0.jpg";
      sha256 = "sha256-In8gFw2Q5Gh+BKzqzFy4Fq2WRMUhb+b9ElhzN6MJjuc=";
    }
    |> crop16x9North;

  buffaRiderGirl =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2023/03/30/15/14/43/106695372_p0.jpg";
      sha256 = "sha256-XLcCLY5lY+JtV+5f38U51auqEJzg410REbEodix6p6Q=";
    }
    |> crop16x9North;

  horobiArkRiderGirl =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2022/05/28/15/15/12/98658814_p0.jpg";
      sha256 = "sha256-kH/4WH8ad23rY642EH2hI3o8ZgUtx5daT7p6YLUIaHI=";
    }
    |> crop16x9North;

  cronusRiderGirl =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2022/03/20/19/08/21/97050403_p0.jpg";
      sha256 = "sha256-hkHPo4c1mcueoHKmfi/Mh7CvzdWrq4P4NGmXyR4yCdI=";
    }
    |> crop16x9North;

  shinIchigo = pkgs.fetchurl {
    name = "shin-ichigo.jpg";
    url = "https://pbs.twimg.com/media/G6_0XmEaUAABt6e?format=jpg&name=4096x4096";
    hash = "sha256-WxnFVYtM2go+nTgizl0uBL/gzRUsNgEiSPfVzra4wJw=";
  };

  hellBros =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2018/02/18/09/13/52/67334146_p0.png";
      sha256 = "sha256-Q/FLDbfQR8sUDVT5f5qqVwBV2drwv4r3ANkX5l1pZJE=";
    }
    |> crop16x9North;

  vram = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2025/01/19/10/01/18/126358621_p0.jpg";
    sha256 = "sha256-UlzJaoQNHeUl1sY2JvkmAdf8fmWsiylW4ofCIQ2fkwA=";
  };

  gavvCaking = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2024/12/07/23/52/20/124987698_p1.jpg";
    sha256 = "sha256-puqFOpl2tw3cJ47/GG4uvWMVJb/kcLuuWYlVa/SjOyY=";
  };

  zeztzLeaning = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2025/07/15/12/01/43/132718341_p0.jpg";
    sha256 = "sha256-/P+GwhXOL5fCpeoN/czv8slYIc3HohXZEctfeUsZQVQ=";
  };

  gavvOverMaster = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2025/04/26/11/05/53/129710416_p1.jpg";
    sha256 = "sha256-6daWsoNUgFLt0TPyKK3M63bOiuwjx99n9L2h1cLHBQ4=";
  };

  valen = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2024/10/05/10/34/25/123047043_p0.jpg";
    sha256 = "sha256-2uAN4nvW87NCtnEraKaii9lIr547YQWD3yeQdMhWGTI=";
  };

  liselle = pkgs.fetchurl {
    name = "liselle.jpg";
    url = "https://pbs.twimg.com/media/GpdBqW4bEAMdieF?format=jpg&name=4096x4096";
    hash = "sha256-v6xRQ8VEUafkoaFux82LvM246dZJ6Cd7nS5m+TsBnjg=";
  };

  evolX = pkgs.fetchurl {
    name = "evol-x.jpg";
    url = "https://pbs.twimg.com/media/GhFuyIMa8AAtJQ5?format=jpg&name=large";
    hash = "sha256-FwJtzvnRngsNne72aWeDEvnklOsbCHokuqdFjhFwbnc=";
  };

  cakingArmy = pkgs.fetchurl {
    name = "caking-army.jpg";
    url = "https://pbs.twimg.com/media/Geb1pUgaUAAToDM?format=jpg&name=4096x4096";
    hash = "sha256-TbO0YoW6dy1VuvtaQM6+G4T5MDDw6ifGPYfzcT7xXyQ=";
  };
  tojima = pkgs.fetchurl {
    name = "tojima.jpg";
    url = "https://pbs.twimg.com/media/G26QOMPawAASFNA?format=jpg&name=large";
    sha256 = "sha256-Pnm+nSOFIBCbdeV1dB9YyEtRSqfIP8tkKLeHAaatTM4=";
  };

  ichigoNigo =
    fetchPixiv {
      url = "https://pbs.twimg.com/media/GOPkHnBbAAAG1PH?format=jpg&name=4096x4096";
      sha256 = "sha256-9392QaxK0xrukomO+w0UDH8dOvNedzqXHciMYinUwpg=";
    }
    |> grow16x9;

  ouja =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2023/02/16/03/30/22/105426309_p0.jpg";
      sha256 = "sha256-kLmz2FDIIwOqrWQT2aiZYIIU1vVmXeGajixdjMGIpnA=";
    }
    |> crop16x9North;

  oujaAllSurvive =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2023/01/03/18/14/19/104200987_p1.png";
      sha256 = "sha256-5pCXuwKX+4b16LCEKXZdWYiVpJ63V8Gc0LSfpEy4uqE=";
    }
    |> crop16x9North;

  faizRiders =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2018/11/07/15/44/20/71545055_p1.jpg";
      sha256 = "sha256-whiYXXRf/seWc3Cdut7D/0wwoltSrEfcRRoZLRk60aE=";
    }
    |> crop16x9;

  kivaFatherSon =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2022/10/23/13/30/58/102164512_p0.jpg";
      sha256 = "sha256-T4OPCFqACEb10u/5e7kNheysAZfxdPGHsuBC6Pcs+4c=";
    }
    |> crop16x9;

  cobraEvol =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2018/05/20/00/00/08/68825414_p0.png";
      sha256 = "sha256-OLVoxIvohX5drA+lJMgMzsUTczsjRjjGuxjOwNi7N7Y=";
    }
    |> crop16x9South;

  overQuartzer =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2019/07/27/23/12/53/75940616_p0.png";
      sha256 = "sha256-LL8LO/D9B3fcHt9HnjSwnb6ztOrUkQ3YStHfrmr5CPc=";
    }
    |> crop16x9West;

  ridersSubway =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2024/09/01/00/00/19/122018484_p0.png";
      sha256 = "sha256-ntjAH5NPcSkPkLMHO5hEvHUTtNE94pzeO+FIcbaGFTg=";
    }
    |> crop16x9North;

  geatsIX = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2024/01/29/00/00/13/115570781_p0.png";
    sha256 = "sha256-DxlPcbcFoVvbzAFL/+2tEbiviv9nnWZ5Z+Nk9cOjHO4=";
  };

  shinDoubleRiders = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2023/03/17/00/00/20/106278060_p0.png";
    sha256 = "sha256-Sfjv3ySelSa7AyX3oFp10XMutqp83Q+3zQvegCTxsaY=";
  };

  evil = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2022/01/10/00/00/18/95420328_p0.png";
    sha256 = "sha256-NGlUHgOV8/DkjuaB/1phoax3qXZh+LZcqo5nzbQPNnk=";
  };

  wMotorcycle =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2021/12/31/00/03/56/95145658_p1.png";
      sha256 = "sha256-g6MfuDUZQZHXdXZ8pLORuI4stXE/GzhgmxdGy79kzC8=";
    }
    |> crop16x9North;

  saberCrimson = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2021/12/31/00/03/56/95145658_p7.png";
    sha256 = "sha256-4DdTzItyZkkcn7y9gilX2IABbCmfaIV3iOeNk+78/6I=";
  };

  reviceForms = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2021/09/26/00/00/13/93015946_p0.png";
    sha256 = "sha256-hjQKwnSUkWpfuaX5AKMqK6frqb+nqPeioZzxpMK+DSQ=";
  };

  reviceRiders = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2021/10/24/00/00/11/93638730_p0.png";
    sha256 = "sha256-d2rUAelLCXlhwQP851+Yo3SQMyVshJygk6GEliwcwDI=";
  };

  arkVsArk =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2020/11/29/00/00/19/85968331_p0.png";
      sha256 = "sha256-JW7oD9R+y/1fjHXUkn/2xzhd63J5r5MGTC5zKNXH4iY=";
    }
    |> crop16x9North;

  zeroOneTrio =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2019/09/01/00/00/52/76559252_p0.png";
      sha256 = "sha256-qukN+aKD9FtokYTQfyACFTpbfpeJ4g2LoGXel+XZniY=";
    }
    |> crop16x9West;

  demushu =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2014/04/13/13/35/57/42866119_p0.jpg";
      sha256 = "sha256-72wOifxCMpHoJ62hPn1+l90JKeu5KsOqbDnQ+ry9ABQ=";
    }
    |> crop16x9North;

  redyue =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2014/09/07/08/39/44/45831983_p0.jpg";
      sha256 = "sha256-oGLFwMpECWQkEGAc/i+f1Vmg79ApbiBtEfChi3g4KhQ=";
    }
    |> crop16x9North;

  aguilera = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2022/05/26/10/39/49/98609964_p0.jpg";
    sha256 = "sha256-NrtSC0vQDNQRlQ9vZTd+vbc/ita0tQIgaUczX/Z7+PE=";
  };

  kivala =
    fetchPixiv {
      url = "https://i.pximg.net/img-original/img/2021/12/05/21/44/32/94590299_p0.jpg";
      sha256 = "sha256-B0ddDPn5LVIN5YEYQ+LJtEJQKHjxJkF+uZPBLdnSCpc=";
    }
    |> crop16x9South;

  fourzeNadeshiko = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2013/06/27/22/09/20/36676888_p0.jpg";
    sha256 = "sha256-R6QcJPnR1d2UuO2QKcZeQtGF6gyKkktFiJNGiRNZcek=";
  };

}
