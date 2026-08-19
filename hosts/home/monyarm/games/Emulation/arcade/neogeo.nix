{
  config,
  lib,
  pkgs,
  fetchSteam,
  mkNeoGeo,
  getFile,
  ...
}:
let
  # each depot is the game's own DotEmu release; neogeo-rom-extractor's
  # per-game modules stage under a folder matching one of their own
  # search_folder_names and pull real MAME-format roms out of it
  metalSlug = fetchSteam {
    appId = 366250;
    depotId = 366251;
    manifestId = 2905929974020898780;
    # DotEmu depots aren't split by OS; DepotDownloader's default -os linux
    # filter doesn't match these manifests' real tagging -- omit it
    os = null;
    sha256 = "sha256-V0GasCzQWpv4s3fZwYYoAxP5ozneGjYWnunPWbUAeNs=";
  };
  metalSlug2 = fetchSteam {
    appId = 366260;
    depotId = 366261;
    manifestId = 1979623860533635830;
    os = null;
    sha256 = "sha256-VDQSwGoMHvWv7IsMgal0YEJTAQOMpyt5C4XjkJtUUnk=";
  };
  metalSlug3 = fetchSteam {
    appId = 250180;
    depotId = 250181;
    manifestId = 2708512601076444967;
    os = null;
    sha256 = "sha256-IlnAzmDTZrtPZ74hveF8+EVbazaSef9icpZqgDNqai8=";
  };
  twinkleStarSprites = fetchSteam {
    appId = 366280;
    depotId = 366281;
    manifestId = 1720600691697359437;
    os = null;
    sha256 = "sha256-+E8JnlnwhXchWZOJFZC2Ghb8cDoBkPmD8uEnVYxpl3c=";
  };

  # neogeo_extractor.py derives its scan root from its own script location
  # (SCAN_ROOT = script's parent dir), so the extractor tree has to be
  # copied out of the (read-only) nix store next to the staged game
  # folders rather than run from $out/bin directly; --all also produces
  # the shared neogeo.zip BIOS from whichever title's data carries it
  extracted =
    pkgs.runCommand "neogeo-extracted-roms"
      {
        nativeBuildInputs = [ pkgs.python3 ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        cp -r ${pkgs.neogeo-rom-extractor}/share/neogeo-rom-extractor extractor
        chmod -R u+w extractor

        mkdir -p "METAL SLUG" "METAL SLUG 2" "METAL SLUG 3" "Twinkle Star Sprites"
        cp -r ${metalSlug}/. "METAL SLUG"/
        cp -r ${metalSlug2}/. "METAL SLUG 2"/
        cp -r ${metalSlug3}/. "METAL SLUG 3"/
        cp -r ${twinkleStarSprites}/. "Twinkle Star Sprites"/

        (cd extractor && python3 neogeo_extractor.py --all)

        mkdir -p $out
        cp -r extractor/extracted_neogeo_games/. $out/
      '';

  # Extractor nests output under per-title subfolders with unstable names --
  # find by fixed zip name instead, once for all 4 game ROMs + neogeo BIOS
  resolvedZips = pkgs.runCommand "neogeo-resolved-zips" { } ''
    mkdir -p $out
    find ${extracted} \( ${
      lib.concatMapStringsSep " -o " (n: "-name ${lib.escapeShellArg n}") [
        "mslug.zip"
        "mslug2.zip"
        "mslug3.zip"
        "twinspri.zip"
        "neogeo.zip"
      ]
    } \) -type f -exec cp -n -t $out {} +
  '';

  extractedZip = name: resolvedZips |> getFile "${name}.zip";

  biosDir = pkgs.runCommand "neogeo-bios-dir" { } ''
    mkdir -p $out
    cp ${resolvedZips}/neogeo.zip $out/neogeo.zip
  '';
in
lib.mkIf config.games.emulation.enable {
  games.emulation.arcade.neogeoBios = biosDir;

  programs.steam.games = {
    METAL_SLUG = mkNeoGeo {
      name = "Metal Slug";
      romset = extractedZip "mslug";
      shortname = "mslug";
    };
    METAL_SLUG_2 = mkNeoGeo {
      name = "Metal Slug 2";
      romset = extractedZip "mslug2";
      shortname = "mslug2";
    };
    METAL_SLUG_3 = mkNeoGeo {
      name = "Metal Slug 3";
      romset = extractedZip "mslug3";
      shortname = "mslug3";
    };
    TWINKLE_STAR_SPRITES = mkNeoGeo {
      name = "Twinkle Star Sprites";
      romset = extractedZip "twinspri";
      shortname = "twinspri";
    };

    # Owned, but outside neogeo-rom-extractor's coverage, no other extractor found:
    #   Baseball Stars 2 (appId 366230)
    #   Shock Troopers (appId 366270)
  };
}
