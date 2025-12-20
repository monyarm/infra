{ pkgs, image, ... }:
{
  fallout4Wallpaper01 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/5wuLB3sJRmVIbOYtBMyTnB/85c2a987522d265ad7819d324d0f4a4a/FO4_ART_AnniversaryEdition_16x9_GUN_Clean__1_.png";
    sha256 = "1xdrydyxrvqvfg39lqr3d6qg2winzr7dnr3a4bliwyghcl20164q";
  };

  fallout4Wallpaper02 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/4s51P6NWSWzdDOSlcyrmNd/c29dba12e4be2431090333a4c3e09e48/FO4_SKU_AnniversaryEdition_Web-16x9_STD_Clean.png";
    sha256 = "1h74jz86wspfnqj10rfmnbnbpfn2yrkpna5y2kdxpd5w1hipkb6f";
  };

  fallout4NukaWorld = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/1MmrhHew0uDiOySyuidqw0/721fe7c72201b7aed5840fb669c41209/f4-dlc6_1920x1080-nologo-01.png";
    sha256 = "0cv2pyd8414j7zrx8dl12xv0p826z0sy348ijx344p4is0k3a20z";
  };

  fallout4Automatron = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/4HjvP1PuSs0aYiokquwWge/cd6b04ec14037b148c147d36064b0717/78458_2_12.jpg";
    sha256 = "1i0yl3fncg8wdv5s1hz953ws1jgqlcqgbr7r08zdh7ls2mv61635";
  };

  fallout4WastelandWorkshop = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/22kdNIb1PauUwcE6wEIKG4/4c5edc0ac6388b1c0b13a78816544f95/78474_2_12.jpg";
    sha256 = "0fbhqddqw77173kkzmdcr2qxjzgla4ijrdgiqa5x1g1hr86m61g0";
  };

  fallout4FarHarbor = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/15zkAnpbmcC6qYK0AUsC6G/610273ac0fe9c08c2cde7cb073f0c002/78528_2_12.jpg";
    sha256 = "1rrafsyqfzfw4jqb6g7gdi054rczgkcgazx46ja2j4i8dqdz1l5s";
  };

  fallout4Wallpaper03 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/zesGefykwgaQ6UuCaKaog/60029ff52a244e0802a5e3ada94251a6/72678_2_12.jpg";
    sha256 = "0a7i13xq5m8179bq8k308c7csbg547341cp4ggqz2h2xq4vrjh55";
  };

  fallout4Wallpaper04 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/6iunXvAP8Q2IiY6yGoOqks/3bbe2b66cb0fceb8a4aa1da48003eb9b/72650_2_17.jpg";
    sha256 = "0p02wsqdha7r9s2zda5cw8k2vd0gbdgs0cclr8g5igf3d5yn58ci";
  };

  fallout4Wallpaper05 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/4cPYJTvnVmEW2QYAccUQoU/811a13f2514f6be33892a35f56759018/64700_2_17.jpg";
    sha256 = "1c2rpf972fnvvyqfs4fv1q750q2bf6afkv1q5wzkgaxjpw7kydif";
  };

  falloutNewVegas01 = image.crop16x9South (
    pkgs.fetchurl {
      url = "https://images.ctfassets.net/rporu91m20dc/3jyjWTCiRqKQ4S4y8CEMSk/2f0d622f1c981a0aad7849b7fe5335ff/53490_2_17.jpg";
      sha256 = "0pn8xb0w38jsb1id8fkhkgjwgcd42b9cg7f94ph2d7bxp7v3fk7m";
    }
  );

  falloutNewVegas02 = image.crop16x9South (
    pkgs.fetchurl {
      url = "https://images.ctfassets.net/rporu91m20dc/SJ5OfbOPqEGkIACOWWeIu/d8d4d6845e3a5b6f6c66dbafa2094079/53534_2_17.jpg";
      sha256 = "0zf9acjr1x09yyqf238r2p81w50gd1m6mcaqdsc6i2z9s7pjm5zk";
    }
  );

  fallout76SkylineValley = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/4iZDzhIk24kD3Lru5ej0Pj/56ddc594a230b472537e983a95ff7d78/F76_P52_Skyline-Valley_Standard_3840x2160.png";
    sha256 = "1m5cxbhz5rnhvrfvvqwway5psyxq2bar0zq7hlwlggi3yw29ww9z";
  };

  fallout76Wallpaper01 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/1ToaIEwrJzle2iY2VPkaZ4/5dd387ee85fb755d4bbb6c1d1fb70413/F76_S1-1.PNG";
    sha256 = "054gn4cn9qvshgjs0l51nm0mcq4fpjhfm385kj2jbz59fja79mjl";
  };

  fallout76Wallpaper02 = pkgs.fetchurl {
    url = "https://downloads.ctfassets.net/rporu91m20dc/w8uzXrsYNn92eTLaz2xYS/b82be98992028b1559775548e0c43163/F76_S16_Full-Art__final_.png";
    sha256 = "1j5sr88619ckic71d8rh643hffkk8ywzdshhj7bsddzl26943yw7";
  };

  fallout76AmericasPlayground = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/2mERQwMn6aytxqwtxHmkij/a1976f250e388cafad5a877f0ba48e8e/F76_P50_Americas-Playground_3840x2160.png";
    sha256 = "04da41ks968v8hvnjlmrn6i3447150zbyj11jpw3zi9k41zmmvsk";
  };

  fallout76Wallpaper03 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/5rTxxZCVusojfj0JnRm1Oe/60215f22aeccde7d847c47faa14017b0/F76_P5-3.PNG";
    sha256 = "0v6jw4yhv1yl41lygk4lx4gav0lbwhndbhjpgqfwa7xl2xfyp4yp";
  };

  fallout76Wallpaper04 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/4HFdjowwXT7bRpPII9zvSs/20ae5c41db62f48c5c5e744639e393db/image__48_.png";
    sha256 = "1ryg4i1ghzc83y47f3wh86axljxlcarnlyk602pb1vb800qr8kpm";
  };

  fallout76Wallpaper05 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/5TyNgO2Cp56a4sdHeQTcuZ/fbd71880b56a06803828ed20352cb967/Fallout76_S14_FullArt_NOLOGO.jpg";
    sha256 = "07kwfzgkzba29p1qfb1lp3c5zrs9g0b1zhwaj1j0ch1p4s51chnp";
  };

  fallout76Wallpaper06 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/52GdzmGzYF0XOR3eBgNcKz/c3cf4bbbc8d53f3044f2bac7ac5d3f97/Fallout76_S13_FullArt_FINAL.png";
    sha256 = "0vk1xfsbv1yazganbrbpq7zwwc679gxgwwfpqw605ydygjrj380a";
  };

  fallout76Patch42FullKeyArt = pkgs.fetchurl {
    url = "https://downloads.ctfassets.net/rporu91m20dc/4Ko95uG4UDCcwMFOtzLEFf/790dc19f060a9823f766e9891a7ef97b/F76_Patch42_FullKeyArt.png";
    sha256 = "0y6dfxc064d7qpahv5r5m19ngg060cs6pjzf5ibn27wirnc7igdw";
  };

  fallout76Wallpaper07 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/6NzpVf2zoGSmEpVt8QfcLd/690b958610c488778489a29ca4a17baa/Fallout76_S12_FullArt_FINAL.png";
    sha256 = "00kvzsnwa7nskv6h1pf25xqjz1vqppqrsbkw80w7kdd8dnv3awzr";
  };

  fallout76Wallpaper08 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/1LvS3QyzNgjPR0zxXoENDX/abc920c4d1080193c0e08b1166d0a328/Fallout76_S11_FullArt_FINAL_REV2_NOLOGO.jpg";
    sha256 = "05ad2rsxkqxzd09l7ahj51jdsmazmb65vcgarjq1i1a57jfp7ycn";
  };

  fallout76Wallpaper09 = pkgs.fetchurl {
    url = "https://downloads.ctfassets.net/rporu91m20dc/1HgpugWWVQCPm7fiUCWhND/5f8a01599a4788a158bb061c98aea4e6/F76_S10_KeyArt_Final.png";
    sha256 = "1wwi8siqwwhamfz4141l0khwkmnl12jl7mxjhj2qhfmna2blii59";
  };

  fallout76Wallpaper10 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/ghFeKMDZHCMmR2EiAyeG3/9f586a470a3c58f0feb44c8360dc3b4c/FO76-Season8_Xbox_GameHub_1920x1080-01.png";
    sha256 = "0rkhnxf7a2skqz6hn0xdzdajjb7xzgr39rm5flnp499ksfvfrkkp";
  };

  fallout76Wallpaper11 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/3Tsf4ZoabdrVT47qZSBho3/c8b07a527be569aee239138db8112f8c/FO76-Season7_Wallpaper.png";
    sha256 = "0pq6vgm2j9nlvxb04r10g23i96qnip43i16wigpg942333xjripv";
  };

  fallout76Wallpaper12 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/3Iec9ie7UFyvYQfV0lamez/86edfe9574444c690362bd63828fd5cc/Fallout76_S6-Art_FINAL.png";
    sha256 = "08m30a5jw7wq4f2yz1i63lc0391i2s02kwhjx35sqwnjykqi5lfv";
  };

  fallout76Wallpaper13 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/3JmHACgku58ji4lJGSV96M/182982bb48d16a566224e345c281cb2c/F76-Season5_Xbox_HeroArt_1920x1080-01.png";
    sha256 = "1x9n4yk44gfpxdh91i99mriwjk6fb8i9pah37pzmg9dgr7nf6iv4";
  };

  fallout76Wallpaper14 = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/6yNh1yabrZICOge1EVEtkD/4698bee939b8cbc0e465afbed6ffbcfd/F76-Season4_Bnet-ProductPage_1920x1080-01.png";
    sha256 = "0rigrrdbryighwlndnwsi0y5y7a95384p80nxc91dh46q2pn2r9w";
  };

  fallout76LockedLoaded = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/7MdQU06IuRJ2qkwPGn2mLD/0d1bf21bd38384ca9ac166d1092ef711/F76-Locked_Loaded_Bnet-ProductPage_1920x1080-01__1_.png";
    sha256 = "1r829i7cpq8cysbc2dfp5iy0y1609z4hk0z65d9sa6qdpa8ysvh0";
  };

  fallout76Dawn = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/18hoMg3faeYoueiac4KYGM/4ba996bdc856aedf9750412cba15025b/Fallout76_Dawn_MediaDesktopWallpaper_1920x1080-01.png";
    sha256 = "1irn7yc943y5415i4hnz5cmlf490fd5x3cmgmmll26mc5ys7k4h9";
  };

  fallout76PleaseStandBy = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/66OBPoDoc0CYEYkY8oAgcs/b64dc4a5ceb5b767d1c53e2bb2121980/Fallout76_PleaseStandBy_MediaDesktopWallpaper_1920x1080-01.png";
    sha256 = "0xwzxpp9a3nn8id3fbvi39d2dly3yxklxzkzw4bh51s3xg0fmr8c";
  };

  fallout76T51b = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/41jsmHgjNuO86MsuY6aI6m/c5f9a3a3b49b41c62ca932aba2cb981d/Fallout76_T51b_MediaDesktopWallpaper_1920x1080-01.png";
    sha256 = "0nwsw1lg3aka2751h7pp29vys7d6my58n5b9xx3l5y5jq0hmk4xa";
  };

  fallout76Tri = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/oqAYscZO3AcwAoKWMAQMO/a5c485b0dab3e645fdc82c6f4e682664/Fallout76_Tri_MediaDesktopWallpaper_1920x1080-01.png";
    sha256 = "1fyrfd8i8hmdj41db9y58s2sfkvp2392y9hkvzgxchq52vlzl5sw";
  };

  fallout76VaultBoy = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/2j5cZ5XX3qMoCOOOw6qqI6/5f46c0e8f06b290aa167317d5f632dc5/Fallout76_VaultBoy_MediaDesktopWallpaper_1920x1080-01.png";
    sha256 = "03i9mxpag3s1xn569wjdn697lxcs3m36nr33r83aj0014qpzgxsc";
  };

  fallout76IntroWallpaper = pkgs.fetchurl {
    url = "https://images.ctfassets.net/rporu91m20dc/3fo959LDLyIKu06eOaKUIW/79140e72e1bbb7a732c301555ef9c311/IntroWallpaper_1920x1080.jpg";
    sha256 = "0b70qvqyhx8da8v6wnphwjfwhv8zgvb7gin315cdvcyp3xxl6ydq";
  };
}
