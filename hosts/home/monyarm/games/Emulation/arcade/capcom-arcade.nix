{
  lib,
  pkgs,
  fetchSteam,
  mkArcade,
  patchZip,
  config,
  ...
}:
# Per-title mameSystem/emulator/romPatch overrides here are cross-checked
# against https://github.com/farmerbb/RED-Project/issues/192 (community
# survey of which CAS/CAS2 extractions load as-is vs need a rename/dummy
# file/different core). That thread is known stale in places -- where a
# real smoke-check build disagrees with it, the build wins.
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
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
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
      # CAS2's own internal PAK filenames (shortname above) sometimes carry a
      # region/date suffix MAME's current driver name has since dropped or
      # renamed (e.g. "sfau_950727" -> "sfau") -- mameSystem is the string
      # actually handed to mame (rompath zip name + -bench arg), defaulting
      # to shortname for every title where the two still coincide.
      mameSystem ? shortname,
      # "mame" (default): standalone pkgs.mame. Any other string is a
      # retroarchCores key, for titles whose dump only matches an older
      # MAME driver revision (see arcade/default.nix's mkArcade).
      emulator ? "mame",
      extraVariants ? [ ],
      sha256 ? lib.fakeHash,
      images ? null,
      # Applied to the launched (shortname) romset only, for titles whose
      # depot extraction is otherwise correct but needs member renames
      # and/or a dummy stub added to match the real MAME set (see
      # lib/rom/patchZip.nix). null: no patch.
      romPatch ? null,
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
      inherit
        name
        shortname
        mameSystem
        emulator
        ;
      roms = lib.listToAttrs (
        map (
          variant:
          lib.nameValuePair variant (
            let
              raw = capcomZip tag depot variant;
            in
            if variant == shortname && romPatch != null then patchZip romPatch raw else raw
          )
        ) ([ shortname ] ++ extraVariants)
      );
    }
    // (if images != null then { inherit images; } else { });

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
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
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
      emulator = "mame2010";
      roms = {
        "1943u" = capcom1943Zip "1943u";
        "1943jc" = capcom1943Zip "1943jc";
      };
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/19e4eb080cdbf8da0c1f52351e3bfc61.png";
          sha256 = "sha256-X4MbLlx2MQ6IjLAmObLl+l+YU/ZgbhfI9a2ZGgitz74=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/babd2e7221c7a8198c64691480313e47.png";
          sha256 = "sha256-+/3Tily6+em/bD2gWxwVQJhKl9bAW7zrQvNrbFMHYK4=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/bd1c639bbaf42b94057038ab0e1ad2b0.png";
          sha256 = "sha256-Oseamy8SQmI3LFJeyKzLXS+m36dsJbjC/5/RdHaUovs=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/03555a28a61d7e741514d83b5e09597c.png";
          sha256 = "sha256-yY3eANno6+F6JjbgQ3zp7eTC4hg0kf2mmz/j2qrE3kU=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/bdc9f6ada518791b8b76e8a07021e145.png";
          sha256 = "sha256-5XPlUCfWCKsvMKT8w6Qh7pStbGIuWQyByAHMdg4IYzU=";
        };
      };
    };
    CAS_GHOSTS_N_GOBLINS = mkCapcomArcade {
      name = "Ghosts 'n Goblins";
      depotId = 1556690;
      manifestId = 720985918200840956;
      sha256 = "sha256-XzBl+QGQPVV12ctyGzz4W1aMn3viOtnH9zBf0F2Lhhw=";
      shortname = "gng";
      emulator = "mame2010";
      extraVariants = [ "makaimurg" ];
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/50ae0ce8c27842532dcd83c3678302bc.png";
          sha256 = "sha256-ZgOF8qy8ImMgsYmu/PSGm16J3ru6Ipsu66KJyM382bI=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/bece005119a18546b9a4be3e6e299ec4.png";
          sha256 = "sha256-bbF/EfP0imac4tIf3RqjR/g25JqhaXPlgF1c4Zb/i2U=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/f5b9430e2561a2e2233863b3a844eb66.jpg";
          sha256 = "sha256-8dcKBEDH5nrJRWQUykdyDkQIF3RhIBuQ/qKtxu5f5gA=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/7be1e38aa45f59b64b08e621783dff4a.png";
          sha256 = "sha256-CuxvfgNr2rjaEwR04MOl/ldeKbZGUbHI26NMbTjbwM0=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/747cd247d7e5dca7fa453e0dca5204b7.png";
          sha256 = "sha256-AN+JmhIu1KAAlvuebHgPQJX3siwKZirvhgVo+rJqbFc=";
        };
      };
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
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/041d7fccff9c39b0681ffcd0595349b8.png";
          sha256 = "sha256-RTF9gviebfE1Eg7MUyd1v2vzyJxu5rWRtEqiSDJ2YDE=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/f21aa9a67ef524410f718cff368a6ff2.png";
          sha256 = "sha256-RJ7IO5X9Y11jrbeGThE0HEIx+HaOa940q4QRDhxzP9w=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/3e8574f965c16188849878fc2be32f32.png";
          sha256 = "sha256-+49ZVI3HPNMOCJZ3hIrA68pmyvLMajY7nbZGSmZ2sgY=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/19209a8a5875fd49630803a69dc7bbcb.png";
          sha256 = "sha256-EYudPdvHC+efAD4/ERTExozZ9sRmHnyqkb3xLdZ34MY=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/f5b49df0ec42774c1c13ef6f93d7865c.png";
          sha256 = "sha256-ktTYsiE3eMUF6lFq3GCd2NJQARo+xq97QTMv4pby3lM=";
        };
      };
    };
    CAS_COMMANDO = mkCapcomArcade {
      name = "COMMANDO";
      depotId = 1556703;
      manifestId = 3068512296888649504;
      sha256 = "sha256-x2Z4Rxh3GXc38uJ5EVAOBbMcKA/5CtmQ+DbfOq1w/T0=";
      shortname = "commandou";
      extraVariants = [ "commandoj" ];
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/3312a1d297ed261ecb3cc34928347c43.png";
          sha256 = "sha256-dNPfEvSo2jjigWjpU8T1mBS0akMxacQ9JlSfjZFU8fw=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/7caf725460a122ea49d40b9e770f451b.png";
          sha256 = "sha256-XFNULnhjocFywb+Fs4jnyIQSc7TrbvoZNH/RgkJ5TuI=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/cee38bdf685ff9779ffd7dfa84830914.png";
          sha256 = "sha256-sOmPhmOI7kFYjPqMmYRvCY/309vvb2L3FCfYxFEHXtg=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/81e68999106d6798eca552cbb9337751.png";
          sha256 = "sha256-vMdv8PeazDIho87z/VQXTTwKjn4GK6nLipiLNKANZow=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/8722c8f495dcee23f39d5519735e1f71.png";
          sha256 = "sha256-Bdvwdpac4PU7/c1QttXDhrYbkRDDUr4anqtjPJBvWOM=";
        };
      };
    };
    CAS_SECTION_Z = mkCapcomArcade {
      name = "SECTION Z";
      depotId = 1556704;
      manifestId = 4115256064438261885;
      sha256 = "sha256-+3HgyaIFY7X8yOenZWoeiN+ijxW3xin2R3aqDkJY9TM=";
      shortname = "sectionza";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/1c09320d1ec78f4fe21d58bf936ee017.png";
          sha256 = "sha256-FEqojt9Vpa7faGdAyGyLFofF16EDMwl9cBFCnRU56sg=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/1c4cab9abb79db850eb3d8465593e365.png";
          sha256 = "sha256-neROm/s6VhSgqq9WRwfi96vPde0MRin0zk9r8lqwWBI=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/f5abe18064d57c2e5a768504a2041036.png";
          sha256 = "sha256-UdBwlEbrt/QRJUPFKxXFeKDkbK1QtcL+szOqhwd4Eog=";
        };
      };
    };
    CAS_TROJAN = mkCapcomArcade {
      name = "Tatakai no Banka";
      depotId = 1556705;
      manifestId = 2012252709011603898;
      sha256 = "sha256-KmXOBBFZOk05TzmLtItEdn54YrOgCBaRkKRHifiYKmk=";
      shortname = "trojanj";
      romPatch = {
        rename = {
          "tb03.8k" = "tb_03.8k";
          "tb24.13n" = "tb_24.13n";
          "tb08.4a" = "tb_08.4a";
          "tb16.3l" = "tb_16.3l";
          "tb07.3a" = "tb_07.3a";
          "mb7114e.1e" = "tbb-1.1e";
          "tb11.3b" = "tb_11.3b";
          "tb15.2l" = "tb_15.2l";
          "tb19.2n" = "tb_19.2n";
          "tb13.6b" = "tb_13.6b";
          "tb10.8a" = "tb_10.8a";
          "tb22.7n" = "tb_22.7n";
          "tb18.7l" = "tb_18.7l";
          "tb14.8b" = "tb_14.8b";
          "tb01.6d" = "tb_01.6d";
          "troj-06.13n" = "tb_06.13n";
          "tb09.6a" = "tb_09.6a";
          "tb17.5l" = "tb_17.5l";
          "tb21.5n" = "tb_21.5n";
          "tb23.9n" = "tb_23.9n";
          "tb20.3n" = "tb_20.3n";
          "troj-04.10n" = "tb_04.10n";
          "tb12.4b" = "tb_12.4b";
          "tbp24s10.7j" = "tbb-2.7j";
          "tb05.12n" = "tb_05.12n";
          "tb02.15h" = "tb_02.15h";
          "tb25.15n" = "tb_25.15n";
        };
      };
    };
    CAS_LEGENDARY_WINGS = mkCapcomArcade {
      name = "LEGENDARY WINGS";
      depotId = 1556706;
      manifestId = 1060722444987922461;
      sha256 = "sha256-JJUDUohvGyP38GUyMqiDLzf0Lx/cuisqJWl5otpcoP0=";
      shortname = "lwings";
      extraVariants = [ "lwingsja" ];
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/6e0cbb72e91cfa0e026b6a066db1b2e5.ico";
          sha256 = "sha256-Rglqzxf1P+o+60G/VFcxwDZZo39krjR6nW4uJ7aFpCc=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/8e1b45b41454a54788169495dbb74ecc.png";
          sha256 = "sha256-n/y2VJDWbuzd+J4K1tfmR44kdIkExpudSe1WJHzL/hw=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/22f4d9ee6c26ab5a413445a6b327e1dd.png";
          sha256 = "sha256-iZpekNW/oJuCvBPzmbR7AJ6HEFCUCbPNVWF+v69PbQw=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/dfc579b1ad66a45ca3fe79fc61278063.png";
          sha256 = "sha256-jXDh4uFh/NjVJwlpPXgz0AYZVh+jAoM1xvG937nP+pQ=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/8d6615523a6c8e16f9d0ef45d235c73a.png";
          sha256 = "sha256-wyLzG1b0CT6poDYQDs9BTSjOlxHCPkM8fn67ibOAAG0=";
        };
      };
    };
    CAS_BIONIC_COMMANDO = mkCapcomArcade {
      name = "BIONIC COMMANDO";
      depotId = 1556707;
      manifestId = 3311060249623978404;
      sha256 = "sha256-Kp/+k9JTzvo5J70xP3qK6NSaVFqW1RtnAvQd979PilA=";
      shortname = "bionicc2";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/e11ee596539d22171527ba1c833d59c0.png";
          sha256 = "sha256-7jQOTi+Ygz/v6q6uPCMUMsan0yn0bxlRo1MlSftyvmQ=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/f0d65c0d56a5c7ff1c5bd9f9909f1c54.png";
          sha256 = "sha256-7DZieVjwrz2SC8BpxDBe+YFzpNwZqNWBiHPOSCk0UpU=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/147daaa4d649f65f12a78c8048338128.jpg";
          sha256 = "sha256-Ngbl437U/pji6asI17eI7Kq/PHIO9aT3enc0iSSfzYk=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/621d187a8e1a345cc07422a61c669654.png";
          sha256 = "sha256-onegFCp/3a2RXwcFBThKuzv7ULW4jUMzP51zKLOXfm4=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/aa1987b9d1722e6cc9565bb4ef069724.jpg";
          sha256 = "sha256-11+nT7m8/rCzjHeHYQtrJLB/HAqpcJeQV02Lmu0W0/U=";
        };
      };
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
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/3cd13cea091d84211559098a33a38ce9.ico";
          sha256 = "sha256-33mmcI9Okby6ZVDhqEWFCEgDAZuNtHC8Mgl7dIh3U0k=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/26317dce2f9d6ed627386f34400be2ec.png";
          sha256 = "sha256-/ADOK3J4foEJ6h2jnZvpGns6pZLaRaPNCdLN/KLf5kI=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/0e461b91f8d6b26ba74565b9e8956545.png";
          sha256 = "sha256-6NtBC42OBnbiuRSEW849BHHjyS73SVu3W6lHi5R3S4I=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/b6f05a7baab2fe0eea07e59bd5b0b317.png";
          sha256 = "sha256-+/QdADw4VHAvFsMdtQBzLL9B2wpSSTSI86YlvRWluoc=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/27a1e0e31bf1a18797d26f7796f1ae4e.png";
          sha256 = "sha256-avkI0tbJJ9zYQlxtRZSQX1nYH4jJumzRKvyoAp2I55U=";
        };
      };
    };
    CAS_STRIDER = mkCapcomArcade {
      name = "STRIDER";
      depotId = 1556710;
      manifestId = 8852060672413987001;
      sha256 = "sha256-/3mPe0UPmqGgVHdJpvjlpOOy+Md5In21XffWxsX5aGY=";
      shortname = "striderua";
      extraVariants = [ "striderjr2" ];
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/a8a5204dd969d34ddbd26915537bd937.png";
          sha256 = "sha256-o7SCqRYI7GUE+nWzY14jZOjtsuUBt224HfArp8L2Tlg=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/55f16320eb523947f12d2e94d9630c6e.png";
          sha256 = "sha256-8mVygC68HO4GCg70wYlboiPSDfP5KlkXf45qAO/1U8I=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/77d40045c24c613463c3eef0732475f3.png";
          sha256 = "sha256-5VpwxhV4+oEsuQPfb/0ERKnocyEM9fGuvTu6GsqF0rA=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/f58f29ba07d6fd4206404184edc66f01.jpg";
          sha256 = "sha256-F1g/KYeBD0nhk9Do8APsQ68JsBVnDcSDbRo+Fq6Vs74=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/74374f84082a46a108e58968cc46cb41.png";
          sha256 = "sha256-cb0qeEt1o4Re0/GiwfnLULeNtHow1hAhKwdOERn58mQ=";
        };
      };
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
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/7a08de37d82277a516282b53d3c29b57.png";
          sha256 = "sha256-PJ9hkbtkeAE++OGhAQ7vqhCBb9ptxFxGxdlnrn6UxSY=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/eaef73772fcb49f558324ad51e5c4d2f.png";
          sha256 = "sha256-0TxFgduVpMAb+rw7LJ4AeqL5NeYufRzYL6/ryHi54HY=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/a8166da05c5a094f7dc03724b41886e5.png";
          sha256 = "sha256-60kryaKBqsdaLxhr710uA6cQzfHF9u0QZyw0eD2bNrI=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/040ca38cefb1d9226d79c05dd25469cb.png";
          sha256 = "sha256-vYNOnC5TZzimLT3hP02dKzCsIAJEY1bhuFfb8DuTMjM=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/61cd29e0ffa769ecebb1acfc6748b4fe.jpg";
          sha256 = "sha256-OhSzRMuxUxXHWy5Uwgb7XUG8FIR4e28KFwnZA/Izj4c=";
        };
      };
    };
    CAS_1941 = mkCapcomArcade {
      name = "1941 - Counter Attack -";
      depotId = 1556713;
      manifestId = 3043018487682955546;
      sha256 = "sha256-BrvZRP09zDYV0BoO1al9QglWWGvvjUTR9MugQEIrkRs=";
      shortname = "1941u";
      extraVariants = [ "1941j" ];
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/a598e7d200bf02558d5534839884b7a3.ico";
          sha256 = "sha256-pXHUWuKqV7TGgjA/9zDvpVIOnx3f+azMQC58wHkVHA0=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/85eab9c5f317ee19e3e27263a91ae4d4.png";
          sha256 = "sha256-whpTJH5+QQpzzrTvw0yxTd8PDCODOeajRgNQ5TALRsk=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/30ba105754346aaf47509089d2287f2a.png";
          sha256 = "sha256-4ErkkpI2emDdmG3m7Jp+/GqHGVB79HJ1fdRDst/vzrM=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/18d10dc6e666eab6de9215ae5b3d54df.png";
          sha256 = "sha256-rHv80ssTyOBm6ej7X9yHbELD0PM94rnFkeqNSKcRRH0=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/6db291ac9963003618ca6aa15063c4d6.png";
          sha256 = "sha256-YdOVyX4Ju9qqt3TiDuSdfSo7QWq3dsFXRhRpPjgm2bs=";
        };
      };
    };
    CAS_MERCS = mkCapcomArcade {
      name = "Senjo no Okami II";
      depotId = 1556714;
      manifestId = 8684632688241706607;
      sha256 = "sha256-+dyLdzDHV1cKK6dinreoQE10v7uMSHCkBWR1c167FFc=";
      shortname = "mercsj";
      romPatch = {
        add."c628" = 0;
      };
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
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/8b542d5e68088d7345fc31d92c8013db.ico";
          sha256 = "sha256-zsyngE9n4tL2x7i5D7LMLwHCwnangm036yfF6wmBtvo=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/5db2ed0b85a235ec531f042e939b2f38.png";
          sha256 = "sha256-ediOzjd9eoGl46tssPBqHENCq2Ld44LtWog7ldpega4=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/fe9cb798feccaff35f7147a5181c676d.png";
          sha256 = "sha256-c5SHvCbayVL1fTVoKT5Zqq+1S9r9av6jpidYjWS7hGg=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/e74935f9648226657ed4bb8168cca50e.png";
          sha256 = "sha256-fwHb+G6tESvISIv5H1Dj/MQ6kXvQcJBFW3PBiWMF5Uw=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/56a11624261bb5b56cd6d255d81cb778.png";
          sha256 = "sha256-zDLmaOM7KN2LE3LbqiEDEpfVei7Uu4raHXPRm/KN5GY=";
        };
      };
    };
    CAS_STREET_FIGHTER_II = mkCapcomArcade {
      name = "STREET FIGHTER II - The World Warrior -";
      depotId = 1556717;
      manifestId = 6565168997152152747;
      sha256 = "sha256-wYYt8i1CvW8IIY7jPDDwAAPumomtEKS7FBgsayBg+mQ=";
      shortname = "sf2ul";
      # Non-standard MAME set name; real driver is sf2um with 23 renamed
      # chips (per RED-Project#192).
      mameSystem = "sf2um";
      romPatch = {
        rename = {
          "sf2_16(m4).bin" = "sf2-4m.5c";
          "sf2u_09.bin" = "sf2_09.12a";
          "sf2_24(m9).bin" = "sf2-9m.3d";
          "sf2j_36b.bin" = "sf-2u_36m.10f";
          "sf2_06(m5).bin" = "sf2-5m.4a";
          "sf2_35m.bin" = "sf-2u_35m.9f";
          "sf2_08(m7).bin" = "sf2-7m.6a";
          "sf2_14(m2).bin" = "sf2-2m.3c";
          "sf2_30m.bin" = "sf-2u_30m.11e";
          "sf2_15(m6).bin" = "sf2-6m.4c";
          "sf2_07(m3).bin" = "sf2-3m.5a";
          "sf2j_29b.bin" = "sf-2u_29m.10e";
          "sf2_25(m13).bin" = "sf2-13m.4d";
          "sf2_17(m8).bin" = "sf2-8m.6c";
          "sf2_31m.bin" = "sf-2u_31m.12e";
          "sf2_27(m15).bin" = "sf2-15m.6d";
          "sf2u_18.bin" = "sf2_18.11c";
          "sf2u_19.bin" = "sf2_19.12c";
          "sf2_05(m1).bin" = "sf2-1m.3a";
          "sf2u_37m.bin" = "sf-2u_37m.11f";
          "sf2_28m.bin" = "sf-2u_28m.9e";
          "sf2_38m.bin" = "sf-2u_38m.12f";
          "sf2_26(m11).bin" = "sf2-11m.5d";
        };
      };
      extraVariants = [ "sf2jl" ];
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/d1e77f1dd62e66f98fd01387cb99037b.png";
          sha256 = "sha256-acndG+5zM+yqxi5EcJ1ppHqYaiff1wkpmDOayZIFCqk=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/e4656174f0a5436efd535a9a9d050e09.png";
          sha256 = "sha256-MEyJgNP2F9bt7kn0PcODS1RDaFop3Wj9DjCVy3pOg6g=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/d0310993ced219c9d5f81c0e930d0b5c.png";
          sha256 = "sha256-Q3GLMkIO5WfrEHiWRULRfF0ezZ1N+vCSRki8QvIciI8=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/001cc24087bbb2b9e50059240017bad3.png";
          sha256 = "sha256-+k3jexguPFAsxgSqDrms+tlKA6hjtbBGwDlMF5F9vsA=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/ad4064ed89c079795893aed6055c1a90.png";
          sha256 = "sha256-Tcrni40wFmE/4megbTovT0unGu13cMAf/R9Wo1tcig0=";
        };
      };
    };
    CAS_CAPTAIN_COMMANDO = mkCapcomArcade {
      name = "CAPTAIN COMMANDO";
      depotId = 1556718;
      manifestId = 3828378947312518235;
      sha256 = "sha256-CO7c+3JRv97uMWogiujwFRNaxP5oHjlByS/rg2DKuMk=";
      shortname = "captcomm";
      extraVariants = [ "captcommj" ];
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/7e83a4be61c9f15cb1e5686ea2c1edaa.ico";
          sha256 = "sha256-jjJThbd5cT8fmMN9EDBbWDhXYYXPQjI7UuXcJPjEGnE=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/7f18639c3bf9bffe4a6b1888e810b6b4.png";
          sha256 = "sha256-aORIWf0/C+138co2AxFn7oVvaUsX6361PnL+e2WHRng=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/794f31502eb2dbd9bedd49947e85e895.png";
          sha256 = "sha256-w7dWC5G45049/ZHJvnEgFFUUSiPB6cHXrKzOcmZoqzg=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/1bd297a32a156c82a79e326a96ad77f4.png";
          sha256 = "sha256-FojDNwynxg3AjWc/I3xM10F7HNDvg8M0wTV3dQj3G5o=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/02c7b9e35b5abe16eff4721993beb0fd.png";
          sha256 = "sha256-9UEq5N/H7ZIyQtGpITKBSCFy4nhrP5Ug3eOEbKmeRYQ=";
        };
      };
    };
    CAS_VARTH = mkCapcomArcade {
      name = "VARTH - Operation Thunderstorm -";
      depotId = 1556719;
      manifestId = 7633392002448169369;
      sha256 = "sha256-aPrteX3ODYFoYhsdApooPdNO4k9/kHWOeptcIsSTtU8=";
      shortname = "varth";
      extraVariants = [ "varthj" ];
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/5cdb6521e5b6213c311bb61308b3092d.ico";
          sha256 = "sha256-dBzAlYYUw7wD62hUYGWDOl8fN2ZCjp2wrkHIuHrbZj0=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/f71d3c3105a6e1374c8abd57e8eeaa15.png";
          sha256 = "sha256-WK3CqzL1ci9cuKC2pvgHFwBTtIsVQuaOsxg0rcFrvtQ=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/9251166c44733b893f2803005379f37a.png";
          sha256 = "sha256-HIVZhFZuQuj/IgNYPTxGBwMpiVef2JAlbyv0HnaxkDs=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/272f58b6ebed68be34401cd0d9b78499.png";
          sha256 = "sha256-gdxsdYPTdHU+Dgv8GRJLykaXvI/2RFNIAa1HM7fjd3Y=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/009c33af49f6e5b9b57d31967e7ee46e.png";
          sha256 = "sha256-AfZgySENBuFAN5yv5O3AjRznli3sOMTNTPltmHKnEn4=";
        };
      };
    };
    CAS_WARRIORS_OF_FATE = mkCapcomArcade {
      name = "WARRIORS OF FATE";
      depotId = 1556720;
      manifestId = 939928116172609116;
      sha256 = "sha256-UaHbgywPXTPTw0lsktx3v+RFThqa5f3S5SmgA6a9Kuw=";
      shortname = "wofu";
      emulator = "fbneo";
      extraVariants = [ "wofj" ];
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/e7231cdd39ec8d177d83ba538cac70ba.png";
          sha256 = "sha256-AdfVqZXCpa4b3xGuB+QQFEwH1FYDDzhNkxaIsXlJxvY=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/484c1fb65fa7e725740f20c975c9b284.jpg";
          sha256 = "sha256-Wwpj7kxzFl6mb7rk2KSowdBQamPnE2R27NqEBYF98gE=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/3667791d622e17db04fe6109913a7651.jpg";
          sha256 = "sha256-ovgQmqVtMxSCcQho5+NHqEzvGZ4KekPkgP0LMgNFKuA=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/9eaab9c13cdef28781d614fd9de1b244.png";
          sha256 = "sha256-2zWmXQZ5PmODVgsEw5MIa/yW6h3hASG7Wr2QBtY6jYc=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/436daf7e5bdda10a4194fa6e7fb100d9.png";
          sha256 = "sha256-IjIzud26yVynFPIx4XIJ8CPyQrx3CvlBRyFiQmRo4rw=";
        };
      };
    };
    CAS_STREET_FIGHTER_II_HYPER_FIGHTING = mkCapcomArcade {
      name = "STREET FIGHTER II' - Hyper Fighting -";
      depotId = 1556721;
      manifestId = 8853416909907985637;
      sha256 = "sha256-O7tR84FtygSKaOc1eZFDenKhu9F8+yuc6BIm5busn+A=";
      shortname = "sf2hfu";
      extraVariants = [ "sf2hfj" ];
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/faadd9fb7b13360b4913b3a91c0d6b66.png";
          sha256 = "sha256-5RQz/vtt4TFWzarAvUXtlpQy4nAWLbub3hTKLXFIjDA=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/d8207e803edeb9ee50eb96ac46a27a10.png";
          sha256 = "sha256-lA8OqyOqwNluBCrZQs4ePJ60y+UukEtablSn72ZLPP4=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/6b17d006a2ed6f12f07c7ea60b8002b5.png";
          sha256 = "sha256-vMX6+DfhR+UpQcqCUIcihJYx9/K2EW3Cumw6GiYSaYo=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/176eafc7ea8bd1fb06b8757b724aea72.jpg";
          sha256 = "sha256-4pY8YMpcDDM3gh0AOkfn3kb4P7P0k5UGZIzipPp4ekI=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/7204cd5907572d0713b03e889cb4c290.png";
          sha256 = "sha256-H+oB6L4w6XHIgVsklgD7hHzJz5iXMX5PJaOTY8MB2uM=";
        };
      };
    };
    CAS_POWERED_GEAR = mkCapcomArcade {
      name = "Powered Gear - Strategic Variant Armor Equipment -";
      depotId = 1556723;
      manifestId = 3507050944236305691;
      sha256 = "sha256-ItUjY5gtNNAtSFC7NR3b4LNXP+WAP7DFdFhGm12QzoI=";
      shortname = "pgear";
      emulator = "mame2010";
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
      # Current MAME hard-requires the protection MCU dump under a new
      # filename; mame0139's "sfua" marks it NO_DUMP (non-fatal) instead.
      emulator = "mame2010";
      extraVariants = [ "sfj" ];
      sha256 = "sha256-nG60uUrxYPSKG51GazX9DSMR0dJQXA1+Dk0KKwXqL38=";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/f925d889c47509a561814369363d19e7.png";
          sha256 = "sha256-ozO6l6FAQNC1Fr6k/xDok5ehV+eihtUJPiud4nGhKQ0=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/b7d1f1c8d305db3a7f5bced270c7a47a.png";
          sha256 = "sha256-RjJygOm2uK6UBKyPCA5MKyUT9puxZvyKXtWUUM5WGCE=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/96e780727281bc3d109b130bfe7f41dd.png";
          sha256 = "sha256-RccB3ZyzgAWl+mu5cf3NLMo03ZLyxyqpdzdsaj28XHI=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/96b250a90d3cf0868c83f8c965142d2a.png";
          sha256 = "sha256-rgMZJkRHBiyNSlG43QRQ4bS2bOT6YcpYEy7ASoQTw2M=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/8f8bd93dfe82ad77d6b3ad3fb193d1ba.png";
          sha256 = "sha256-4h/z4Xhfj/TcTASryjhC1ctsQ0uolYN4qPuueD0mVYQ=";
        };
      };
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
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/690d83983a63aa1818423fd6edd3bfdb.png";
          sha256 = "sha256-OMqzcl3JSgk8redlXnbS7SJGNGxHhPLPMptjPGFyLTc=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/5b52c2a49dc6e0b0f512ce11c5e4fbdc.png";
          sha256 = "sha256-apB3beR/JeZkReBWTGFomxXM7nMJyQYtIgQTVqRUFHk=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/1aa422e171759d045bd46c6d38f5d253.png";
          sha256 = "sha256-wsQ09oQUXUTzrHzo3pBR/E/3X0Ij5h/h5Mj5X6950UU=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/a67c236d20090803210a0f236a1097ea.jpg";
          sha256 = "sha256-IKOAoYHpuYEaBgoFPKqQbQ5+R5SDwU8N82ILZ4eRLvs=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/f0f5877bdd2709ec3d779771c4caba2b.png";
          sha256 = "sha256-h77YF/Oox4bMqkhf/QmBSeTNItcZSJl5/ckRwiOAf28=";
        };
      };
    };
    CAS2_KING_OF_DRAGONS = mkCapcomArcade2 {
      name = "The King of Dragons";
      depotId = 1842967;
      manifestId = 4888131231458650022;
      shortname = "kodu";
      emulator = "fbneo";
      extraVariants = [ "kodjr3" ];
      sha256 = "sha256-D5cXpIKc29nUw82Sl48fnzOT7T28xf34o8nZ1xgh788=";
    };
    CAS2_SLAM_MASTERS = mkCapcomArcade2 {
      name = "Saturday Night Slam Masters";
      depotId = 1842968;
      manifestId = 1628235808209934720;
      shortname = "slammastur1";
      # MAME's current driver dropped the "r1" revision suffix; MAME/mame2010
      # also want this content cross-combined with mbomberjr1's data
      # (RED-Project#192), but FBNeo's own ROM database accepts this dump
      # directly, no reconstruction needed.
      mameSystem = "slammastu";
      emulator = "fbneo";
      extraVariants = [ "mbomberjr1" ];
      sha256 = "sha256-KWN1IkEysztoy9vaFtFoWtS4uPsZCbcELGgSs+wslcM=";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/d8c8ab01f40605bbaf209306092135a1.png";
          sha256 = "sha256-upfUplg8qBGkBx5qic6hpJir9ohhmMxt5nCuotedDP8=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/2b45eff9c8b89150444adfeb1802a86b.png";
          sha256 = "sha256-6Y2RI8isd7DMKjpFdC/tKesCOfQHRxWfaTpk7+oDOJk=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/3c104bc89d04cdda44a3617acd3683c9.png";
          sha256 = "sha256-OPdKK+hGBbrZ3Wodsp/VqVW0+LPMOGZapJqrT4dFlwM=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/1fe3ee2df00b047f9932aeade98859c2.jpg";
          sha256 = "sha256-j47PGxkEXw7mJHLzrI1wza+JLoN/Z6r2CrGYEQf4t00=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/a19c477ad72b23bf84cb5dddd8b75e9e.png";
          sha256 = "sha256-1LLQ0gEchvLNIEKEItI+BSKasoqRNMcDpNb/BSFXfb4=";
        };
      };
    };
    CAS2_ECO_FIGHTERS = mkCapcomArcade2 {
      name = "Eco Fighters";
      depotId = 1842969;
      manifestId = 5392066310871616954;
      shortname = "ecofghtru";
      emulator = "mame2010";
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
      emulator = "mame2010";
      extraVariants = [ "vampj_940818" ];
      sha256 = "sha256-KGeRib9LW/1h+FvZspu35a94S5iSP3wTQ/vVi3AvdFU=";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/3e1f618033945f210a55c8d77277cfc9.png";
          sha256 = "sha256-Rf21VJ3QFRSdpVSv3nHjt7ryg/lV/ykOERkWSr+heIs=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/833552e068d3cf30bf8a677ddb104b83.png";
          sha256 = "sha256-zwnlA7WxQSy9t8QPI9dBvo2F6+dSm5oy0jdiPrNjcs0=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/22456f4b545572855c766df5eefc9832.png";
          sha256 = "sha256-DR3kSOqly6iax447lglaM0rM4moHXWQ0E46gPjXkSeM=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/6963cde4b6c8633a1fee8ba021684563.png";
          sha256 = "sha256-Nmag3b0j3SnzfetPjaxTqFCEY/p0R5G7LvAv6HgQJOE=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/1977ab8c9f9473d8594671be4ddf9e7f.png";
          sha256 = "sha256-6Rv9EkJbvntP0/uF7Fe3KJKWLCWinlq5SNujgGCyVP8=";
        };
      };
    };
    CAS2_STREET_FIGHTER_ALPHA = mkCapcomArcade2 {
      name = "Street Fighter Alpha: Warriors' Dreams";
      depotId = 1842972;
      manifestId = 1372844834572053952;
      shortname = "sfau_950727";
      # MAME's current driver dropped the date suffix.
      mameSystem = "sfau";
      romPatch = {
        rename = {
          "SFZ.05B" = "sfz.05a";
          "SFZU.04C" = "sfz.04a";
          "sfzu.key" = "sfau.key";
          "SFZU.03D" = "sfzu.03a";
        };
      };
      emulator = "mame2010";
      extraVariants = [ "sfzj" ];
      sha256 = "sha256-f7cnKa3uk5uBJZUZ1Moq7SdhNhFhOgsuMaR5BXtPob0=";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/cbe4a675981f20ffb27ea97bb036cfae.png";
          sha256 = "sha256-ngEL227jlqMzOFLLI7vbSws7Lzkvd+SSFhhRA34vll0=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/58f026b4e22be105b001e823ba5e4d46.png";
          sha256 = "sha256-sgtNbuPAQbMBPJkLx4dQYEcU7HForWKxxNtyV1oxp7I=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/06a15eb1c3836723b53e4abca8d9b879.png";
          sha256 = "sha256-n59AHwKA91cPALLdGxfiOkdYvQJg0cOjxOPhLZ/+1Gk=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/3506709108e107543aa9fcf845daf0a6.png";
          sha256 = "sha256-fSZw7oA+wF2O8GENKu/pudSd1JzftRSOiBoBnmfUCYA=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/30ee748d38e21392de740e2f9dc686b6.png";
          sha256 = "sha256-8uFL+zTP+CNl8xbfFfcPoV9aJEvuP5XGzztkHo01ztk=";
        };
      };
    };
    CAS2_MEGA_MAN_POWER_BATTLE = mkCapcomArcade2 {
      name = "Mega Man: The Power Battle";
      depotId = 1842973;
      manifestId = 336887344897685996;
      shortname = "megaman";
      extraVariants = [ "megamanj" ];
      sha256 = "sha256-XsM2+u4X+tGM+j97rYtpO4sfD6AqhBS3PJBCEfjwkqA=";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/0554ad2558c20505cf185f4ed40148ae.ico";
          sha256 = "sha256-kdoiK50Qke+7tP89AhVcBDphz7ExRnVKP46JOYFoMek=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/af88750567b6ba69738b21c8745b24e8.png";
          sha256 = "sha256-M1SBcLEMXKceEPwbyYTWjEnsXs9Fkdx/ZrIGtBHaLlw=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/bb6b07f0fd4afe38c61f232bbb693fd7.png";
          sha256 = "sha256-0xh+8TolnHbfTOlwZWmrc8mT0ZqDW4Z+MnEltV8pz48=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/7081c837a17b5649dbbe2ed841196d30.jpg";
          sha256 = "sha256-Cy1c6MINi8/Ms5M4WK5i8beatlX56QVysZ5o3p1XXZc=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/1751a9a215df522dcf207ba51b327643.png";
          sha256 = "sha256-5sKLE+Yn9qOWlCzSFlJAjvxvzOm9ALdVIobWXv6Gn5I=";
        };
      };
    };
    CAS2_STREET_FIGHTER_ALPHA_2 = mkCapcomArcade2 {
      name = "Street Fighter Alpha 2";
      depotId = 1842974;
      manifestId = 5026210803311757706;
      shortname = "sfa2u";
      # "sfa2u" didn't exist yet as a driver name in mame2010's vintage
      # (Unknown system); dl-1425.bin is a universal QSound HLE lookup ROM
      # shared across many CPS1/2 titles, not per-game content -- a dummy
      # stub lets mainline MAME load it instead.
      romPatch.add."dl-1425.bin" = 8192;
      extraVariants = [ "sfz2j" ];
      sha256 = "sha256-+K2u/HcbfuO6mbyODJUjSlSa65fihpfRErL8s+bMLA4=";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/753d0c1b60cc9f7b9717d40dac01a96e.png";
          sha256 = "sha256-zu0dWsBKOLLFdFvpszNwHubS/Xx8qcHNLRAF+e7/Hvk=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/6b55f00da01b1282c17d91c7760d2df9.png";
          sha256 = "sha256-yO2A0mqtCZziKu9UI7KwvGujDHe+W8uBzr4+Y+O8cLI=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/411fa12071ee54b837ed4bfdf200d526.png";
          sha256 = "sha256-bnNzyE8S4x0aSEdmXlGl+qpI3nvGHIVe0m94E1aRtso=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/744a873401e614a0264c71f24c77a381.jpg";
          sha256 = "sha256-XR+Le6JwC2WJBMEhy3JBm2ISIL592YdiUvvWxVVahV0=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/9b5977b4521e5e48a8ef03ae73c4112d.png";
          sha256 = "sha256-7KKeyxJrtMIjA7ZrVHbRVIi/6l7yvRcwPpcNqUTqx+k=";
        };
      };
    };
    CAS2_HISSATSU_BURAIKEN = mkCapcomArcade2 {
      name = "Hissatsu Buraiken";
      depotId = 1842975;
      manifestId = 6279003862699888025;
      shortname = "buraiken";
      emulator = "mame2010";
      sha256 = "sha256-RZS3ylIL/l8M4jEkxj4Z+GgbKwuaFrC/5w6Gl32i3u8=";
    };
    CAS2_1943_KAI = mkCapcomArcade2 {
      name = "1943 Kai - Midway Kaisen -";
      depotId = 1842976;
      manifestId = 5008732065646381718;
      shortname = "1943kai";
      emulator = "mame2010";
      sha256 = "sha256-IvlsOf0OPu2nvFL53XEqU3bsbVS3J51Ao0veX7XP7w0=";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/5af243115f9ec87355d9bee000626351.ico";
          sha256 = "sha256-rrzq7dni9STJ0oi1byIe/Ewt77vV2x/mIprUd8xDNDw=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/d0505d156ac710a1c3da7cb40425139b.png";
          sha256 = "sha256-lksLDervjTwke8qRuJfoyvobsdw44O4DIUUGirQgPKs=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/9fab699778515e57db05c17dd8b92e30.png";
          sha256 = "sha256-8DP6/6gezeE1WtNQwDE36WDchQzuCuSP1CtiI2PQdBI=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/139042a4157a773f209847829d80894d.png";
          sha256 = "sha256-PHFhsWz8EPSSlgp3Sx+3E6TspK1nUaUucFmH0KUjaCI=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/a4589a60ea90b98f8f75780b4c829e9a.png";
          sha256 = "sha256-hZTuJUtJ3Ps4rGRLtmN5XVmZdob+ViMTRrvFPIAEARU=";
        };
      };
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
      name = "Magic Sword";
      depotId = 1842979;
      manifestId = 5437653424291948405;
      shortname = "mswordu";
      extraVariants = [ "mswordj" ];
      sha256 = "sha256-Arl6lkgUXXk20wgn46UYUwvPUu5vIusK5wUj3J90RXc=";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/ee606869f78127ed0411ed54e8449a92.png";
          sha256 = "sha256-q8W6ihpXTcIUSZNHhU8gTHLQBAzAderSlVKzoXGJqLI=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/4a222abf0da5e49d0f15264e2037895e.png";
          sha256 = "sha256-qI71muKUZHVVas6FiZlsABGlvipEgpmxxHpvcpWn8Ic=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/21729543fb3bf3a270c704f8367c99a5.png";
          sha256 = "sha256-xmQxkdFzEHmcMsOWYGgr6KqUKhyyQtx0B1KqJH141Lo=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/5d352ecee1ff01aab9d3c39761b27334.jpg";
          sha256 = "sha256-Tg3vA5sJ8X6mSu1OUhBzXISmjALyw+p7g31RFIJgRp8=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/c3f9998b6447338a54eeefb1c51ce567.png";
          sha256 = "sha256-JceC7Z9uy05LdVrubW8kbP7IDT6emJ1omFywrK48HMA=";
        };
      };
    };
    CAS2_BLOCK_BLOCK = mkCapcomArcade2 {
      name = "Block Block";
      depotId = 1842980;
      manifestId = 3617612435567830562;
      shortname = "blockr2";
      mameSystem = "block";
      emulator = "mame2010";
      extraVariants = [ "blockj" ];
      sha256 = "sha256-S6P4jbF+N9JYTuI+eQQAAGZWc96tDit/dzC6ykjG8qo=";
    };
    CAS2_KNIGHTS_OF_THE_ROUND = mkCapcomArcade2 {
      name = "Knights of the Round";
      depotId = 1842981;
      manifestId = 621514193746640518;
      shortname = "knightsu";
      extraVariants = [ "knightsj" ];
      sha256 = "sha256-T5+9p2wsVXrWDOQyEjw0zynMEkGwm4PJolsiwh4Ux98=";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/178b99100c7594627daa57e8fa69da24.png";
          sha256 = "sha256-I+yVSYsrjEIwUMHVtCD6nWs8Jh4Sv1Gc1DYv2VJiYyo=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/94bc8b7e4631b22431b57fe25cc4e61f.png";
          sha256 = "sha256-VTh6vx1pmpjDXrCOW/gqHfeaUS8WvBaQwwT2kIJiMPM=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/2f75d7dddf73483d16a099322fd92e3a.png";
          sha256 = "sha256-eLbAZPBLvsUTixwnQwwuTAz/PCze9Ucrf5Ase8X/Wng=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/25639022948ed45cef4ffffe83f2c556.jpg";
          sha256 = "sha256-I6tv99YCsGN+ESL/aDvTykLXO0JUlB66lxUCXhw1fEk=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/ff6b922f140cdc4bc622f4d0b0818e18.png";
          sha256 = "sha256-b6ZwEvOOd1Dl0uZt39iAcdr6eT3fsAvSKyxYRCoqH+E=";
        };
      };
    };
    CAS2_NIGHT_WARRIORS = mkCapcomArcade2 {
      name = "Night Warriors: Darkstalkers' Revenge";
      depotId = 1842982;
      manifestId = 615881480605010086;
      shortname = "nwarre_950420";
      # MAME's current driver dropped the date suffix.
      mameSystem = "nwarr";
      romPatch = {
        rename = {
          "VPHE.03G" = "vphe.03f";
        };
      };
      emulator = "mame2010";
      extraVariants = [ "vhuntj_950420" ];
      sha256 = "sha256-7UNXxH4T6+8wnPtO3huxEdgYLXbaOlY1VC+wDqUc5G8=";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/a6c506c61e1677550136a42f6948aec1.png";
          sha256 = "sha256-XTHyixcv2E1yTfClf1RPIQDnF3dE14/KbwXNcV8In5A=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/c27b70bc885cfc378c0ea91bf9953cf6.png";
          sha256 = "sha256-Qt6t97jtz+khYzsWAbNNA6i/ZegkTbfFoBwL+bb7i/A=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/ff2b205b94763692ae03846c493a5ce7.png";
          sha256 = "sha256-skPyqIRGF7c8FdF6Jy0s+QxT3Ndej2sq7hvh2DPkIHo=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/010918db27b6631cdc9ecff0f7f960d9.png";
          sha256 = "sha256-eRZdgUplJKJySdl0lAMJpNWZIx3cuQy7/b0no0VzDD0=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/beb3c650aaae598375f60df2c6063269.png";
          sha256 = "sha256-YllUjU7QPKjdWiRn6sQUstwo62J2QH1jWrA3QO+//p4=";
        };
      };
    };
    CAS2_SUPER_PUZZLE_FIGHTER_II_TURBO = mkCapcomArcade2 {
      name = "Super Puzzle Fighter II Turbo";
      depotId = 1842983;
      manifestId = 1897934777002168467;
      shortname = "spf2tu";
      # Same as sfa2u: "spf2tu" didn't exist as a driver name in mame2010's
      # vintage; dummy-stub the shared dl-1425.bin under mainline MAME.
      romPatch.add."dl-1425.bin" = 8192;
      extraVariants = [ "spf2xj" ];
      sha256 = "sha256-BqyS8iQtNUM/N/obzHITvXY3jZgqaGUfFO6eboqDkrI=";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/51be12b3867a37636fddfee6716a6109.ico";
          sha256 = "sha256-4t3EFaXjMzoiRvujKQ1Y1YKaa4UYOXHak+6XB5lOKng=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/f9d1152547c0bde01830b7e8bd60024c.png";
          sha256 = "sha256-3KTPg7i0PdwD9bcapTBgTJZtL39MpYae1qSEwItK4ZY=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/5d7bec8c05ebb017758028aa34da27b1.png";
          sha256 = "sha256-TZeai0B1u0dQyPHoKDJaLZjCOleVsl57EWiBBsQdyRo=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/f4696b4f528efcb44201bbe56c57b618.png";
          sha256 = "sha256-dLQHs6uAjY5tuuIu7vFacVx52Am9LngCyipQt6axelw=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/8cb5ea731c124302bdc1daf59ef8b5a4.png";
          sha256 = "sha256-o74AO+K0whTVoYpXlYah2lyMVt/4TxKSNRwzIgt7lAY=";
        };
      };
    };
    CAS2_MEGA_MAN_2_POWER_FIGHTERS = mkCapcomArcade2 {
      name = "Mega Man 2: The Power Fighters";
      depotId = 1842984;
      manifestId = 1023452342768997774;
      shortname = "megaman2";
      # Current MAME's QSound HLE needs a shared qsound.zip BIOS
      # (dl-1425.bin) this dump predates -- MAME 0.139's synthesis-based
      # QSound emulation has no such dependency. Confirmed: passes clean
      # under mame2010 with zero other changes.
      emulator = "mame2010";
      extraVariants = [ "rockman2j" ];
      sha256 = "sha256-9MzB2hvWzLrzoaAc+m873m8tyNOspGa06lUazBpOqQ4=";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/e52732dd6f487d77dfc098228406b646.ico";
          sha256 = "sha256-gX+DcGJkIgNWDYftw3eEHdV9+dY/TAWgPqNDRuVdAMo=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/923d001edbd44bbf095ee2bc03e9fca0.png";
          sha256 = "sha256-OwHw6RUFxA9CvupQLaYqby78BSGc+Lr2iQvu6F9aOlY=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/d5747424d04a6d71f0e652de55872534.png";
          sha256 = "sha256-i+yCe6rXdh8ajoh53L9ss+7FDE+BaUyJO/0I94HpIDs=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/9e9e009dac5a57f08b9c4b364bca2f27.png";
          sha256 = "sha256-mYXC/NiPSP33rhBdKqKFb5gfTS6kgDTFmiXuY6IbYBw=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/ef80b7219c2db106c9a5a19bd629af2e.png";
          sha256 = "sha256-x+euwHT4YU7JHK1bmeGxKme19j6RRLnZuVYSsD9HAYA=";
        };
      };
    };
    CAS2_VAMPIRE_SAVIOR = mkCapcomArcade2 {
      name = "Vampire Savior: The Lord of Vampire";
      depotId = 1842985;
      manifestId = 6829454349251196795;
      shortname = "vsavu";
      emulator = "mame2010";
      extraVariants = [ "vsavj" ];
      sha256 = "sha256-lUzpKNKlEs6zuWrCaYnw5EvGD8m9nvNYd8YHfJCpm2A=";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/4287990f7cf627545fb78965df7fa415.png";
          sha256 = "sha256-6PFpVXkFfAXGbnEjQXK5mN54XcQKjMBwzfWr64O+yDo=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/1464fdc6211b3bcca0d8d02234158248.jpg";
          sha256 = "sha256-AKdW1zShd2wHvpHsfg3UEKxSwQhZYa3fm436PYYRDG8=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/4f68d6a8a0309b36b9a6b44de9d2eb05.png";
          sha256 = "sha256-yusQ/VVaB77FMyNf0v6p/cjOEB9xy1EpHfPZsZ/jSrA=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/16a8d0c178e877a642837bf57984fb5e.png";
          sha256 = "sha256-Bj/hNvnS0fX/a98o7lUTXlbQsY4vkwbaRas6F9Y8bp4=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/2743214d24795dc7d9caf7751a3684c9.png";
          sha256 = "sha256-4Fw7mWSErdceKrfRvNzlnGf4xy78RSt1HLrclsThdEQ=";
        };
      };
    };
    CAS2_CAPCOM_SPORTS_CLUB = mkCapcomArcade2 {
      name = "Capcom Sports Club";
      depotId = 1842986;
      manifestId = 9090483507631980910;
      # 4 of 12 files don't match any known csclub-family CRC in MAME
      # (confirmed independently and by RED-Project#192), but FBNeo's own
      # ROM database accepts this dump directly.
      shortname = "csclubu_971017";
      emulator = "fbneo";
      extraVariants = [ "csclubj" ];
      sha256 = "sha256-FW2Ofjidti6B4T8Ihd0DXefMbi7FqL523EW057hFaaA=";
    };
    CAS2_SUPER_GEM_FIGHTER = mkCapcomArcade2 {
      name = "Super Gem Fighter Mini Mix";
      depotId = 1842987;
      manifestId = 7239720317153599283;
      shortname = "sgemfu_970922";
      # MAME's current driver dropped the date suffix. 4 program chips don't
      # match any known MAME sgemf-family CRC in any era, but FBNeo's own
      # ROM database accepts this dump directly.
      mameSystem = "sgemf";
      emulator = "fbneo";
      extraVariants = [ "pfghtj_970922" ];
      sha256 = "sha256-dYNtRPiYySqK0OSCqbA+OmsKD9DaFDye6xmDnP03e4g=";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/98512e599eadddf308d4dfeb48f98005.png";
          sha256 = "sha256-SCa/Isbg1eOsIkB7IA4EzMXy9X8hdWS/fHMien3POXE=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/8d3f1ab6a0ac5d3f557d3541a8ac3162.png";
          sha256 = "sha256-12MR/hT1ApkMHY5DnSrIVc1NNkrksrI8xd/7G5AuoYg=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/080f6271695a90d0d2234d55f4bab601.png";
          sha256 = "sha256-pVHuaCRArjltvSVe/SfkOZlUy988aU+Cf7zSFkZdosA=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/d92e39f6f092e24948641a150e2c841d.png";
          sha256 = "sha256-NCZUWV6WBdqn0D5lbHPX5HZXGK97jhfbQkI0q/QEakE=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/83b034fd013fc37aa7ca6041a75ed03e.png";
          sha256 = "sha256-cMbe2l9AG69IVq+Or3jWOA29TmjiE9x28UZWuNJiln4=";
        };
      };
    };
    CAS2_STREET_FIGHTER_ALPHA_3 = mkCapcomArcade2 {
      name = "Street Fighter Alpha 3";
      depotId = 1842988;
      manifestId = 8254947701711188485;
      shortname = "sfa3u";
      # Same QSound dl-1425.bin gap as megaman2 -- mame0139 predates the
      # HLE sample requirement.
      emulator = "mame2010";
      extraVariants = [ "sfz3j" ];
      sha256 = "sha256-erwPHYa6qny6R7eCrc/kkluN2VolhB5TRR9uByfd2/g=";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/a216f784baf4edda106603ef76adfcb1.png";
          sha256 = "sha256-2IMSQhwGmcvHoixgMJCI/gN9CtL5OJjX1FgPchFqpzE=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/b05aa5ae598aff32ec94a1156bd7132b.png";
          sha256 = "sha256-4VeqgxmY8QiWHxWCyMldPSaS1OwtqvO6oTIBQA9IkDw=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/4984ba34063e003daf14d28d31c59391.png";
          sha256 = "sha256-bC2H+haTM3OMGBtKbHPg5A7j4XBWim2Tn8gINTY3IVM=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/df193a49317e95704244d5e88c7a6902.jpg";
          sha256 = "sha256-VDF1wAKlh6+kmyX8pJvSVVEeZvnE8HgBcRyHhLiZT0Y=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/331cc28f8747a032890d0429b5a5f0e5.png";
          sha256 = "sha256-hHh6Zb/G0T5o6F25yNLn/1ebAQB6rrvGzXduzWSjJ6Y=";
        };
      };
    };
    CAS2_HYPER_STREET_FIGHTER_II = mkCapcomArcade2 {
      name = "Hyper Street Fighter II: The Anniversary Edition";
      depotId = 1842989;
      manifestId = 8949776931283853998;
      shortname = "hsf2";
      emulator = "mame2010";
      extraVariants = [ "hsf2j" ];
      sha256 = "sha256-T0DtHC1LkhfD3VrbaZxVK6rRDfh5gKiHnOcLlZ27Jxw=";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/313e7d092611f0c58251064957ca6b4c.png";
          sha256 = "sha256-0w5wgDKPI5ZM/h7rVQEV+uHP9oTa0cvqo+JMVuFiGbk=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/0af7b7a01a2b6eb43c4b6bdac55638a0.png";
          sha256 = "sha256-9CgvV0hScs80OnabOKfj6++KvVKro+vpuZVvGEN3pOQ=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/4553e2860aa9b02beb881caf80d50e19.png";
          sha256 = "sha256-FPkk1/MsCdQTSsBguxYD6EbVGaS2uZspnIYi0FZgyAg=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/21cfcb4f0a621f01b09c81e315e099d4.png";
          sha256 = "sha256-mcA7E1w5TDat2D4G5YDCdH6NSlUU/onjofA3/GPiR7Q=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/53ddc60bfd3094fb49c3e2b20022357e.png";
          sha256 = "sha256-zAewjUo/60Z5Pjl8Nrp3lWWiRPYUTi1PWIzMQrkgt/E=";
        };
      };
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
  programs.steam.games =
    lib.mapAttrs (
      _: entry:
      mkArcade (
        {
          inherit (entry) name;
          shortname = entry.mameSystem or entry.shortname;
          emulator = entry.emulator or "mame";
          romset = config.games.emulation.roms.${entry.shortname};
        }
        // (if entry ? images then { inherit (entry) images; } else { })
      )
    ) capcomEntries
    // {
      CAPCOM_ARCADE_STADIUM_SOURCE = {
        disabled = true;
        name = "Capcom Arcade Stadium";
        steamAppId = 1515950;
      };
      CAPCOM_ARCADE_2ND_STADIUM_SOURCE = {
        disabled = true;
        name = "Capcom Arcade 2nd Stadium";
        steamAppId = 1755910;
      };
    };
}
