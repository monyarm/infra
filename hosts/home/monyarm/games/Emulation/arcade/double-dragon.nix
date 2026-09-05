{
  config,
  lib,
  pkgs,
  fetchSteam,
  mkArcade,
  ...
}:
let
  # all three games' resource files sit flat in one resources/game/ dir (no
  # per-game subfolder like Raiden Legacy) -- dotemu2mame's single
  # ddragon_hd6309.bin marker check triggers ddragon()+ddragon2()+ddragon3()
  # together, so one invocation covers the whole trilogy.
  doubleDragonTrilogy = fetchSteam {
    appId = 314150;
    depotId = 314151;
    manifestId = 1998632449042343054;
    # DotEmu depots aren't split by OS; DepotDownloader's default -os linux
    # filter doesn't match these manifests' real tagging -- omit it
    os = null;
    filelist = map (n: "resources/game/${n}") [
      "ddragon_hd6309.bin"
      "ddragon_hd63701.bin"
      "ddragon_m6809.bin"
      "ddragon_gfxdata1.bin"
      "ddragon_gfxdata2.bin"
      "ddragon_gfxdata3.bin"
      "ddragon_adpcm.bin"
      "proms.bin"
      "ddragon2_hd6309.bin"
      "ddragon2_z80sub.bin"
      "ddragon2_z80sound.bin"
      "ddragon2_gfxdata1.bin"
      "ddragon2_gfxdata2.bin"
      "ddragon2_gfxdata3.bin"
      "ddragon2_oki.bin"
      "ddragon3_m68k.bin"
      "ddragon3_z80.bin"
      "ddragon3_gfxdata1.bin"
      "ddragon3_gfxdata2.bin"
      "ddragon3_oki.bin"
    ];
    sha256 = "sha256-pxh7BDoT4OIWGsfN2zar20qbuUlLZkNeGNuWwHBRkcM=";
  };

  extracted =
    pkgs.runCommand "double-dragon-trilogy-extracted-roms"
      {
        nativeBuildInputs = [ pkgs.nodejs ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        mkdir -p $out
        dir="$(find ${doubleDragonTrilogy} -name ddragon_hd6309.bin -printf '%h\n')"
        (cd $out && ${pkgs.dotemu2mame}/bin/dotemu2mame "$dir")
      '';

  extractedZip =
    name:
    pkgs.runCommand "${name}.zip" { } ''
      cp "$(find ${extracted} -name ${lib.escapeShellArg "${name}.zip"})" $out
    '';
in
lib.mkIf config.games.emulation.enable {
  programs.steam.games = {
    DOUBLE_DRAGON = mkArcade {
      name = "Double Dragon";
      romset = extractedZip "ddragon";
      shortname = "ddragon";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/d83a3ece517109abe8c5127136eb6145.png";
          sha256 = "sha256-9ySY5g03FUb+3hmm8IPhX5kx/igWt76xGpRnkTlu7Rg=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/9e7a3b6fbfa4f7c2052f776f1b4eab35.png";
          sha256 = "sha256-OOgLQrnsfIL6Df6KY/xVWpyEQeT1mIEGO77nmZc4Tho=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/d27e89910b2505a3e0f22461d4eb9aa7.png";
          sha256 = "sha256-gXjvFxf7FyzN1Xv3KeJ91Q/dsOLI/ayeoa0mefWW4nA=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/c6b5359f37fa977e7f9e4d1c533bc1c0.png";
          sha256 = "sha256-GKC0kaOf+5wwNvv/BWM0SIY2LXsuzga8tqxHuJiUavU=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/132af5e482483ff69c642974b3ec23a7.png";
          sha256 = "sha256-TWFgwnbY+nI9IMsBTz0qw1u6SAlaEZeEOwlPHD68S3o=";
        };
      };
    };
    DOUBLE_DRAGON_2 = mkArcade {
      name = "Double Dragon II: The Revenge";
      romset = extractedZip "ddragon2";
      shortname = "ddragon2";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/e746ec9d02541b374a9aead8fdb941fe.png";
          sha256 = "sha256-U4kR7RWyTkfglr/25V5K1S+AZHMk/z2YfT/FgfV9qMY=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/4d231a32781b0536c2290fb9898630f9.png";
          sha256 = "sha256-pH6FeNqEJIJhn8Fx3GheQLatNFWScpDKNqBqsS1cvT0=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/ec5c931cc3eb9fcc8a46b364c0f69e51.png";
          sha256 = "sha256-mkygB5vynASaNoYkNHoYU8STGNcad3Tn7S0t5pv9NlQ=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/e36e012e7c27fac9057da8f154cecebe.jpg";
          sha256 = "sha256-JKkpFQHa0ntC6x7dpINOiZFgQtAZ9U4ZSjcI6qqLLrQ=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/6c50432e82f3e7e45fa52df9c65148da.png";
          sha256 = "sha256-Wzwww/X9ggz656+0jyL9iBfqbgYegk3dsfmQiQy5KmU=";
        };
      };
    };
    DOUBLE_DRAGON_3 = mkArcade {
      name = "Double Dragon 3: The Rosetta Stone";
      romset = extractedZip "ddragon3";
      shortname = "ddragon3";
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/45c1824b0a9aea167565a29e700a1ca1.png";
          sha256 = "sha256-yT5hGRtCwM5dlyV1D2CaQKVAwuND+DxPIc/z3rovRs0=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/286f73111ed59440a39ec623872a0a12.png";
          sha256 = "sha256-VEp08APeIxwYGe9bQkWF0KX0BpTL9zaU2JFAYcMapJk=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/8c96ff2663551d41c5eb5199f2a3e598.jpg";
          sha256 = "sha256-e9XMpNzTup2LcuKtDC6uCqzEZpvKTIAmYOGBHCTpgt8=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/21ea0e818cc36595bdb3d5afb2f09788.jpg";
          sha256 = "sha256-JQTBvk3Ay15/QmFvn8RPk3UHnfNf1/d3/C1IaRUq/8w=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/5d80f41d392a2f39804eae9eb91fe770.png";
          sha256 = "sha256-P9rvp5Dp3Qh2b0Cgj0j8hBj3UPg+r5zHzTmpsfE2p1w=";
        };
      };
    };
  };
}
