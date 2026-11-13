{
  config,
  lib,
  pkgs,
  compressScummvmGame,
  ...
}:
let
  # Abandonware mirror: none of these are for sale anywhere (wiki.scummvm.org
  # "Available for Purchase: No"). Swap the source if one gets re-released.
  # archive.org publishes sha1 per file, so no prefetch round-trip is needed.
  fetchArchiveOrg =
    item: file: sha1:
    pkgs.fetchurl {
      url = "https://archive.org/download/${item}/${lib.escapeURL file}";
      inherit sha1;
    };

  extract =
    name: script:
    pkgs.runCommand name {
      nativeBuildInputs = [
        pkgs.unzip
        pkgs.p7zip
        pkgs.bchunk
      ];
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "recursive";
    } script;

  # Wiki "Required data files", DOS CD.
  discworld =
    extract "discworld" ''
      unzip -qC ${
        fetchArchiveOrg "msdos_Discworld_1995" "msdos_Discworld_1995.zip"
          "7a02c2bd42032f0c75bedf05cc7864ed48fac6af"
      } 'dw1/*.idx' 'dw1/*.gra' 'dw1/*.scn' 'dw1/*.smp' 'dw1/*.txt' \
        dw1/fat.opl dw1/midi.dat dw1/index dw1/sample.ad dw1/sample.opl || [ $? -eq 11 ]
      mv dw1 $out
    ''
    |> compressScummvmGame "tinsel";

  # Wiki "Required data files", DOS CD; ENGLISH{1,2}.* already renamed here.
  discworld2 =
    extract "discworld2" ''
      unzip -qC ${
        fetchArchiveOrg "msdos_Discworld_2_-_Missing_Presumed_1996"
          "Discworld_2_-_Missing_Presumed_1996.zip"
          "29a8c8191750944e8d1192a28c5e14892a14952d"
      } 'dw2/*.bmv' 'dw2/*.cdp' 'dw2/*.mus' 'dw2/*.scn' dw2/gdata dw2/hopper dw2/index \
        'dw2/english[12].*' dw2/dw2/sample.bnk -x 'dw2/cd/*'
      mv dw2/DW2/SAMPLE.BNK dw2/
      rm -rf dw2/DW2/CACHE
      rmdir dw2/DW2
      mv dw2 $out
    ''
    |> compressScummvmGame "tinsel";

  # Not listed on the wiki; detection keys on DATA/DUCKMAN.GAM.
  duckman =
    extract "duckman" ''
      7z x ${
        fetchArchiveOrg "duckman-game-cd"
          "Duckman - The Graphic Adventures of a Private Dick (1997)(Playmates Interactive Entertainment).iso"
          "9114a90c1205773a12c9e5f411baa2d4a3080a06"
      } DATA
      mv DATA $out
    ''
    |> compressScummvmGame "illusions";

  # Wiki "Windows 3CD": DATA_MTI/{MTPLAY32 (disc 1), VIDEO (disc 3), MTI*.MP?}.
  muppetTreasureIsland =
    extract "muppet-treasure-island" ''
      mkdir $out
      7z x ${
        fetchArchiveOrg "MuppetTreasureIslandPC" "MTI1.ISO" "d5b777e5bb9b1f982c96f18617f5457a778e80b7"
      } DATA_MTI/MTPLAY32 DATA_MTI/MTI1.MPL DATA_MTI/MTI2.MPX
      7z x ${
        fetchArchiveOrg "MuppetTreasureIslandPC" "MTI2.ISO" "2023c69188890b0053357342eb685166cc0c0512"
      } DATA_MTI/MTI3.MPX
      7z x ${
        fetchArchiveOrg "MuppetTreasureIslandPC" "MTI3.ISO" "2cdb03d6056e36e9552592c790f648d478bd9b2f"
      } DATA_MTI/MTI4.MPX DATA_MTI/VIDEO
      mv DATA_MTI/* $out/
    ''
    |> compressScummvmGame "mtropolis";

  # Wiki: PPTP.BRO, PPTP.EXE, PPTP.ORB. Redump raw bin, so bchunk to ISO first.
  passportToPeril =
    extract "passport-to-peril" ''
      unzip -q ${
        fetchArchiveOrg "ThePinkPantherPassportToPerilUSA" "Pink Panther, The - Passport to Peril (USA).zip"
          "d41f3adff3d7623e386c614fded890d020eb5c66"
      }
      bchunk *.bin *.cue peril
      mkdir $out
      7z e -o$out peril01.iso -ir'!PPTP.BRO' -ir'!PPTP.EXE' -ir'!PPTP.ORB'
    ''
    |> compressScummvmGame "pink";

  # Wiki: HPP.EXE, HPP.ORB. EXE (and BRO) live in INSTALL/ on the CD.
  hokusPokusPink =
    extract "hokus-pokus-pink" ''
      mkdir $out
      7z e -o$out ${
        fetchArchiveOrg "the-pink-panther-hokus-pokus-pink-cd-rom-1998" "Pokus.iso"
          "cca83a2cfdd24d9591df0b5ac5c017b8c1ccd2ff"
      } HPP.ORB INSTALL/HPP.EXE INSTALL/HPP.BRO
    ''
    |> compressScummvmGame "pink";
in
lib.mkIf config.games.scummvm.enable {
  games.scummvm.games = {
    discworld = {
      gameid = "dw";
      engineid = "tinsel";
      description = "Discworld";
      path = "${discworld}";
    };
    discworld2 = {
      gameid = "dw2";
      engineid = "tinsel";
      description = "Discworld II: Missing Presumed...!?";
      path = "${discworld2}";
    };
    duckman = {
      gameid = "duckman";
      engineid = "illusions";
      description = "Duckman: The Graphic Adventures of a Private Dick";
      path = "${duckman}";
    };
    muppetTreasureIsland = {
      gameid = "mti";
      engineid = "mtropolis";
      description = "Muppet Treasure Island";
      path = "${muppetTreasureIsland}";
    };
    peril = {
      gameid = "peril";
      engineid = "pink";
      description = "The Pink Panther: Passport to Peril";
      path = "${passportToPeril}";
    };
    pokus = {
      gameid = "pokus";
      engineid = "pink";
      description = "The Pink Panther: Hokus Pokus Pink";
      path = "${hokusPokusPink}";
    };
  };
}
