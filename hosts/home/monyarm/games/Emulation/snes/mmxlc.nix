{
  config,
  lib,
  pkgs,
  fetchSteam,
  getFile,
  splitFiles,
  mkRom,
  fetchRomhacking,
  sources,
  ...
}:
let
  # X1-X3 only; X4 is a native reimplementation, not a real ROM
  MMXLC = fetchSteam {
    filelist = [ "RXC1.exe" ];
    appId = 743890;
    depotId = 743891;
    manifestId = 1036283505936301385;
    sha256 = "sha256-3NDrYRIYe8RMskKckX5GVvO1cwBwI59vMA+8mgvUwnY=";
  };

  mmxlcExtracted =
    pkgs.runCommand "mmxlc-extracted-roms"
      {
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        mkdir -p $out
        cp "${MMXLC}/RXC1.exe" $out/RXC1.exe
        cd $out
        ${pkgs.mmxlc-rom-extractor}/bin/mmxlc-rom-extractor
        rm RXC1.exe
      '';

  mmxlcRoms = lib.listToAttrs (
    lib.zipListsWith lib.nameValuePair
      [ "megaManX1" "megaManX2" "megaManX3" "rockManX1" "rockManX2" "rockManX3" ]
      (
        splitFiles [
          "Mega Man X.sfc"
          "Mega Man X2.sfc"
          "Mega Man X3.sfc"
          "Rock Man X.sfc"
          "Rock Man X2.sfc"
          "Rock Man X3.sfc"
        ] mmxlcExtracted
      )
  );

  mmxCompletePatch =
    fetchRomhacking sources.patch.mmxcomplete
    |> getFile "Mega Man X Complete Edition Including Gameplay Changes.ips";

  mmx3FastromPatch =
    fetchRomhacking sources.patch.mmx3fastrom |> getFile "Megaman X3 - Fastrom v2.1.ips";

in
lib.mkIf config.games.emulation.enable {
  games.emulation.roms = {
    inherit (mmxlcRoms) megaManX1 megaManX2 megaManX3;

    # regional variants, registered for enumeration only -- not launchable
    inherit (mmxlcRoms) rockManX1 rockManX2 rockManX3;
  };

  games.emulation.patches = {
    mmxComplete = mmxCompletePatch;
    mmx3Fastrom = mmx3FastromPatch;
  };

  programs.steam.games =
    with config.games.emulation.roms;
    with config.games.emulation.patches;
    {
      MEGA_MAN_X1 = mkRom {
        name = "Mega Man X";
        rom = megaManX1;
        system = "snes";
        patch = [ mmxComplete ];
        images = {
          icon = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/icon/89b85f944790639e8d6d5096b1909082.png";
            sha256 = "sha256-lNFnmnEKMJuJsyeMeufLjwM0D1hFm1EnEcA5uoR29vI=";
          };
          hero = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/hero/87fb64db8a74fa38e6778aea4d9e0f6c.png";
            sha256 = "sha256-kGO4YxJTjb2wxgc3lrhkYvaOW9wDBoXFXXw8YSh05fc=";
          };
          grid = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/e24927b595bdddebb71671d11f76f067.png";
            sha256 = "sha256-doNMmw/Ff8sAPD/rBQtTawk8HVfqykP94vt5mnzqUow=";
          };
          wide = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/a3a505c6026819367f80ba29fc1bc060.png";
            sha256 = "sha256-D/AQgXItYEnlfjOTKuFr2GkqxOBT0iQwVq7qKRl2qxw=";
          };
          logo = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/logo/e2a23af417a2344fe3a23e652924091f.png";
            sha256 = "sha256-yYb8UAXbPM/GF0GWUieEPY9NLUP1g/DJqH19Cg1rvAM=";
          };
        };
      };
      MEGA_MAN_X2 = mkRom {
        name = "Mega Man X2";
        rom = megaManX2;
        system = "snes";
        images = {
          icon = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/icon/2d21fefd587c8429da8c2233d1d12346.png";
            sha256 = "sha256-Y+9A8imLDT1AIaNeRoHLyoBr2s71MoWASKCq7OYU6MY=";
          };
          hero = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/hero/ff36cea2000e8559754fb3dfd88aaf71.png";
            sha256 = "sha256-QLpfXF9tque+mWVtKOlRShJ9/MngwO/1rRhS2tfV7jY=";
          };
          grid = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/5fe3254ca9f7e2d49bd9a2c35c5dbe58.png";
            sha256 = "sha256-17spCrfYMi+2jyaOV9c92XMGgDUdb4JJuaJlBVwNWmA=";
          };
          wide = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/3e0523a44b459ee23c557fc44aeef161.png";
            sha256 = "sha256-yp+x21eBV5Ij//4QF70gL5/c/hlUcnP7qwM16eE46fc=";
          };
          logo = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/logo/e6fa05c07b144b6ff4d1fd1cd2bbb244.png";
            sha256 = "sha256-sJHG1RCCMlBkQWwPu/dwDbT1q5seZ9F5eEf7PT4rIEk=";
          };
        };
      };
      MEGA_MAN_X3 = mkRom {
        name = "Mega Man X3";
        rom = megaManX3;
        system = "snes";
        patch = [ mmx3Fastrom ];
        images = {
          icon = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/icon/9b279012cc9b02e28fb32e827355714f.png";
            sha256 = "sha256-r+MZa8YriMYy8o07PNl2FlO0LXvhbCPeRRwOBXgIA/8=";
          };
          hero = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/hero/d6f79574ce2d52937d75553a00b32c0b.png";
            sha256 = "sha256-uDxnknICcaWN5HIQaIebpOfzqjwAK0fBX/Kl5wyXdmo=";
          };
          grid = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/5efae0e101b4cd69f60057c3ac7e81d7.png";
            sha256 = "sha256-Fhd0spTkyIDeyVZWWNwO1cT8fb0eK47vjoQhavLmOJI=";
          };
          wide = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/f897f6cdf30170aafcb858cc71d10f60.png";
            sha256 = "sha256-sFX9baUWxaLqrnv56gSYq74uaVp3y4FCnpTLN45pjto=";
          };
          logo = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/logo/ed169960635ad981cb7b65edf84b3f8f.png";
            sha256 = "sha256-8Oho6TaLeVKNl8nLWzm2TGQ7M0m1GX/IVbmMqxJKS2Q=";
          };
        };
      };

      MEGA_MAN_X_LEGACY_COLLECTION = {
        disabled = true;
        name = "Mega Man X Legacy Collection";
        steamAppId = 743890;
      };
    };
}
