{
  config,
  lib,
  pkgs,
  fetchSteam,
  getFile,
  mkRom,
  fetchRomhacking,
  sources,
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

  bn1OssPatch = fetchRomhacking sources.patch.bn1oss |> getFile "Operation_Patch_0.7.ips";

  bn2RevisionPatch =
    fetchRomhacking sources.patch.bn2revision |> getFile "MMBN2Revision/MMBN2Revision.ips";

  bn3RevisionPatch = fetchRomhacking sources.patch.bn3revision;
  bn3BlueRevisionPatchFile = bn3RevisionPatch |> getFile "MMBN3Revision/MMBN3Revision-Blue.ips";
  bn3WhiteRevisionPatchFile = bn3RevisionPatch |> getFile "MMBN3Revision/MMBN3Revision-White.ips";

  bn4RevisionPatch = fetchRomhacking sources.patch.bn4revision;
  bn4BlueMoonRevisionPatchFile =
    bn4RevisionPatch |> getFile "MMBN4Revision/MMBN4Revision-BlueMoon-PROG.ips";
  bn4RedSunRevisionPatchFile =
    bn4RevisionPatch |> getFile "MMBN4Revision/MMBN4Revision-RedSun-PROG.ips";

  patches = {
    bn1Operation = bn1OssPatch;
    bn2Revision = bn2RevisionPatch;
    bn3WhiteRevision = bn3WhiteRevisionPatchFile;
    bn3BlueRevision = bn3BlueRevisionPatchFile;
    bn4RedSunRevision = bn4RedSunRevisionPatchFile;
    bn4BlueMoonRevision = bn4BlueMoonRevisionPatchFile;
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

  games.emulation.patches = patches;

  programs.steam.games =
    with allRoms;
    with config.games.emulation.patches;
    {
      MEGA_MAN_BATTLE_NETWORK_1 = mkRom {
        name = "Mega Man Battle Network";
        rom = megaManBattleNetwork1;
        system = "gba";
        patch = [ bn1Operation ];
        images = {
          hero = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/hero/15978ec98cc7fb6d2b95cd397439f23a.png";
            sha256 = "sha256-AXn9OmvgUaL9ZVYg4o3NVlBN7Jm4xVcVDHHxbYm9UJU=";
          };
          wide = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/4a11d6352175e2c16fa7c264092942a0.png";
            sha256 = "sha256-u/N4uTMvpKv6O19/ip0jgEYH6Jhxiwq3IfLJIZ5teJs=";
          };
          logo = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/logo/7c792a8279211dece3b4df04719c818a.png";
            sha256 = "sha256-eUKK8me2xBzml9iQ09jETFnY1UPFIrSbkx91Z3ttuZg=";
          };
          icon = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/icon/6e69ebbfad976d4637bb4b39de261bf7.png";
            sha256 = "sha256-kbFb85N5iIzNRRvv+zGoMsywYOtnJFL9rBDL/ncRXuI=";
          };
          grid = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/c100c41536e6667b8deb75adf6527f97.png";
            sha256 = "sha256-4ZM4PfmBVMI2xcR9VQLowPd49xfjCseigsyh76xv8VY=";
          };
        };
      };
      MEGA_MAN_BATTLE_NETWORK_2 = mkRom {
        name = "Mega Man Battle Network 2";
        rom = megaManBattleNetwork2;
        system = "gba";
        patch = [ bn2Revision ];
        images = {
          hero = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/hero/8ed16b12adc574bb06ec2cb2f5479952.png";
            sha256 = "sha256-riVNQNJyihj/00nE96y93Dg7wF/FFLfMTeReenGkzCo=";
          };
          wide = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/b60acf1106e0499b33ccd862d8342e91.png";
            sha256 = "sha256-gYVyLIzH+6fQbfits/xo1H1EqSU0LixouzeOA+1gRi8=";
          };
          icon = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/icon/9e4775f046c2105d8e7d6655287a2f34.png";
            sha256 = "sha256-wiUPs5nQS8rTqa4HSVv+PGtOM3uXlfnzXcy0Nv7j7fU=";
          };
          logo = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/logo/ee0c1616bbc82804b2f4b635d4a055fb.png";
            sha256 = "sha256-9oeLghC/WFJMu7Q84zDSuwRmzHwiwFVfd9D4gZD3d5g=";
          };
          grid = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/44f2378f4b0651daf2cb4fa277e4695e.png";
            sha256 = "sha256-xUHzn4XlAzJY/S4AsvH11EFsxhyrEBjdXEbFYz5I22w=";
          };
        };
      };
      MEGA_MAN_BATTLE_NETWORK_3_WHITE = mkRom {
        name = "Mega Man Battle Network 3: White";
        rom = megaManBattleNetwork3White;
        system = "gba";
        patch = [ bn3WhiteRevision ];
        images = {
          icon = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/icon/e9018f56e41b4c27f0376d73aa5048b4.png";
            sha256 = "sha256-g7ldkV0s87rHAUb81Rwhfid9b2RbVgrU0fN3DjvB3PQ=";
          };
          grid = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/4224d324188134290d99f44a379e40f9.png";
            sha256 = "sha256-LQL6XcjSsUpJ82uQsrFKKdo1zytdjgITaJTMkUTdSqE=";
          };
          wide = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/7656582fcb9662d6d176bff7281cf50c.png";
            sha256 = "sha256-ZuvZP//r4vDRoRpNugz3RUgRhCcT2hdHJy80l2ulzBU=";
          };
          logo = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/logo/f7652e68e0da3f415d7a0cb66da9c510.png";
            sha256 = "sha256-eW/MxErBaubotAxj1lFSM6R3KQ3XZUtVcZX9Mr4IgOw=";
          };
          hero = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/hero/55b815e096cacb06e3e556d22e8d106c.png";
            sha256 = "sha256-ahWUJCRO8IX//p5mVapmtB9+fTJMcPyE5Rx5/MD7Qac=";
          };
        };
      };
      MEGA_MAN_BATTLE_NETWORK_3_BLUE = mkRom {
        name = "Mega Man Battle Network 3: Blue";
        rom = megaManBattleNetwork3Blue;
        system = "gba";
        patch = [ bn3BlueRevision ];
        images = {
          icon = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/icon/438e8e03fca213a74f5bd6b6f1bd403f.png";
            sha256 = "sha256-g7ldkV0s87rHAUb81Rwhfid9b2RbVgrU0fN3DjvB3PQ=";
          };
          logo = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/logo/64d4f6639c0f1569f2b3736cdc947a69.png";
            sha256 = "sha256-88WCLukP9IFsLufkJjv/FHZHUoJiKle+FAm9QFO+cDs=";
          };
          wide = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/8db305710d10a0b562cc12215cb207da.png";
            sha256 = "sha256-ZReKEsGroLfxSf3U28ef86P/OyKCYLxZvRxJ2SeMQxw=";
          };
          hero = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/hero/7fc67a493d49abe6d0500d56675f41b2.png";
            sha256 = "sha256-cJambZjwhHENzmzRci0bf1br1MPqsGB2h1IBOZoqKoQ=";
          };
          grid = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/b5e2c77e749f83619063552ea95c3bfa.png";
            sha256 = "sha256-EKjcnEjsIHUUGxiLUzFoxsY7R+YYuWbnLXflREEPMOk=";
          };
        };
      };
      MEGA_MAN_BATTLE_NETWORK_4_RED_SUN = mkRom {
        name = "Mega Man Battle Network 4: Red Sun";
        rom = megaManBattleNetwork4RedSun;
        system = "gba";
        patch = [ bn4RedSunRevision ];
        images = {
          icon = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/icon/3678815f853787f941687e1cbe1c90fd.png";
            sha256 = "sha256-v9dxJKMQ5u93qNes/Cj7CIQBFT6SKlJuRHHM15HBKy0=";
          };
          hero = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/hero/9c25dc28b94e5226f1983330dc421cec.png";
            sha256 = "sha256-3KsRPgdul3Mnzlk4tQSi8nkFnB4Vh6udTLSzrzWhc3M=";
          };
          grid = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/372516fe16e4bd193b86755a09648eac.png";
            sha256 = "sha256-xpQG8rTgIPcYCTcaK9V9m8sX+Q8o+8cuX5ws46Mzwuo=";
          };
          wide = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/dd9631b60b8a204dee2c930668380b4b.png";
            sha256 = "sha256-BCeKBzg5KxzlJBm9QBYOvAoqWFOD457A8Ab4cLFXxtk=";
          };
          logo = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/logo/cb03c49012a597f2dcd23bc978567b71.png";
            sha256 = "sha256-hiRq0GgHc053w9NR6X6mIhuLNeYm2hAxgwtcLSGUl7w=";
          };
        };
      };
      MEGA_MAN_BATTLE_NETWORK_4_BLUE_MOON = mkRom {
        name = "Mega Man Battle Network 4: Blue Moon";
        rom = megaManBattleNetwork4BlueMoon;
        system = "gba";
        patch = [ bn4BlueMoonRevision ];
        images = {
          icon = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/icon/3678815f853787f941687e1cbe1c90fd.png";
            sha256 = "sha256-v9dxJKMQ5u93qNes/Cj7CIQBFT6SKlJuRHHM15HBKy0=";
          };
          hero = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/hero/4c0303ffb193bd5e66078909a15268aa.png";
            sha256 = "sha256-Xmg+8oLVJS0tKrkaS2EiJhUOvJAVuCBZCQh+SoXCsqM=";
          };
          grid = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/b89fc71ee73d1d6ec09693a1844bf3a2.png";
            sha256 = "sha256-mwnzbFmyDkdo2S6CN7L2cgl4uxPxBnGrrYUcv0ZR38Q=";
          };
          wide = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/2229da808f1e22b82dd3bcd72992ede4.png";
            sha256 = "sha256-lyj0Y0yq+JIBspON6TjoDPPYUKVvkk6ZoQWAfIJ/Id0=";
          };
          logo = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/logo/e74381ceac0d5d783fe71c15bb24fb7e.png";
            sha256 = "sha256-J0N96njbCuGmhOutc1f6NimGimlTb8BH732g8mk+1lo=";
          };
        };
      };
      MEGA_MAN_BATTLE_NETWORK_5_PROTO_MAN = mkRom {
        name = "Mega Man Battle Network 5: Team ProtoMan";
        rom = megaManBattleNetwork5ProtoMan;
        system = "gba";
        images = {
          icon = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/icon/32aa5f339eb718e348e7a33c1749b2d3.png";
            sha256 = "sha256-qklZ3BQOdlK6nXaQSJTomWmKFPPu3/w4pQ/4zztBdqY=";
          };
          hero = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/hero/b689e747d1360e42e9dbb90fa68d9e83.png";
            sha256 = "sha256-5QUcloBylpE252lLmSftHxy0oyIDWn9/g3MIDnnPYRM=";
          };
          logo = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/logo/21b49d9441391d620b8ececd6a402dc7.png";
            sha256 = "sha256-DlXpvp1QdnUb2GnQHP7PkxPnxdiG39jKtviFsN5FvQM=";
          };
          grid = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/6a0ba661a871cc50a0e439bb719d8a9a.png";
            sha256 = "sha256-K2GT/ITsJC3l5/5ddx25MVd8JbytjDdf7B4ckERk364=";
          };
          wide = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/4621dad09a402d3bf6d5c38b33a97117.png";
            sha256 = "sha256-1ih4zGBkjps79BkzPbVPTfYvhoashVG8lpA3LrmRPy8=";
          };
        };
      };
      MEGA_MAN_BATTLE_NETWORK_5_COLONEL = mkRom {
        name = "Mega Man Battle Network 5: Team Colonel";
        rom = megaManBattleNetwork5Colonel;
        system = "gba";
        images = {
          icon = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/icon/59b8a68f5518805ff14961c896caddae.png";
            sha256 = "sha256-QAjqPLgCRK1HlCi/N2AnZr1PVf1oW/oF6xJXwWLSdqA=";
          };
          hero = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/hero/039b9f5c48fb1bbea76b82b43d43ea74.png";
            sha256 = "sha256-qltGjyn247fupnrY6rXAFWiJdg/DD8RcV64NueZpkhI=";
          };
          logo = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/logo/16eeeb491080ff779eefceb3565812db.png";
            sha256 = "sha256-mWo032PXjYPeiiDVc2FHMbSodmutMwaQwaFB9XMsrx8=";
          };
          grid = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/b0b72040288946060ea425d8a80f22d9.png";
            sha256 = "sha256-WqiJlcPFINrcaGjN0ZSrJvnMui9CwZSatYKbupZdJ/w=";
          };
          wide = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/391fdd5c8d4b9ac789db16caed3a2ebb.png";
            sha256 = "sha256-Uult+g8+u/ELnefTrZqAl1V3AMLGbw8F05uDY0KxNN8=";
          };
        };
      };
      MEGA_MAN_BATTLE_NETWORK_6_GREGAR = mkRom {
        name = "Mega Man Battle Network 6: Cybeast Gregar";
        rom = megaManBattleNetwork6Gregar;
        system = "gba";
        images = {
          icon = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/icon/ef4a492636371042079b30a947d7ad8a.png";
            sha256 = "sha256-W0zmZ5Zs0VnQKvGOyNntxrvSMJ59xNNUYq2S1ri33fs=";
          };
          hero = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/hero/dd397459f8f50e4cd7c5e9d77b8b19f1.jpg";
            sha256 = "sha256-i/L/Xr2uG7myCoBtshucJoYn8xaIkOGlBVdEKxTKeoo=";
          };
          logo = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/logo/b42a80c01d9b3bb5bb385d4fba81a0c5.png";
            sha256 = "sha256-TuwuczHFH/hlriPyXaf7+j65t+lnzpi+1eEhTpSZyzE=";
          };
          grid = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/93770d7c4fd32b3083adfb98e1ab381c.png";
            sha256 = "sha256-6ktYtoRC2/hPBVCD4RCVgyNuPblkPXH3MisnOLHzbog=";
          };
          wide = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/6ff4a876b8e82efe27008a2cb722dbc7.png";
            sha256 = "sha256-Q8+BtpBMNfyeZHl2dIPrIYxg4eATa75kEXlbRvsuQ8k=";
          };
        };
      };
      MEGA_MAN_BATTLE_NETWORK_6_FALZAR = mkRom {
        name = "Mega Man Battle Network 6: Cybeast Falzar";
        rom = megaManBattleNetwork6Falzar;
        system = "gba";
        images = {
          icon = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/icon/ef4a492636371042079b30a947d7ad8a.png";
            sha256 = "sha256-W0zmZ5Zs0VnQKvGOyNntxrvSMJ59xNNUYq2S1ri33fs=";
          };
          hero = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/hero/c45b876541ee45037b6ba8c7af1608ac.jpg";
            sha256 = "sha256-H/9Y2DeK0orXulxBpAa7htDuNTFjbuM4j+WqIfpn4Eg=";
          };
          logo = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/logo/d2e9d8ef0fc25b13066af5f3d20aa3de.png";
            sha256 = "sha256-LA8/GyzTnWs6LvwmJ3FCIZMoQ8eHDJLT9VsIQYOT6xc=";
          };
          grid = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/6404c1c8e70bd8994caf2014003bf0ae.png";
            sha256 = "sha256-GpkHXIIxC8ezHR6/I0wNhsofOXrFgcRNuFX1dpUyAkM=";
          };
          wide = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/0968bc8096656cf5a66c63b8562432b5.png";
            sha256 = "sha256-LttNnIFtM6MuBF//q4fshrbbPLKZLktuQz7f7rU8OJE=";
          };
        };
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
