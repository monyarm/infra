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
  # pulls the title's .mameac.2 out of the .pak (CAS_STM_Release tag list),
  # REE.Rom.Cryptor decrypts that into a plain MAME-loadable zip. Both run
  # in one derivation, fed straight into mkArcade.
  mkCapcomArcade =
    {
      name,
      appId ? 1515950,
      depotId,
      manifestId,
      shortname,
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
      romset =
        pkgs.runCommand "${shortname}.zip"
          {
            nativeBuildInputs = [
              pkgs.ree-tools
            ];
          }
          ''
            REE.Unpacker CAS_STM_Release "$(find ${depot} -name '*.pak' -print -quit)" "$PWD/unpacked"
            REE.Rom.Cryptor "$(find "$PWD/unpacked" -name '*.mameac.2' -print -quit)" "$out"
          '';
    in
    mkArcade {
      inherit name shortname;
      inherit romset;
    };

  # deadnix: skip
  mkCapcomArcade2 = args: mkCapcomArcade (args // { appId = 1755910; });

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

in
lib.mkIf config.games.emulation.enable {
  programs.steam.games = {
    # Capcom Arcade Stadium -- base app 1515950 + all 31 DLC titles owned.
    CAS_1943_BATTLE_OF_MIDWAY = mkArcade {
      name = "Capcom Arcade Stadium: 1943 -The Battle of Midway-";
      romset = capcom1943Zip "1943u";
      shortname = "1943u";
    };
    CAS_1943_BATTLE_OF_MIDWAY_JC = mkArcade {
      name = "Capcom Arcade Stadium: 1943 -The Battle of Midway- (Japan Clone)";
      romset = capcom1943Zip "1943jc";
      shortname = "1943jc";
    };
    CAS_GHOSTS_N_GOBLINS = mkCapcomArcade {
      name = "Capcom Arcade Stadium: Ghosts 'n Goblins";
      depotId = 1556690;
      manifestId = 720985918200840956;
      sha256 = "sha256-XzBl+QGQPVV12ctyGzz4W1aMn3viOtnH9zBf0F2Lhhw=";
      shortname = "gng";
    };
    CAS_VULGUS = mkCapcomArcade {
      name = "Capcom Arcade Stadium: VULGUS";
      depotId = 1556700;
      manifestId = 5256365349174359542;
      sha256 = "sha256-ORFIR8OAGJJKLx2t9mXvEvDuwgMWi1igvmd73D5N55s=";
      shortname = "vulgus";
    };
    CAS_PIRATE_SHIP_HIGEMARU = mkCapcomArcade {
      name = "Capcom Arcade Stadium: PIRATE SHIP HIGEMARU";
      depotId = 1556701;
      manifestId = 2839819348004594506;
      sha256 = "sha256-53eSPA56xr9nHR7SfMUkbipsiPgsn21wcDhm/0DWOrc=";
      shortname = "higemaru";
    };
    CAS_1942 = mkCapcomArcade {
      name = "Capcom Arcade Stadium: 1942";
      depotId = 1556702;
      manifestId = 930775891296948257;
      sha256 = "sha256-u+3h6M84jHpqexD6J09XOijM3QSJ/msEZza55ogb6bs=";
      shortname = "1942";
    };
    CAS_COMMANDO = mkCapcomArcade {
      name = "Capcom Arcade Stadium: COMMANDO";
      depotId = 1556703;
      manifestId = 3068512296888649504;
      sha256 = "sha256-x2Z4Rxh3GXc38uJ5EVAOBbMcKA/5CtmQ+DbfOq1w/T0=";
      shortname = "commando";
    };
    CAS_SECTION_Z = mkCapcomArcade {
      name = "Capcom Arcade Stadium: SECTION Z";
      depotId = 1556704;
      manifestId = 4115256064438261885;
      sha256 = "sha256-+3HgyaIFY7X8yOenZWoeiN+ijxW3xin2R3aqDkJY9TM=";
      shortname = "sectionz";
    };
    CAS_TROJAN = mkCapcomArcade {
      name = "Capcom Arcade Stadium: Tatakai no Banka";
      depotId = 1556705;
      manifestId = 2012252709011603898;
      sha256 = "sha256-KmXOBBFZOk05TzmLtItEdn54YrOgCBaRkKRHifiYKmk=";
      shortname = "trojan";
    };
    CAS_LEGENDARY_WINGS = mkCapcomArcade {
      name = "Capcom Arcade Stadium: LEGENDARY WINGS";
      depotId = 1556706;
      manifestId = 1060722444987922461;
      sha256 = "sha256-JJUDUohvGyP38GUyMqiDLzf0Lx/cuisqJWl5otpcoP0=";
      shortname = "lwings";
    };
    CAS_BIONIC_COMMANDO = mkCapcomArcade {
      name = "Capcom Arcade Stadium: BIONIC COMMANDO";
      depotId = 1556707;
      manifestId = 3311060249623978404;
      sha256 = "sha256-Kp/+k9JTzvo5J70xP3qK6NSaVFqW1RtnAvQd979PilA=";
      shortname = "bionicc";
    };
    CAS_FORGOTTEN_WORLDS = mkCapcomArcade {
      name = "Capcom Arcade Stadium: FORGOTTEN WORLDS";
      depotId = 1556708;
      manifestId = 1338479023925864521;
      sha256 = "sha256-Hq6nhnvls6Br5YRE8Y90TFUX0MtZ3axuE4F5LxXVLD8=";
      shortname = "forgottn";
    };
    CAS_GHOULS_N_GHOSTS = mkCapcomArcade {
      name = "Capcom Arcade Stadium: Ghouls 'n Ghosts";
      depotId = 1556709;
      manifestId = 4791960461403205195;
      sha256 = "sha256-ujftUjxgKF1dRi3QMvxoErDPhEJBRW952kydwZTbVkk=";
      shortname = "ghouls";
    };
    CAS_STRIDER = mkCapcomArcade {
      name = "Capcom Arcade Stadium: STRIDER";
      depotId = 1556710;
      manifestId = 8852060672413987001;
      sha256 = "sha256-/3mPe0UPmqGgVHdJpvjlpOOy+Md5In21XffWxsX5aGY=";
      shortname = "strider";
    };
    CAS_DYNASTY_WARS = mkCapcomArcade {
      name = "Capcom Arcade Stadium: DYNASTY WARS";
      depotId = 1556711;
      manifestId = 4583266592555943480;
      sha256 = "sha256-O1zYDgA7yW/6xfbIH45dv13tTQcNvB2HB629GvDhSlU=";
      shortname = "dynwar";
    };
    CAS_FINAL_FIGHT = mkCapcomArcade {
      name = "Capcom Arcade Stadium: FINAL FIGHT";
      depotId = 1556712;
      manifestId = 6599462489458630755;
      sha256 = "sha256-dqV41hh7iPOxUTSG5IlW+yoHwnThZ+u1ZVgPB5Vvu18=";
      shortname = "ffight";
    };
    CAS_1941 = mkCapcomArcade {
      name = "Capcom Arcade Stadium: 1941 - Counter Attack -";
      depotId = 1556713;
      manifestId = 3043018487682955546;
      sha256 = "sha256-BrvZRP09zDYV0BoO1al9QglWWGvvjUTR9MugQEIrkRs=";
      shortname = "1941";
    };
    CAS_MERCS = mkCapcomArcade {
      name = "Capcom Arcade Stadium: Senjo no Okami II";
      depotId = 1556714;
      manifestId = 8684632688241706607;
      sha256 = "sha256-+dyLdzDHV1cKK6dinreoQE10v7uMSHCkBWR1c167FFc=";
      shortname = "mercs";
    };
    CAS_MEGA_TWINS = mkCapcomArcade {
      name = "Capcom Arcade Stadium: MEGA TWINS";
      depotId = 1556715;
      manifestId = 2594671030254058043;
      sha256 = "sha256-AcvaHua3rixxlRTSRQAvnZy7XU49p/0h4h0V+pujkSo=";
      shortname = "mtwins";
    };
    CAS_CARRIER_AIR_WING = mkCapcomArcade {
      name = "Capcom Arcade Stadium: CARRIER AIR WING";
      depotId = 1556716;
      manifestId = 3262338654785901818;
      sha256 = "sha256-23qK6yuQcTqKLlFt/t0k96rfY9/k351YXDGonsQUIT4=";
      shortname = "cawing";
    };
    CAS_STREET_FIGHTER_II = mkCapcomArcade {
      name = "Capcom Arcade Stadium: STREET FIGHTER II - The World Warrior -";
      depotId = 1556717;
      manifestId = 6565168997152152747;
      sha256 = "sha256-wYYt8i1CvW8IIY7jPDDwAAPumomtEKS7FBgsayBg+mQ=";
      shortname = "sf2";
    };
    CAS_CAPTAIN_COMMANDO = mkCapcomArcade {
      name = "Capcom Arcade Stadium: CAPTAIN COMMANDO";
      depotId = 1556718;
      manifestId = 3828378947312518235;
      sha256 = "sha256-CO7c+3JRv97uMWogiujwFRNaxP5oHjlByS/rg2DKuMk=";
      shortname = "captcomm";
    };
    CAS_VARTH = mkCapcomArcade {
      name = "Capcom Arcade Stadium: VARTH - Operation Thunderstorm -";
      depotId = 1556719;
      manifestId = 7633392002448169369;
      sha256 = "sha256-aPrteX3ODYFoYhsdApooPdNO4k9/kHWOeptcIsSTtU8=";
      shortname = "varth";
    };
    CAS_WARRIORS_OF_FATE = mkCapcomArcade {
      name = "Capcom Arcade Stadium: WARRIORS OF FATE";
      depotId = 1556720;
      manifestId = 939928116172609116;
      sha256 = "sha256-UaHbgywPXTPTw0lsktx3v+RFThqa5f3S5SmgA6a9Kuw=";
      shortname = "wof";
    };
    CAS_STREET_FIGHTER_II_HYPER_FIGHTING = mkCapcomArcade {
      name = "Capcom Arcade Stadium: STREET FIGHTER II' - Hyper Fighting -";
      depotId = 1556721;
      manifestId = 8853416909907985637;
      sha256 = "sha256-O7tR84FtygSKaOc1eZFDenKhu9F8+yuc6BIm5busn+A=";
      shortname = "sf2hf";
    };
    CAS_POWERED_GEAR = mkCapcomArcade {
      name = "Capcom Arcade Stadium: Powered Gear - Strategic Variant Armor Equipment -";
      depotId = 1556723;
      manifestId = 3507050944236305691;
      sha256 = "sha256-ItUjY5gtNNAtSFC7NR3b4LNXP+WAP7DFdFhGm12QzoI=";
      shortname = "pgear";
    };
    # Depots 1556730, 1560440 also under base app, ownership unconfirmed -- left out.
  };

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

  # Capcom Arcade 2nd Stadium -- base app 1755910 not owned, so none of its
  # titles are either:
  #   SONSON (free, base app 1755910), Savage Bees, The Speed Rumbler,
  #   Hyper Dyne Side Arms, Black Tiger, Street Fighter (1987), Tiger Road,
  #   Three Wonders, King of Dragons, Saturday Night Slam Masters,
  #   Eco Fighters, Pnickies, Darkstalkers, Street Fighter Alpha,
  #   Mega Man: The Power Battle, Street Fighter Alpha 2,
  #   Hissatsu Buraiken, 1943 Kai, Last Duel, Rally 2011 LED Storm,
  #   Magic Sword, Block Block, Knights of the Round, Night Warriors,
  #   Super Puzzle Fighter II Turbo, Mega Man 2: The Power Fighters,
  #   Vampire Savior, Capcom Sports Club, Super Gem Fighter Mini Mix,
  #   Street Fighter Alpha 3, Hyper Street Fighter II, Gan Sumoku.
}
