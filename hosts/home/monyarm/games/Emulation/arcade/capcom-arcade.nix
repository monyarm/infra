{
  lib,
  pkgs,
  fetchSteam,
  mkArcade,
  config,
  ...
}:
let
  # Depot is a raw RE Engine PAK archive, not a MAME romset: REE.Unpacker
  # pulls the title's .mameac.2 out of the .pak (CAS_STM_Release / CAS2_STM_Release
  # tag list), REE.Rom.Cryptor decrypts that into a plain MAME-loadable zip.
  # Every title's PAK carries a degenerate ~26-byte placeholder .mameac.2 under
  # natives/stm/roms/ alongside the real payload under natives/stm/streaming/roms/
  # (same basename in both places) -- and 1st Stadium titles can also bundle a
  # second region/revision MAME clone under a differently-named .mameac.2, same
  # as 2nd Stadium. Search streaming/roms/ specifically (not a size heuristic --
  # some real payloads, e.g. vulgus, are themselves only tens of KB) and require
  # an exact variant-name match, so the right clone always lands under the right
  # shortname.
  capcomZip =
    tag: depot: variant:
    pkgs.runCommand "${variant}.zip"
      {
        nativeBuildInputs = [
          pkgs.ree-tools
        ];
      }
      ''
        REE.Unpacker ${tag} "$(find ${depot} -name '*.pak' -print -quit)" "$PWD/unpacked"
        REE.Rom.Cryptor "$(find "$PWD/unpacked/natives/stm/streaming/roms" -name '${variant}.mameac.2' -print -quit)" "$out"
      '';

  # every variant (primary shortname + region/revision clones) is registered
  # into games.emulation.roms, same as genesis.nix; programs.steam.games below
  # pulls the launchable one back out of that registry rather than building it
  # again, so mkArcade's compressRom only ever runs on the one it launches.
  mkCapcomEntry =
    tag:
    {
      name,
      appId,
      depotId,
      manifestId,
      shortname,
      extraVariants ? [ ],
      sha256 ? lib.fakeHash,
    }:
    let
      depot = fetchSteam {
        inherit
          appId
          depotId
          manifestId
          sha256
          ;
      };
    in
    {
      inherit name shortname;
      roms = lib.listToAttrs (
        map (variant: lib.nameValuePair variant (capcomZip tag depot variant)) (
          [ shortname ] ++ extraVariants
        )
      );
    };

  mkCapcomArcade = args: mkCapcomEntry "CAS_STM_Release" (args // { appId = args.appId or 1515950; });
  mkCapcomArcade2 =
    args: mkCapcomEntry "CAS2_STM_Release" (args // { appId = args.appId or 1755910; });

  # 1943 ships in the base app's own depot, not a DLC depot, and its .pak
  # carries TWO real MAME romsets -- 1943u (US) and 1943jc (Japan clone) --
  # plus degenerate stub .mameac.2 files (~26 bytes) under natives/stm/roms/
  # that must not be picked. -size +100k picks the real ones under
  # natives/stm/streaming/roms/ instead.
  base1943Depot = fetchSteam {
    appId = 1515950;
    depotId = 1515951;
    manifestId = 8730299595221726936;
    sha256 = "sha256-CSwblCD82ULPAIpPVb1aBVdiwGVtEEc8XQUaOloPrLY=";
  };

  capcom1943Zip =
    name:
    pkgs.runCommand "${name}.zip"
      {
        nativeBuildInputs = [
          pkgs.ree-tools
        ];
      }
      ''
        # base depot also ships patch_*.pak files with no rom data --
        # name re_chunk_000.pak exactly, unqualified *.pak glob picks wrong file
        REE.Unpacker CAS_STM_Release "$(find ${base1943Depot} -name 're_chunk_000.pak' -print -quit)" "$PWD/unpacked"
        REE.Rom.Cryptor "$(find "$PWD/unpacked" -name '${name}.mameac.2' -size +100k -print -quit)" "$out"
      '';

  capcomEntries = {
    # Capcom Arcade Stadium -- base app 1515950 + all 31 DLC titles owned.
    CAS_1943_BATTLE_OF_MIDWAY = {
      name = "1943 -The Battle of Midway-";
      shortname = "1943u";
      roms = {
        "1943u" = capcom1943Zip "1943u";
        "1943jc" = capcom1943Zip "1943jc";
      };
    };
    CAS_GHOSTS_N_GOBLINS = mkCapcomArcade {
      name = "Ghosts 'n Goblins";
      depotId = 1556690;
      manifestId = 720985918200840956;
      sha256 = "sha256-XzBl+QGQPVV12ctyGzz4W1aMn3viOtnH9zBf0F2Lhhw=";
      shortname = "gng";
      extraVariants = [ "makaimurg" ];
    };
    CAS_VULGUS = mkCapcomArcade {
      name = "VULGUS";
      depotId = 1556700;
      manifestId = 5256365349174359542;
      sha256 = "sha256-ORFIR8OAGJJKLx2t9mXvEvDuwgMWi1igvmd73D5N55s=";
      shortname = "vulgus";
      extraVariants = [ "vulgusj" ];
    };
    CAS_PIRATE_SHIP_HIGEMARU = mkCapcomArcade {
      name = "PIRATE SHIP HIGEMARU";
      depotId = 1556701;
      manifestId = 2839819348004594506;
      sha256 = "sha256-53eSPA56xr9nHR7SfMUkbipsiPgsn21wcDhm/0DWOrc=";
      shortname = "higemaru";
    };
    CAS_1942 = mkCapcomArcade {
      name = "1942";
      depotId = 1556702;
      manifestId = 930775891296948257;
      sha256 = "sha256-u+3h6M84jHpqexD6J09XOijM3QSJ/msEZza55ogb6bs=";
      shortname = "1942";
    };
    CAS_COMMANDO = mkCapcomArcade {
      name = "COMMANDO";
      depotId = 1556703;
      manifestId = 3068512296888649504;
      sha256 = "sha256-x2Z4Rxh3GXc38uJ5EVAOBbMcKA/5CtmQ+DbfOq1w/T0=";
      shortname = "commandou";
      extraVariants = [ "commandoj" ];
    };
    CAS_SECTION_Z = mkCapcomArcade {
      name = "SECTION Z";
      depotId = 1556704;
      manifestId = 4115256064438261885;
      sha256 = "sha256-+3HgyaIFY7X8yOenZWoeiN+ijxW3xin2R3aqDkJY9TM=";
      shortname = "sectionza";
    };
    CAS_TROJAN = mkCapcomArcade {
      name = "Tatakai no Banka";
      depotId = 1556705;
      manifestId = 2012252709011603898;
      sha256 = "sha256-KmXOBBFZOk05TzmLtItEdn54YrOgCBaRkKRHifiYKmk=";
      shortname = "trojanj";
    };
    CAS_LEGENDARY_WINGS = mkCapcomArcade {
      name = "LEGENDARY WINGS";
      depotId = 1556706;
      manifestId = 1060722444987922461;
      sha256 = "sha256-JJUDUohvGyP38GUyMqiDLzf0Lx/cuisqJWl5otpcoP0=";
      shortname = "lwings";
      extraVariants = [ "lwingsja" ];
    };
    CAS_BIONIC_COMMANDO = mkCapcomArcade {
      name = "BIONIC COMMANDO";
      depotId = 1556707;
      manifestId = 3311060249623978404;
      sha256 = "sha256-Kp/+k9JTzvo5J70xP3qK6NSaVFqW1RtnAvQd979PilA=";
      shortname = "bionicc2";
    };
    CAS_FORGOTTEN_WORLDS = mkCapcomArcade {
      name = "FORGOTTEN WORLDS";
      depotId = 1556708;
      manifestId = 1338479023925864521;
      sha256 = "sha256-Hq6nhnvls6Br5YRE8Y90TFUX0MtZ3axuE4F5LxXVLD8=";
      shortname = "forgottnuaa";
      extraVariants = [ "lostwrld" ];
    };
    CAS_GHOULS_N_GHOSTS = mkCapcomArcade {
      name = "Ghouls 'n Ghosts";
      depotId = 1556709;
      manifestId = 4791960461403205195;
      sha256 = "sha256-ujftUjxgKF1dRi3QMvxoErDPhEJBRW952kydwZTbVkk=";
      shortname = "ghoulsu";
      extraVariants = [ "daimakai" ];
    };
    CAS_STRIDER = mkCapcomArcade {
      name = "STRIDER";
      depotId = 1556710;
      manifestId = 8852060672413987001;
      sha256 = "sha256-/3mPe0UPmqGgVHdJpvjlpOOy+Md5In21XffWxsX5aGY=";
      shortname = "striderua";
      extraVariants = [ "striderjr2" ];
    };
    CAS_DYNASTY_WARS = mkCapcomArcade {
      name = "DYNASTY WARS";
      depotId = 1556711;
      manifestId = 4583266592555943480;
      sha256 = "sha256-O1zYDgA7yW/6xfbIH45dv13tTQcNvB2HB629GvDhSlU=";
      shortname = "dynwar";
      extraVariants = [ "dynwarj" ];
    };
    CAS_FINAL_FIGHT = mkCapcomArcade {
      name = "FINAL FIGHT";
      depotId = 1556712;
      manifestId = 6599462489458630755;
      sha256 = "sha256-dqV41hh7iPOxUTSG5IlW+yoHwnThZ+u1ZVgPB5Vvu18=";
      shortname = "ffightu";
      extraVariants = [ "ffightj" ];
    };
    CAS_1941 = mkCapcomArcade {
      name = "1941 - Counter Attack -";
      depotId = 1556713;
      manifestId = 3043018487682955546;
      sha256 = "sha256-BrvZRP09zDYV0BoO1al9QglWWGvvjUTR9MugQEIrkRs=";
      shortname = "1941u";
      extraVariants = [ "1941j" ];
    };
    CAS_MERCS = mkCapcomArcade {
      name = "Senjo no Okami II";
      depotId = 1556714;
      manifestId = 8684632688241706607;
      sha256 = "sha256-+dyLdzDHV1cKK6dinreoQE10v7uMSHCkBWR1c167FFc=";
      shortname = "mercsj";
    };
    CAS_MEGA_TWINS = mkCapcomArcade {
      name = "MEGA TWINS";
      depotId = 1556715;
      manifestId = 2594671030254058043;
      sha256 = "sha256-AcvaHua3rixxlRTSRQAvnZy7XU49p/0h4h0V+pujkSo=";
      shortname = "mtwins";
      extraVariants = [ "chikij" ];
    };
    CAS_CARRIER_AIR_WING = mkCapcomArcade {
      name = "CARRIER AIR WING";
      depotId = 1556716;
      manifestId = 3262338654785901818;
      sha256 = "sha256-23qK6yuQcTqKLlFt/t0k96rfY9/k351YXDGonsQUIT4=";
      shortname = "cawingu";
      extraVariants = [ "cawingj" ];
    };
    CAS_STREET_FIGHTER_II = mkCapcomArcade {
      name = "STREET FIGHTER II - The World Warrior -";
      depotId = 1556717;
      manifestId = 6565168997152152747;
      sha256 = "sha256-wYYt8i1CvW8IIY7jPDDwAAPumomtEKS7FBgsayBg+mQ=";
      shortname = "sf2ul";
      extraVariants = [ "sf2jl" ];
    };
    CAS_CAPTAIN_COMMANDO = mkCapcomArcade {
      name = "CAPTAIN COMMANDO";
      depotId = 1556718;
      manifestId = 3828378947312518235;
      sha256 = "sha256-CO7c+3JRv97uMWogiujwFRNaxP5oHjlByS/rg2DKuMk=";
      shortname = "captcomm";
      extraVariants = [ "captcommj" ];
    };
    CAS_VARTH = mkCapcomArcade {
      name = "VARTH - Operation Thunderstorm -";
      depotId = 1556719;
      manifestId = 7633392002448169369;
      sha256 = "sha256-aPrteX3ODYFoYhsdApooPdNO4k9/kHWOeptcIsSTtU8=";
      shortname = "varth";
      extraVariants = [ "varthj" ];
    };
    CAS_WARRIORS_OF_FATE = mkCapcomArcade {
      name = "WARRIORS OF FATE";
      depotId = 1556720;
      manifestId = 939928116172609116;
      sha256 = "sha256-UaHbgywPXTPTw0lsktx3v+RFThqa5f3S5SmgA6a9Kuw=";
      shortname = "wofu";
      extraVariants = [ "wofj" ];
    };
    CAS_STREET_FIGHTER_II_HYPER_FIGHTING = mkCapcomArcade {
      name = "STREET FIGHTER II' - Hyper Fighting -";
      depotId = 1556721;
      manifestId = 8853416909907985637;
      sha256 = "sha256-O7tR84FtygSKaOc1eZFDenKhu9F8+yuc6BIm5busn+A=";
      shortname = "sf2hfu";
      extraVariants = [ "sf2hfj" ];
    };
    CAS_POWERED_GEAR = mkCapcomArcade {
      name = "Powered Gear - Strategic Variant Armor Equipment -";
      depotId = 1556723;
      manifestId = 3507050944236305691;
      sha256 = "sha256-ItUjY5gtNNAtSFC7NR3b4LNXP+WAP7DFdFhGm12QzoI=";
      shortname = "pgear";
    };
    # Depots 1556730, 1560440 also under base app, ownership unconfirmed -- left out.

    # Owned, but these 7 titles' PAK entries live under "decryptionrom" and
    # need an extra conversion step beyond plain REE.Rom.Cryptor. Not found yet:
    #   CYBERBOTS - FULLMETAL MADNESS - (appId 1556724, depotId 1556724,
    #     manifestId 2973553248234592332, shortname cybots)
    #   19XX - The War Against Destiny - (appId 1556725, depotId 1556725,
    #     manifestId 9114491010637683972, shortname 19xx)
    #   Battle Circuit (appId 1556726, depotId 1556726,
    #     manifestId 7256561282705776837, shortname batcir)
    #   Giga Wing (appId 1556727, depotId 1556727,
    #     manifestId 88396441350106139, shortname gigawing)
    #   1944 - The Loop Master - (appId 1556728, depotId 1556728,
    #     manifestId 8656237320360188678, shortname 1944)
    #   Progear (appId 1556729, depotId 1556729,
    #     manifestId 9110940077951262143, shortname progear)
    #   Super Street Fighter II Turbo (appId 1556722, depotId 1556722,
    #     manifestId 8868733674607803535, shortname ssf2t)

    # Capcom Arcade 2nd Stadium -- base app 1755910 IS owned, and 31 of its 50
    # listed DLC titles are owned (verified via `capcom-arcade-scan`'s
    # steamcmd licenses_for_app check, not the store API's GetOwnedGames,
    # which can't see DLC ownership at all).
    CAS2_SAVAGE_BEES = mkCapcomArcade2 {
      name = "Savage Bees";
      depotId = 1842960;
      manifestId = 7965598959320627290;
      shortname = "savgbees";
      extraVariants = [ "exedexes" ];
      sha256 = "sha256-0LgUlbN4ytPhzFNo1P1paLJb0KH7C9YzmC/0Dkf/2QE=";
    };
    CAS2_SPEED_RUMBLER = mkCapcomArcade2 {
      name = "The Speed Rumbler";
      depotId = 1842961;
      manifestId = 7826576594335602178;
      shortname = "srumbler2";
      extraVariants = [ "rushcrsh" ];
      sha256 = "sha256-qOSS670wUFX3bxNY83+TUwbGzkSqtlAMbRfziLTopr8=";
    };
    CAS2_HYPER_DYNE_SIDE_ARMS = mkCapcomArcade2 {
      name = "Hyper Dyne Side Arms";
      depotId = 1842962;
      manifestId = 938565537066798647;
      shortname = "sidearms";
      extraVariants = [ "sidearmsj" ];
      sha256 = "sha256-/uwodhJaCoEN/DxI7cyBV9m+veRWwWL5iMNJPY3yA0I=";
    };
    CAS2_BLACK_TIGER = mkCapcomArcade2 {
      name = "Black Tiger";
      depotId = 1842963;
      manifestId = 5047305831831734756;
      shortname = "blktiger";
      extraVariants = [ "blkdrgon" ];
      sha256 = "sha256-046oxGDsGdx6Rrj7XT4GZipFFZ7/z7s53T9mx0UKyxA=";
    };
    CAS2_STREET_FIGHTER = mkCapcomArcade2 {
      name = "Street Fighter";
      depotId = 1842964;
      manifestId = 7113733343069705850;
      shortname = "sfua";
      extraVariants = [ "sfj" ];
      sha256 = "sha256-nG60uUrxYPSKG51GazX9DSMR0dJQXA1+Dk0KKwXqL38=";
    };
    CAS2_TIGER_ROAD = mkCapcomArcade2 {
      name = "Tiger Road";
      depotId = 1842965;
      manifestId = 4083947508448188877;
      shortname = "tigeroad";
      extraVariants = [ "toramich2" ];
      sha256 = "sha256-4JmZq9OPO/xOinZP84lEDPHGJUq56BgdrnnUX+NSUo4=";
    };
    CAS2_THREE_WONDERS = mkCapcomArcade2 {
      name = "Three Wonders";
      depotId = 1842966;
      manifestId = 5896673033098389585;
      shortname = "3wondersu";
      extraVariants = [ "wonder3" ];
      sha256 = "sha256-M18c0mJ9c3m1S0PzziCQFHE9/JvPTh03cePQzf9WGqw=";
    };
    CAS2_KING_OF_DRAGONS = mkCapcomArcade2 {
      name = "A.K.A The King of Dragons";
      depotId = 1842967;
      manifestId = 4888131231458650022;
      shortname = "kodu";
      extraVariants = [ "kodjr3" ];
      sha256 = "sha256-D5cXpIKc29nUw82Sl48fnzOT7T28xf34o8nZ1xgh788=";
    };
    CAS2_SLAM_MASTERS = mkCapcomArcade2 {
      name = "Saturday Night Slam Masters";
      depotId = 1842968;
      manifestId = 1628235808209934720;
      shortname = "slammastur1";
      extraVariants = [ "mbomberjr1" ];
      sha256 = "sha256-KWN1IkEysztoy9vaFtFoWtS4uPsZCbcELGgSs+wslcM=";
    };
    CAS2_ECO_FIGHTERS = mkCapcomArcade2 {
      name = "Eco Fighters";
      depotId = 1842969;
      manifestId = 5392066310871616954;
      shortname = "ecofghtru";
      extraVariants = [ "uecology" ];
      sha256 = "sha256-AgW8anQJieD7v0MMesnqVki861wpDcJDzqiJfhd7ENE=";
    };
    CAS2_PNICKIES = mkCapcomArcade2 {
      name = "Pnickies";
      depotId = 1842970;
      manifestId = 3362396637407957435;
      shortname = "pnickj";
      sha256 = "sha256-oA2hEirMltbjja5LP5123QvmVwe1XW/IiWTITN9JdeI=";
    };
    CAS2_DARKSTALKERS = mkCapcomArcade2 {
      name = "Darkstalkers: The Night Warriors";
      depotId = 1842971;
      manifestId = 2608157869711750506;
      shortname = "dstlku";
      extraVariants = [ "vampj_940818" ];
      sha256 = "sha256-KGeRib9LW/1h+FvZspu35a94S5iSP3wTQ/vVi3AvdFU=";
    };
    CAS2_STREET_FIGHTER_ALPHA = mkCapcomArcade2 {
      name = "Street Fighter Alpha: Warriors' Dreams";
      depotId = 1842972;
      manifestId = 1372844834572053952;
      shortname = "sfau_950727";
      extraVariants = [ "sfzj" ];
      sha256 = "sha256-f7cnKa3uk5uBJZUZ1Moq7SdhNhFhOgsuMaR5BXtPob0=";
    };
    CAS2_MEGA_MAN_POWER_BATTLE = mkCapcomArcade2 {
      name = "Mega Man: The Power Battle";
      depotId = 1842973;
      manifestId = 336887344897685996;
      shortname = "megaman";
      extraVariants = [ "megamanj" ];
      sha256 = "sha256-XsM2+u4X+tGM+j97rYtpO4sfD6AqhBS3PJBCEfjwkqA=";
    };
    CAS2_STREET_FIGHTER_ALPHA_2 = mkCapcomArcade2 {
      name = "Street Fighter Alpha 2";
      depotId = 1842974;
      manifestId = 5026210803311757706;
      shortname = "sfa2u";
      extraVariants = [ "sfz2j" ];
      sha256 = "sha256-+K2u/HcbfuO6mbyODJUjSlSa65fihpfRErL8s+bMLA4=";
    };
    CAS2_HISSATSU_BURAIKEN = mkCapcomArcade2 {
      name = "Hissatsu Buraiken";
      depotId = 1842975;
      manifestId = 6279003862699888025;
      shortname = "buraiken";
      sha256 = "sha256-RZS3ylIL/l8M4jEkxj4Z+GgbKwuaFrC/5w6Gl32i3u8=";
    };
    CAS2_1943_KAI = mkCapcomArcade2 {
      name = "1943 Kai - Midway Kaisen -";
      depotId = 1842976;
      manifestId = 5008732065646381718;
      shortname = "1943kai";
      sha256 = "sha256-IvlsOf0OPu2nvFL53XEqU3bsbVS3J51Ao0veX7XP7w0=";
    };
    CAS2_LAST_DUEL = mkCapcomArcade2 {
      name = "Last Duel";
      depotId = 1842977;
      manifestId = 843353557613513062;
      shortname = "lastduel";
      extraVariants = [ "lastduelj" ];
      sha256 = "sha256-ZSm4/m2CbRFzKUDaUVUJpl7mM+vXAzDcW8gvCu1X5G4=";
    };
    CAS2_LED_STORM = mkCapcomArcade2 {
      name = "Rally 2011 LED Storm";
      depotId = 1842978;
      manifestId = 4059528741531468535;
      shortname = "leds2011u";
      sha256 = "sha256-/3WTtxPvcDki9pp9OmrnMAaubgRnlsE1IJvByoHkTi0=";
    };
    CAS2_MAGIC_SWORD = mkCapcomArcade2 {
      name = "A.K.A Magic Sword";
      depotId = 1842979;
      manifestId = 5437653424291948405;
      shortname = "mswordu";
      extraVariants = [ "mswordj" ];
      sha256 = "sha256-Arl6lkgUXXk20wgn46UYUwvPUu5vIusK5wUj3J90RXc=";
    };
    CAS2_BLOCK_BLOCK = mkCapcomArcade2 {
      name = "A.K.A Block Block";
      depotId = 1842980;
      manifestId = 3617612435567830562;
      shortname = "blockr2";
      extraVariants = [ "blockj" ];
      sha256 = "sha256-S6P4jbF+N9JYTuI+eQQAAGZWc96tDit/dzC6ykjG8qo=";
    };
    CAS2_KNIGHTS_OF_THE_ROUND = mkCapcomArcade2 {
      name = "A.K.A Knights of the Round";
      depotId = 1842981;
      manifestId = 621514193746640518;
      shortname = "knightsu";
      extraVariants = [ "knightsj" ];
      sha256 = "sha256-T5+9p2wsVXrWDOQyEjw0zynMEkGwm4PJolsiwh4Ux98=";
    };
    CAS2_NIGHT_WARRIORS = mkCapcomArcade2 {
      name = "Night Warriors: Darkstalkers' Revenge";
      depotId = 1842982;
      manifestId = 615881480605010086;
      shortname = "nwarre_950420";
      extraVariants = [ "vhuntj_950420" ];
      sha256 = "sha256-7UNXxH4T6+8wnPtO3huxEdgYLXbaOlY1VC+wDqUc5G8=";
    };
    CAS2_SUPER_PUZZLE_FIGHTER_II_TURBO = mkCapcomArcade2 {
      name = "Super Puzzle Fighter II Turbo";
      depotId = 1842983;
      manifestId = 1897934777002168467;
      shortname = "spf2tu";
      extraVariants = [ "spf2xj" ];
      sha256 = "sha256-BqyS8iQtNUM/N/obzHITvXY3jZgqaGUfFO6eboqDkrI=";
    };
    CAS2_MEGA_MAN_2_POWER_FIGHTERS = mkCapcomArcade2 {
      name = "Mega Man 2: The Power Fighters";
      depotId = 1842984;
      manifestId = 1023452342768997774;
      shortname = "megaman2";
      extraVariants = [ "rockman2j" ];
      sha256 = "sha256-9MzB2hvWzLrzoaAc+m873m8tyNOspGa06lUazBpOqQ4=";
    };
    CAS2_VAMPIRE_SAVIOR = mkCapcomArcade2 {
      name = "A.K.A Vampire Savior: The Lord of Vampire";
      depotId = 1842985;
      manifestId = 6829454349251196795;
      shortname = "vsavu";
      extraVariants = [ "vsavj" ];
      sha256 = "sha256-lUzpKNKlEs6zuWrCaYnw5EvGD8m9nvNYd8YHfJCpm2A=";
    };
    CAS2_CAPCOM_SPORTS_CLUB = mkCapcomArcade2 {
      name = "Capcom Sports Club";
      depotId = 1842986;
      manifestId = 9090483507631980910;
      shortname = "csclubu_971017";
      extraVariants = [ "csclubj" ];
      sha256 = "sha256-FW2Ofjidti6B4T8Ihd0DXefMbi7FqL523EW057hFaaA=";
    };
    CAS2_SUPER_GEM_FIGHTER = mkCapcomArcade2 {
      name = "Super Gem Fighter Mini Mix";
      depotId = 1842987;
      manifestId = 7239720317153599283;
      shortname = "sgemfu_970922";
      extraVariants = [ "pfghtj_970922" ];
      sha256 = "sha256-dYNtRPiYySqK0OSCqbA+OmsKD9DaFDye6xmDnP03e4g=";
    };
    CAS2_STREET_FIGHTER_ALPHA_3 = mkCapcomArcade2 {
      name = "Street Fighter Alpha 3";
      depotId = 1842988;
      manifestId = 8254947701711188485;
      shortname = "sfa3u";
      extraVariants = [ "sfz3j" ];
      sha256 = "sha256-erwPHYa6qny6R7eCrc/kkluN2VolhB5TRR9uByfd2/g=";
    };
    CAS2_HYPER_STREET_FIGHTER_II = mkCapcomArcade2 {
      name = "Hyper Street Fighter II: The Anniversary Edition";
      depotId = 1842989;
      manifestId = 8949776931283853998;
      shortname = "hsf2";
      extraVariants = [ "hsf2j" ];
      sha256 = "sha256-T0DtHC1LkhfD3VrbaZxVK6rRDfh5gKiHnOcLlZ27Jxw=";
    };
    # Gan Sumoku (appId/depotId 1879140, manifestId 4303558612031073606) is
    # owned, but has no MAME driver at all -- can't be packaged via mkArcade
    # until MAME adds one.
  };

  # 19 of 2nd Stadium's 50 listed DLC titles are confirmed not owned:
  #   1846200, 1846201, 1846202, 2019160, 2087680, 2087690, 2087700, 2087710,
  #   2087720, 2087730, 2087740, 2087750, 2087760, 2093740, 2087780, 2087790,
  #   2087800, 2087810, 2087820.
in
lib.mkIf config.games.emulation.enable {
  games.emulation.roms = lib.foldl' (acc: entry: acc // entry.roms) { } (
    lib.attrValues capcomEntries
  );
  programs.steam.games = lib.mapAttrs (
    _: entry:
    mkArcade {
      inherit (entry) name shortname;
      romset = config.games.emulation.roms.${entry.shortname};
    }
  ) capcomEntries;
}
