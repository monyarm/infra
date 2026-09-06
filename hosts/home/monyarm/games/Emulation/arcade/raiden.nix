{
  config,
  lib,
  pkgs,
  fetchSteam,
  mkArcade,
  ...
}:
let
  # single depot bundles Raiden + the Raiden Fighters trilogy; each has its
  # own marker file (raiden_maincpu.bin, rdft_i386.bin, rdft2_i386.bin,
  # rfjet_i386.bin) that dotemu2mame's detection checks in an if/else chain,
  # so each game needs its own invocation pointed at its own directory
  raidenLegacy = fetchSteam {
    appId = 407600;
    depotId = 407601;
    manifestId = 9094347697498516259;
    # DotEmu depots aren't split by OS; DepotDownloader's default -os linux
    # filter doesn't match these manifests' real tagging -- omit it
    os = null;
    sha256 = "sha256-Wb0/7ykBuUT7oKTTPYkyg3GUQzaIhaLL3pryUgJTCR4=";
  };

  markers = [
    "raiden_maincpu.bin"
    "rdft_i386.bin"
    "rdft2_i386.bin"
    "rfjet_i386.bin"
  ];

  extracted =
    pkgs.runCommand "raiden-legacy-extracted-roms"
      {
        nativeBuildInputs = [ pkgs.nodejs ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        mkdir -p $out
        for marker in ${lib.escapeShellArgs markers}; do
          find ${raidenLegacy} -name "$marker" -printf '%h\n' | sort -u | while read -r dir; do
            (cd $out && ${pkgs.dotemu2mame}/bin/dotemu2mame "$dir")
          done
        done
      '';

  extractedZip =
    name:
    pkgs.runCommand "${name}.zip"
      {
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        cp "$(find ${extracted} -name ${lib.escapeShellArg "${name}.zip"})" $out
      '';
in
lib.mkIf config.games.emulation.enable {
  programs.steam.games = {
    RAIDEN = mkArcade {
      name = "Raiden";
      romset = extractedZip "raidenb";
      shortname = "raidenb";
      images.icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon/b7c72b1b53ebc0b5af2bcf4c7c52e5aa.png";
        sha256 = "sha256-zKX4CKxyscRVh3rCn/h2wfkWTziYouJhB0+130tpgeQ=";
      };
      images.hero = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/hero/eb844cbe61ad95e6462ee45f7c3d87ae.png";
        sha256 = "sha256-Rtc156mEunseVNeupGqrfeI8/x+vUqIePhXj9jYk38s=";
      };
      images.grid = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/e09a0a2083ca253edb80920fc0cc43b9.png";
        sha256 = "sha256-eS8pRX7aMNlAXwfPbSlWd+yZRhBs14SV5LjdGAFGE/4=";
      };
      images.wide = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/grid/4cb2d7e692818b5e431b4f6ddaacd5a4.png";
        sha256 = "sha256-/AhN9Pavum9MD7M6rpi+DWony/sqe8RVWkT+oDGzcPE=";
      };
      images.logo = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/logo/de4ae1f4f810873e3b18b2f942b45795.png";
        sha256 = "sha256-53CPz0T6owyEHF3hPpegp/CS+cy1Pw+jHzbPHlLFAU8=";
      };
    };
    RAIDEN_FIGHTERS = mkArcade {
      name = "Raiden Fighters";
      romset = extractedZip "rdftj";
      # Content matches mame0139's "rdft" (then the parent set) byte-for-byte;
      # current MAME renamed which region variant is the parent, so this
      # exact dump is "rdftj" there instead -- mame2010 still calls it "rdft".
      shortname = "rdft";
      emulator = "mame2010";
    };
    RAIDEN_FIGHTERS_2 = mkArcade {
      name = "Raiden Fighters 2";
      romset = extractedZip "rdft2";
      shortname = "rdft2";
      emulator = "mame2010";
    };
    RAIDEN_FIGHTERS_JET = mkArcade {
      name = "Raiden Fighters Jet";
      romset = extractedZip "rfjet";
      shortname = "rfjet";
    };
  };
}
