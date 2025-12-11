{
  binFile,
  pkgs,
  crop16x9,
  dirs,
  linkContents,
  ...
}:
let
  linkWallpapers = linkContents "Pictures/wallpapers";

  sleepAmount = "5s"; # Configurable sleep amount
  swwwCommand = "swww img --transition-type=none --resize=fit";
  swwwScript = pkgs.writeText "swww-random" ''
    while true; do
            find "${dirs.wallpapers}" -maxdepth 1 -type f \
            | while read -r img; do
                    echo "$(</dev/urandom tr -dc a-zA-Z0-9 | head -c 8):$img"
            done \
            | sort -n | cut -d':' -f2- \
            | while read -r img; do
                    for d in $(swww query | awk '{print $2}' | sed s/://); do # see swww-query(1)
                            [ -z "$img" ] && if read -r img; then true; else break 2; fi
                            ${swwwCommand} --outputs "$d" "$img"
                            unset -v img # Each image should only be used once per loop
                    done
                    sleep "${sleepAmount}"
            done
    done
  '';

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

  falloutNewVegas01 = crop16x9 {
    src = pkgs.fetchurl {
      url = "https://images.ctfassets.net/rporu91m20dc/3jyjWTCiRqKQ4S4y8CEMSk/2f0d622f1c981a0aad7849b7fe5335ff/53490_2_17.jpg";
      sha256 = "0pn8xb0w38jsb1id8fkhkgjwgcd42b9cg7f94ph2d7bxp7v3fk7m";
    };
    gravity = "south";
  };

  falloutNewVegas02 = crop16x9 {
    src = pkgs.fetchurl {
      url = "https://images.ctfassets.net/rporu91m20dc/SJ5OfbOPqEGkIACOWWeIu/d8d4d6845e3a5b6f6c66dbafa2094079/53534_2_17.jpg";
      sha256 = "0zf9acjr1x09yyqf238r2p81w50gd1m6mcaqdsc6i2z9s7pjm5zk";
    };
    gravity = "south";
  };

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

  oblivionRemastered = pkgs.fetchurl {
    url = "https://res.cloudinary.com/dewzjk72j/image/authenticated/s--LbLvc_X9--/c_lfill,w_2548/f_auto:image,q_auto/JAWS_Hero_KeyArt_FINAL_16x9_l0yj1i";
    sha256 = "1p14jg2q9qdyagmzykh6zcnwizfpgjp70w3n8nh9q6lkdsp317vz";
    name = "oblivionRemastered.jpg";
  };

  doomTheDarkAges01 = pkgs.fetchurl {
    url = "https://images.mweb.bethesda.net/_images/doom-the-dark-ages/DOOM-TheDarkAges_Standard_16x9.jpg?f=jpg&h=1080&w=1920&s=054JKPMrjKcGy9s7w1Sp9UAgh2cVlBUs7BA8Zle8PvQ";
    sha256 = "09inc0zxiv8irny65mjqci6cisz52j78c2q7fkzx45x80zirds6v";
    name = "doomTheDarkAges01.jpg";
  };

  doomTheDarkAges02 = pkgs.fetchurl {
    url = "https://images.mweb.bethesda.net/_images/doom-the-dark-ages/DOOM-TheDarkAges_Premium_16x9.jpg?f=jpg&h=1080&w=1920&s=f9Awx-Q6HRyi7V8Df2t3ya5K8QXavBEwTwy4VJvCtDs";
    sha256 = "026jzsykv27fkg3rcfnsjnfg3paff9q59rkf87smrq561bcxxj7v";
    name = "doomTheDarkAges02.jpg";
  };

  doomTheDarkAges03 = pkgs.fetchurl {
    url = "https://res.cloudinary.com/dewzjk72j/image/authenticated/s---odN20kq--/c_lfill,w_2548/f_auto:image,q_auto/KeyArt_FINAL_Crop_lio0uv";
    sha256 = "0dr4b0m2bgj3gk92x88jkn82v1pvxsgjac6m2438lajwd27b7pnq";
    name = "doomTheDarkAges03.jpg";
  };

  indianaJonesGreatCircle01 = pkgs.fetchurl {
    url = "https://indianajones.bethesda.net/_static-indianajones/wallpapers/Keyart2_Wallpaper_2560x1440-01.jpg";
    sha256 = "1w96lnd2kqkpjwif1260jlyzjrj8lgf4l3lzd9xd363xh5k5612c";
  };

  indianaJonesGreatCircle02 = pkgs.fetchurl {
    url = "https://indianajones.bethesda.net/_static-indianajones/wallpapers/Keyart1_Wallpaper_2560x1440-01.jpg";
    sha256 = "09cryslkc6hvhl450bk6hy0i4r48n7180jpihlj9i6vhd3pvv27w";
  };

  persona5ThePhantomX01 = pkgs.fetchurl {
    url = "https://persona5x.com/assets/images/common/fankit/wallpaper/wallpaper01.jpg";
    sha256 = "09d8qc6fqvh4kg9n4034pyg9hp4sc2k0fkixf29ifjwdb85lv3gz";
  };

  persona5ThePhantomX02 = pkgs.fetchurl {
    url = "https://persona5x.com/assets/images/common/fankit/wallpaper/wallpaper03.jpg";
    sha256 = "0y7mvjlwffbmp9hbm0r79i2fick627ixscyvr4v3q06bz2whwaxr";
  };

  deadCells01 = pkgs.fetchurl {
    url = "https://motiontwin.com/img/presskit_dc/MasterArt_1080.jpg";
    sha256 = "0jgmb18rj1ah9b31cvqsb9xd19mv0x85kl6csvxp2xljcqfgz0ip";
  };

  deadCells02 = pkgs.fetchurl {
    url = "https://motiontwin.com/img/presskit_dc/OfficialKeyArt.jpg";
    sha256 = "1fyxknb081ip7s6j90pd0pannqnhnrjklnij5ma4n0b8la5k9zic";
  };

  deadCells03 = pkgs.fetchurl {
    url = "https://motiontwin.com/img/presskit_dc/MasterArt2_1080.jpg";
    sha256 = "06ll0swfvfxla3ibadq2v3klhhddrcqxbh4lv91qlb6i4pbfvp93";
  };

  deadCells04 = pkgs.fetchurl {
    url = "https://motiontwin.com/img/presskit_dc/AlternativeKeyArt.jpg";
    sha256 = "0pp52grb7jybhm0pp0llx2l735i53kdj3bkz0kyzvn6ngvdvjfsl";
  };

  bloodstained01 = pkgs.fetchurl {
    url = "https://static.wikia.nocookie.net/ritualofthenight/images/5/58/Bloodstained_Castle.png";
    sha256 = "1p3mbb8aj4ahkiwryzsrg88gfl1zjn9l46dxg3jc222cnmhgl7vn";
  };

  bloodstained02 = pkgs.fetchurl {
    url = "https://static.wikia.nocookie.net/ritualofthenight/images/3/32/Bloodstained_Wallpaper.png";
    sha256 = "0ad5n1q10rd71hcj95zxx1nmrds3ndkl4cgrdwm6ic3nwlkd3w5f";
  };

  bloodstained03 = pkgs.fetchurl {
    url = "https://static.wikia.nocookie.net/ritualofthenight/images/4/4d/Bathin_Boss_Revenge_victory.jpg";
    sha256 = "0sf3m6xxh3c5pkcanv3yirjzn9c9c03y3cfbmb79hr9b9lspimji";
  };

  persona5TradingCard01 = pkgs.fetchurl {
    url = "https://shared.fastly.steamstatic.com/community_assets/images/items/1687950/b487e27607ac4548fb99552505dd15176b6364aa.jpg";
    sha256 = "0mzcjcnnjyqw2329b3lsjr31bf6sv897r58cwaab9z21qxavdvaq";
  };

  persona5TradingCard02 = pkgs.fetchurl {
    url = "https://shared.fastly.steamstatic.com/community_assets/images/items/1687950/225c9ee443f2389369da6a399adbc92fb7382f0c.jpg";
    sha256 = "1k2vhk8cx9x72cm7wf98l9i289fq2k96qgfm8gdwym5g8mjaigni";
  };

  persona5TradingCard03 = pkgs.fetchurl {
    url = "https://shared.fastly.steamstatic.com/community_assets/images/items/1687950/0eebe0db15179c3ccbefed455879ecce86723111.jpg";
    sha256 = "1sad30jmpizv9dwqb9bnlmm4f7pqr4h3dnh4g7w3bzkzj2c430ib";
  };

  persona5TradingCard04 = pkgs.fetchurl {
    url = "https://shared.fastly.steamstatic.com/community_assets/images/items/1687950/906d63b2450811bfd671a2015312b62f2d970ec5.jpg";
    sha256 = "1mznym7s5dkyicdm2fn1i322554r5g13zf86q1sls3bsjm6lq85v";
  };

  persona5TradingCard05 = pkgs.fetchurl {
    url = "https://shared.fastly.steamstatic.com/community_assets/images/items/1687950/2033c59ae3a52e32999ff9831626e21f5fd258a7.jpg";
    sha256 = "0z352dw5bk08pv4156nafaa3vhawlb8vvnqjibag6ajrqyjffam2";
  };

  persona5TradingCard06 = pkgs.fetchurl {
    url = "https://shared.fastly.steamstatic.com/community_assets/images/items/1687950/d289aa9e60f46edc57ed354565fd70adad3e8498.jpg";
    sha256 = "17mxs1dmg1wmbf3acisr25p60iqcilckwab0bdds02bnp3agq7sj";
  };

  persona5TradingCard07 = pkgs.fetchurl {
    url = "https://shared.fastly.steamstatic.com/community_assets/images/items/1687950/2a234a0fb6bcf52825566af5364861da82f86805.jpg";
    sha256 = "1nz2ci68vi6pl2dqhhjd52y90dcwgpsq1lh3qb98817wpfsnzh78";
  };

  persona5TradingCard08 = pkgs.fetchurl {
    url = "https://shared.fastly.steamstatic.com/community_assets/images/items/1687950/d83d5852572726b4c8543b84c9194cfc350f8f5d.jpg";
    sha256 = "1div096y0yrmli8xlxa4f76g3988p5qrsdi081blwf151xbdxd0x";
  };

  persona5TradingCard09 = pkgs.fetchurl {
    url = "https://shared.fastly.steamstatic.com/community_assets/images/items/1687950/2db244c3aae5cf3ad6f920f0d35e389da979d627.jpg";
    sha256 = "07c3pqrwx79dz17yrznyykgj0jl9bdc28rlv2lm7sgj1cnaw64pa";
  };

  persona5TradingCard10 = pkgs.fetchurl {
    url = "https://shared.fastly.steamstatic.com/community_assets/images/items/1687950/24b767074e85cc73f4d34e87e7743505cf4e15f5.jpg";
    sha256 = "1xhbqfq268665nx16339v6vvvd112623gzhhixjsy49sykiyxpgh";
  };

  persona5TradingCard11 = pkgs.fetchurl {
    url = "https://shared.fastly.steamstatic.com/community_assets/images/items/1687950/48fab046009b72070c08a3829f92e45114ca13ec.jpg";
    sha256 = "1lx3jqnbsqxp4jpb8byiy9262dsrlf39vaz1zdhfnm64ib2gd08x";
  };

  persona5TradingCard12 = pkgs.fetchurl {
    url = "https://shared.fastly.steamstatic.com/community_assets/images/items/1687950/225c9ee443f2389369da6a399adbc92fb7382f0c.jpg";
    sha256 = "1k2vhk8cx9x72cm7wf98l9i289fq2k96qgfm8gdwym5g8mjaigni";
  };

  vampireSurvivors01 = pkgs.fetchurl {
    url = "https://shared.fastly.steamstatic.com/community_assets/images/items/1794680/dd5dcd2d70a02549946e556fc5a93f4ddedb711d.jpg";
    sha256 = "19apiiwhr0yhl0aq7yri2k7sh9r70nk0i5g993hq6w6436h69cdc";
  };
in
{
  home.file =
    (binFile swwwScript)
    // (linkWallpapers [
      # keep-sorted start
      bloodstained01
      bloodstained02
      bloodstained03
      deadCells01
      deadCells02
      deadCells03
      deadCells04
      doomTheDarkAges01
      doomTheDarkAges02
      doomTheDarkAges03
      fallout4Automatron
      fallout4FarHarbor
      fallout4NukaWorld
      fallout4Wallpaper01
      fallout4Wallpaper02
      fallout4Wallpaper03
      fallout4Wallpaper04
      fallout4Wallpaper05
      fallout4WastelandWorkshop
      fallout76AmericasPlayground
      fallout76Dawn
      fallout76IntroWallpaper
      fallout76LockedLoaded
      fallout76Patch42FullKeyArt
      fallout76PleaseStandBy
      fallout76SkylineValley
      fallout76T51b
      fallout76Tri
      fallout76VaultBoy
      fallout76Wallpaper01
      fallout76Wallpaper02
      fallout76Wallpaper03
      fallout76Wallpaper04
      fallout76Wallpaper05
      fallout76Wallpaper06
      fallout76Wallpaper07
      fallout76Wallpaper08
      fallout76Wallpaper09
      fallout76Wallpaper10
      fallout76Wallpaper11
      fallout76Wallpaper12
      fallout76Wallpaper13
      fallout76Wallpaper14
      falloutNewVegas01
      falloutNewVegas02
      indianaJonesGreatCircle01
      indianaJonesGreatCircle02
      oblivionRemastered
      persona5ThePhantomX01
      persona5ThePhantomX02
      persona5TradingCard01
      persona5TradingCard02
      persona5TradingCard03
      persona5TradingCard04
      persona5TradingCard05
      persona5TradingCard06
      persona5TradingCard07
      persona5TradingCard08
      persona5TradingCard09
      persona5TradingCard10
      persona5TradingCard11
      persona5TradingCard12
      vampireSurvivors01
      # keep-sorted end
    ]);
}
