{
  config,
  lib,
  pkgs,
  fetchSteam,
  getFile,
  mkRom,
  ...
}:
let
  # Volume 1: exe1.dat .. exe3b.dat

  # Actually, let me use the depot downloader approach.
  # fetchSteam with filelist downloads only the listed files.
  bnV1 = fetchSteam {
    filelist = [
      "exe/data/exe1.dat"
      "exe/data/exe2j.dat"
      "exe/data/exe3.dat"
      "exe/data/exe3b.dat"
    ];
    appId = 1798010;
    depotId = 1798011;
    manifestId = 6583874429443952093;
    sha256 = "sha256-Z0uTsfT9p7LH2VqPE1diT6vtmgrQOwrjU+Tlwb4hrVE=";
  };

  bnV2 = fetchSteam {
    filelist = [
      "exe/data/exe4.dat"
      "exe/data/exe4b.dat"
      "exe/data/exe5.dat"
      "exe/data/exe5k.dat"
      "exe/data/exe6.dat"
      "exe/data/exe6f.dat"
    ];
    appId = 1798020;
    depotId = 1798021;
    manifestId = 1422642204280631133;
    sha256 = "sha256-RL6+vPlpU+x5jQ7HZ8oNWSyUQiNiih7ciPfpOBkeDKk=";
  };

  # Extract .srl files from .dat ZIPs and rename to .gba
  extractRom =
    name: datFile: srlFile:
    pkgs.runCommand "${name}.gba"
      {
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        ${pkgs.unzip}/bin/unzip -j "${datFile}" "${srlFile}" -d "$TMPDIR"
        mv "$TMPDIR/${builtins.baseNameOf srlFile}" "$out"
      '';

  # All 20 ROMs mapped from .dat files
  allRoms = {
    # Volume 1
    megaManBattleNetwork1 =
      extractRom "megaManBattleNetwork1" (getFile "exe/data/exe1.dat" bnV1)
        "exe1/rom_e.srl";
    megaManBattleNetwork1Jp =
      extractRom "megaManBattleNetwork1Jp" (getFile "exe/data/exe1.dat" bnV1)
        "exe1/rom.srl";
    megaManBattleNetwork2 =
      extractRom "megaManBattleNetwork2" (getFile "exe/data/exe2j.dat" bnV1)
        "exe2j/rom_e.srl";
    megaManBattleNetwork2Jp =
      extractRom "megaManBattleNetwork2Jp" (getFile "exe/data/exe2j.dat" bnV1)
        "exe2j/rom.srl";
    megaManBattleNetwork3White =
      extractRom "megaManBattleNetwork3White" (getFile "exe/data/exe3.dat" bnV1)
        "exe3/rom_e.srl";
    megaManBattleNetwork3WhiteJp =
      extractRom "megaManBattleNetwork3WhiteJp" (getFile "exe/data/exe3.dat" bnV1)
        "exe3/rom.srl";
    megaManBattleNetwork3Blue =
      extractRom "megaManBattleNetwork3Blue" (getFile "exe/data/exe3b.dat" bnV1)
        "exe3b/rom_b_e.srl";
    megaManBattleNetwork3BlueJp =
      extractRom "megaManBattleNetwork3BlueJp" (getFile "exe/data/exe3b.dat" bnV1)
        "exe3b/rom_b.srl";

    # Volume 2
    megaManBattleNetwork4RedSun =
      extractRom "megaManBattleNetwork4RedSun" (getFile "exe/data/exe4.dat" bnV2)
        "exe4/rom_e.srl";
    megaManBattleNetwork4RedSunJp =
      extractRom "megaManBattleNetwork4RedSunJp" (getFile "exe/data/exe4.dat" bnV2)
        "exe4/rom.srl";
    megaManBattleNetwork4BlueMoon =
      extractRom "megaManBattleNetwork4BlueMoon" (getFile "exe/data/exe4b.dat" bnV2)
        "exe4b/rom_b_e.srl";
    megaManBattleNetwork4BlueMoonJp =
      extractRom "megaManBattleNetwork4BlueMoonJp" (getFile "exe/data/exe4b.dat" bnV2)
        "exe4b/rom_b.srl";
    megaManBattleNetwork5ProtoMan =
      extractRom "megaManBattleNetwork5ProtoMan" (getFile "exe/data/exe5.dat" bnV2)
        "exe5/rom_e.srl";
    megaManBattleNetwork5ProtoManJp =
      extractRom "megaManBattleNetwork5ProtoManJp" (getFile "exe/data/exe5.dat" bnV2)
        "exe5/rom.srl";
    megaManBattleNetwork5Colonel =
      extractRom "megaManBattleNetwork5Colonel" (getFile "exe/data/exe5k.dat" bnV2)
        "exe5k/rom_k_e.srl";
    megaManBattleNetwork5ColonelJp =
      extractRom "megaManBattleNetwork5ColonelJp" (getFile "exe/data/exe5k.dat" bnV2)
        "exe5k/rom_k.srl";
    megaManBattleNetwork6Gregar =
      extractRom "megaManBattleNetwork6Gregar" (getFile "exe/data/exe6.dat" bnV2)
        "exe6/rom_e.srl";
    megaManBattleNetwork6GregarJp =
      extractRom "megaManBattleNetwork6GregarJp" (getFile "exe/data/exe6.dat" bnV2)
        "exe6/rom.srl";
    megaManBattleNetwork6Falzar =
      extractRom "megaManBattleNetwork6Falzar" (getFile "exe/data/exe6f.dat" bnV2)
        "exe6f/rom_f_e.srl";
    megaManBattleNetwork6FalzarJp =
      extractRom "megaManBattleNetwork6FalzarJp" (getFile "exe/data/exe6f.dat" bnV2)
        "exe6f/rom_f.srl";
  };
in
lib.mkIf config.games.emulation.enable {
  games.emulation.roms = {
    inherit (allRoms)
      megaManBattleNetwork1
      megaManBattleNetwork1Jp
      megaManBattleNetwork2
      megaManBattleNetwork2Jp
      megaManBattleNetwork3White
      megaManBattleNetwork3WhiteJp
      megaManBattleNetwork3Blue
      megaManBattleNetwork3BlueJp
      megaManBattleNetwork4RedSun
      megaManBattleNetwork4RedSunJp
      megaManBattleNetwork4BlueMoon
      megaManBattleNetwork4BlueMoonJp
      megaManBattleNetwork5ProtoMan
      megaManBattleNetwork5ProtoManJp
      megaManBattleNetwork5Colonel
      megaManBattleNetwork5ColonelJp
      megaManBattleNetwork6Gregar
      megaManBattleNetwork6GregarJp
      megaManBattleNetwork6Falzar
      megaManBattleNetwork6FalzarJp
      ;
  };

  programs.steam.games = with allRoms; {
    MEGA_MAN_BATTLE_NETWORK_1 = mkRom {
      name = "Mega Man Battle Network";
      rom = megaManBattleNetwork1;
      system = "gba";
    };
    MEGA_MAN_BATTLE_NETWORK_2 = mkRom {
      name = "Mega Man Battle Network 2";
      rom = megaManBattleNetwork2;
      system = "gba";
    };
    MEGA_MAN_BATTLE_NETWORK_3_WHITE = mkRom {
      name = "Mega Man Battle Network 3: White";
      rom = megaManBattleNetwork3White;
      system = "gba";
    };
    MEGA_MAN_BATTLE_NETWORK_3_BLUE = mkRom {
      name = "Mega Man Battle Network 3: Blue";
      rom = megaManBattleNetwork3Blue;
      system = "gba";
    };
    MEGA_MAN_BATTLE_NETWORK_4_RED_SUN = mkRom {
      name = "Mega Man Battle Network 4: Red Sun";
      rom = megaManBattleNetwork4RedSun;
      system = "gba";
    };
    MEGA_MAN_BATTLE_NETWORK_4_BLUE_MOON = mkRom {
      name = "Mega Man Battle Network 4: Blue Moon";
      rom = megaManBattleNetwork4BlueMoon;
      system = "gba";
    };
    MEGA_MAN_BATTLE_NETWORK_5_PROTO_MAN = mkRom {
      name = "Mega Man Battle Network 5: Team ProtoMan";
      rom = megaManBattleNetwork5ProtoMan;
      system = "gba";
    };
    MEGA_MAN_BATTLE_NETWORK_5_COLONEL = mkRom {
      name = "Mega Man Battle Network 5: Team Colonel";
      rom = megaManBattleNetwork5Colonel;
      system = "gba";
    };
    MEGA_MAN_BATTLE_NETWORK_6_GREGAR = mkRom {
      name = "Mega Man Battle Network 6: Cybeast Gregar";
      rom = megaManBattleNetwork6Gregar;
      system = "gba";
    };
    MEGA_MAN_BATTLE_NETWORK_6_FALZAR = mkRom {
      name = "Mega Man Battle Network 6: Cybeast Falzar";
      rom = megaManBattleNetwork6Falzar;
      system = "gba";
    };

    MEGA_MAN_BATTLE_NETWORK_LEGACY_COLLECTION = {
      disabled = true;
      name = "Mega Man Battle Network Legacy Collection";
      steamAppId = 1798010;
    };
    MEGA_MAN_BATTLE_NETWORK_LEGACY_COLLECTION_VOL2 = {
      disabled = true;
      name = "Mega Man Battle Network Legacy Collection Vol. 2";
      steamAppId = 1798020;
    };
  };
}
