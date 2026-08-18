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
    pkgs.runCommand "${name}.zip" { } ''
      cp "$(find ${extracted} -name ${lib.escapeShellArg "${name}.zip"})" $out
    '';
in
lib.mkIf config.games.emulation.enable {
  programs.steam.games = {
    RAIDEN = mkArcade {
      name = "Raiden";
      romset = extractedZip "raidenb";
      shortname = "raidenb";
    };
    RAIDEN_FIGHTERS = mkArcade {
      name = "Raiden Fighters";
      romset = extractedZip "rdftj";
      shortname = "rdftj";
    };
    RAIDEN_FIGHTERS_2 = mkArcade {
      name = "Raiden Fighters 2";
      romset = extractedZip "rdft2";
      shortname = "rdft2";
    };
    RAIDEN_FIGHTERS_JET = mkArcade {
      name = "Raiden Fighters Jet";
      romset = extractedZip "rfjet";
      shortname = "rfjet";
    };
  };
}
