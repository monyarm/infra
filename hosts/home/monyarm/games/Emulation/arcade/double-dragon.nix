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
    };
    DOUBLE_DRAGON_2 = mkArcade {
      name = "Double Dragon II: The Revenge";
      romset = extractedZip "ddragon2";
      shortname = "ddragon2";
    };
    DOUBLE_DRAGON_3 = mkArcade {
      name = "Double Dragon 3: The Rosetta Stone";
      romset = extractedZip "ddragon3";
      shortname = "ddragon3";
    };
  };
}
