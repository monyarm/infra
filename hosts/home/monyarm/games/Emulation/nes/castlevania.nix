{
  config,
  lib,
  pkgs,
  getFile,
  mkRom,
  patchFile,
  fetchRomhacking,
  sources,
  ...
}:
let
  inherit (config.games.emulation) marchive;

  cv3EnPatch = fetchRomhacking sources.patch.cv3 |> getFile "Akuden - Logotrans (New Alucard) v8.ips";
  castlevania3Clean =
    marchive.castlevaniaAnniversary
    |> getFile "famicom_03_AkumajouDensetsu.nes"
    |> patchFile config.games.emulation.patches.castlevania3Restore;

  # Pre-filled SRAM: English translation uses more data than fits in NES ROM,
  # so extra data lives in SRAM. Emulator must load this as initial SRAM content.
  kidDraculaSav =
    pkgs.runCommand "kid-dracula.sav"
      {
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        awk '/m_sram_data = \[/{flag=1; next} /\];/{if(flag) exit} flag' \
          "${marchive.castlevaniaAnniversary}/073/script/title_standalone.nut" \
          | grep -o '0x[0-9a-fA-F][0-9a-fA-F]' | cut -c3-4 | tr -d '\n' \
          | ${pkgs.python3}/bin/python3 -c 'import sys, binascii; sys.stdout.buffer.write(binascii.unhexlify(sys.stdin.read()))' \
          > $out
      '';
in
lib.mkIf config.games.emulation.enable {
  games.emulation.roms = {
    castlevania1 = marchive.castlevaniaAnniversary |> getFile "nes_01_Castlevania.nes";
    castlevania2 = marchive.castlevaniaAnniversary |> getFile "nes_02_Castlevania2.nes";
    castlevania3 = marchive.castlevaniaAnniversary |> getFile "nes_02_Castlevania3.nes";
    kidDracula = marchive.castlevaniaAnniversary |> getFile "kid-dracula.nes";

    # regional variants, registered for enumeration only -- not launchable
    castlevania1Famicom = marchive.castlevaniaAnniversary |> getFile "famicom_01_AkumajouDracula.nes";
    castlevania3Famicom = marchive.castlevaniaAnniversary |> getFile "famicom_03_AkumajouDensetsu.nes";
    kidDraculaFamicom = marchive.castlevaniaAnniversary |> getFile "famicom_04_BokuDraculakun.nes";
  };

  games.emulation.patches = {
    castlevania3Restore = ./patches/castlevania3-restoration.bps;
    castlevania3English = cv3EnPatch;
  };

  programs.steam.games =
    with config.games.emulation.roms;
    with config.games.emulation.patches;
    {
      CASTLEVANIA = mkRom {
        name = "Castlevania";
        rom = castlevania1;
        system = "nes";
        images.icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/9426edcb04ba15a57df6d674f1c74db9.ico";
          sha256 = "sha256-bQV1F4IIUGn6BE/Ngmfw6iC4mltHdGFlyWSDDSD21Pw=";
        };
        images.wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/5c0aa5a8d01f40a1e8e951d4af173045.png";
          sha256 = "sha256-voS2GTuyBg5OfUJnMcNLjUI4qhz7WGLavW1IxhCw7BE=";
        };
        images.hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/8497c3b1d034ce7aaf059804b5c88db6.jpg";
          sha256 = "sha256-K8esUxsEmX94jjVxF5fRxjlxGjqhaFaAIv0q0PD8vck=";
        };
        images.logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/770c0e7e2af0db73409aa2431aa8f33e.png";
          sha256 = "sha256-D3IzO3/tPJWnczZ8wfNCZj39zlloVwjgq3OJ1VE0fkc=";
        };
        images.grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/af3f3aefaf93ea8364b3e2cb27b9594c.png";
          sha256 = "sha256-q2GfwTeMIZ1Fjq7DIOybqmdfgNZPmeAvt7JVYi5I7xM=";
        };
      };
      CASTLEVANIA_2 = mkRom {
        name = "Castlevania II: Simon's Quest";
        rom = castlevania2;
        system = "nes";
        images.icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/74c30a819b548dd7e64902a2cdaf918f.ico";
          sha256 = "sha256-H5hRLNOu0d+K+TMS1azyVTFgKaPu5kzbc+1tn0U7ZG8=";
        };
        images.hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/6c8cbece8eaf044a4c89ab7888b31ce7.png";
          sha256 = "sha256-HR+HXBLBsH8+i6vu1IiQ6LfURlTiiyAzwLpGF1SmYt4=";
        };
        images.logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/fc76150735dde1d2d860aeb77ee2009e.png";
          sha256 = "sha256-u+tze17jSL+a/vNp8AcMiOw7/GXt/MCvXmD0zct7a70=";
        };
        images.grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/f19556a9a0551ec0edfb56673b58688a.png";
          sha256 = "sha256-RVlrj8m4FePZ3Kea3La4nzcJI3izFDrq8hgb/BP3q/U=";
        };
        images.wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/325eaeac5bef34937cfdc1bd73034d17.png";
          sha256 = "sha256-B6RkkNsaA+y5ojW5ahSrvC8yyjYEXoRH+OV0Etew+34=";
        };
      };
      CASTLEVANIA_3 = mkRom {
        name = "Castlevania III: Dracula's Curse";
        rom = castlevania3Clean;
        system = "nes";
        patch = [ castlevania3English ];
        images.icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/cda1b587e20189043c782d7b53e63c59.ico";
          sha256 = "sha256-FD9u1iTbgGi5cBYq5M6Kytq3DBr9/2G9Pmfy92Mkws8=";
        };
        images.hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/24c386cd9c503780b1b219e9aa063136.jpg";
          sha256 = "sha256-IS3Rc4nPoc1Vnv1IIW5qlzSLVgLVdFA12ZCVTi6gzWU=";
        };
        images.logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/efb53b87d5f5286f29b7791ec36a34f8.png";
          sha256 = "sha256-Os3+JkTj8RzccpWhKtRUjcCR9FFQ0SJS2KUSFseMTZs=";
        };
        images.grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/b8452120100ecb4b0ee9eeb2a570fcd7.png";
          sha256 = "sha256-TsVdHvubry+BAPqn8Ki6+/T/lOgyWBPTaZaLGxaI8p4=";
        };
        images.wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/f2b470353443e0fd595becdf7ee51558.png";
          sha256 = "sha256-FtgQRNcxRcpb7Eq51bgdlGr9x705YMfzv2bxkuj1CB4=";
        };
      };
      KID_DRACULA = mkRom {
        name = "Kid Dracula";
        rom = kidDracula;
        sidecar = kidDraculaSav;
        system = "nes";
        images.icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/ce0fe485aa8e6c875cf335571f064036.ico";
          sha256 = "sha256-5CrH7Sui+fRArQXMF9GvnfaQJoEFpFz4qWT4XF2fEWA=";
        };
        images.hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/30c0ebdb79f4fb7f85eae27f2534ea1e.png";
          sha256 = "sha256-ift0G/CRZeXhj05sto08lTFyFfiL7CYSs4lXObXtGGg=";
        };
        images.wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/7963f9aabe18ba7765537f5be83ef797.png";
          sha256 = "sha256-1/bw7jP0M4njlF9OBH2f5vbRSfl2bjRCNxpNPbyEIfM=";
        };
        images.grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/f2bfd6ce994f398490280959b4a3c864.png";
          sha256 = "sha256-bz490yP3jYgQp0oRWmPSDqj5YWcm6Red+Gw3vQlf6g4=";
        };
        images.logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/25e556733d02d0033cabcf5fa17cd35e.png";
          sha256 = "sha256-y+OVdDqMqlTOhlGjFELoDNdfs3F3Deln9+bsszcD4pY=";
        };
      };
    };
}
