{
  fetchVideo,
  extractFrames,
  fetchPixiv,
  image,
  ...
}:
with image;
{
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

}
