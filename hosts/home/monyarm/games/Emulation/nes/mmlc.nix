{
  config,
  lib,
  pkgs,
  fetchSteam,
  getFile,
  splitFiles,
  mkRom,
  patchFile,
  fetchGDrive,
  sources,
  ...
}:
let
  # roms baked inside Proteus.exe; game-extraction-toolbox extracts them
  MMLC = fetchSteam {
    filelist = [ "Proteus.exe" ];
    appId = 363440;
    depotId = 363441;
    manifestId = 1471104847962813070;
    sha256 = "sha256-S5FegdOGa6ugR2LJ0awdeO9Tii1Itg19k1jvg2MRjWQ=";
  };

  mmlcExtracted =
    pkgs.runCommand "game-extraction-toolbox-mmlc-roms"
      {
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        mkdir -p $out/extracted
        cp "${MMLC}/Proteus.exe" $out/Proteus.exe
        ${pkgs.game-extraction-toolbox}/bin/gextoolbox tasks extract \
          --srcdir "$out" \
          --destdir "$out/extracted" \
          --task mmlc1
        cp "$out"/extracted/*.nes $out/
        rm -rf "$out/extracted" "$out/Proteus.exe"
      '';

  # extractor's own naming: game 1 has space before paren, 2-6 don't
  mmlcRomName = n: if n == 1 then "megaman.nes" else "megaman${toString n}.nes";

  mmlcRoms = lib.listToAttrs (
    lib.zipListsWith lib.nameValuePair
      [ "megaMan1" "megaMan2" "megaMan3" "megaMan4" "megaMan5" "megaMan6" ]
      (
        splitFiles (map mmlcRomName [
          1
          2
          3
          4
          5
          6
        ]) mmlcExtracted
      )
  );

  mm3ImprovementPatch =
    fetchGDrive sources.patch.mm3improvement |> getFile "Megaman3 Improvement.ips";

  patchedMmlcRoms = {
    megaMan3 = mmlcRoms.megaMan3 |> patchFile config.games.emulation.patches.megaMan3Restore;
  };
in
lib.mkIf config.games.emulation.enable {
  games.emulation.roms = {
    inherit (mmlcRoms) megaMan1;
    inherit (mmlcRoms) megaMan2;
    inherit (patchedMmlcRoms) megaMan3;
    inherit (mmlcRoms) megaMan4;
    inherit (mmlcRoms) megaMan5;
    inherit (mmlcRoms) megaMan6;
  };

  games.emulation.patches = {
    megaMan3Restore = ./patches/megaman3-restoration.bps;
    mm3Improvement = mm3ImprovementPatch;
  };

  programs.steam.games =
    with config.games.emulation.roms;
    with config.games.emulation.patches;
    {
      MEGA_MAN_1 = mkRom {
        name = "Mega Man";
        rom = megaMan1;
        system = "nes";
        images = {
          icon = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/icon/edb518e0388521905d2302d973250478.png";
            sha256 = "sha256-GLfNy7B4WQ+UXqJ7LRO3fbnh4SegIMFVXlawA9Ig8FE=";
          };
          hero = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/hero/9acadc238d6036baef4b9ea50b8073de.png";
            sha256 = "sha256-7BauZ5PT8MpldT8nlhPkbe04qfRw0e3RWw0ZyC/yP2E=";
          };
          logo = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/logo/e24384b7369e4c6a298a78540d40934c.png";
            sha256 = "sha256-qccxo7VgT9p4Q2pgXdb6OT5oVMjSQ6L/OFQrGF4hScQ=";
          };
          grid = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/20f16dbde9f389fb902074b9a48881a3.png";
            sha256 = "sha256-iboycaPjUje7OncQXom1U0QLNIZcReQpd/f0VHtPZXQ=";
          };
          wide = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/f8bd0d04f5c94f491f4a422b4e6ad4ba.png";
            sha256 = "sha256-xShPJyqSAQLOBfDazwf/uotPko6ivAu/uXTun2kFVdk=";
          };
        };
      };
      MEGA_MAN_2 = mkRom {
        name = "Mega Man 2";
        rom = megaMan2;
        system = "nes";
        images = {
          icon = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/icon/bc4cf560a9a3cdedc711f36c1eb6dc24.png";
            sha256 = "sha256-vBQvmRhVX9H/cYiIW9lHb+4nUV9/m4zPG8+y8oAGZ90=";
          };
          grid = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/16266c6156a9fda5bbd9ea9a566042bd.png";
            sha256 = "sha256-/gpRaZtTZDwdszsCtCU2vHnPNAlNiUvJiVgcwqCclH8=";
          };
          wide = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/216c7a1fad5dc4b1a2be2df9820337af.png";
            sha256 = "sha256-ag9sQFS4QE0bYGBB2toougLaLtN3XR9Q6KKWjlhXoPw=";
          };
          logo = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/logo/1d47a22cf09ca6de619b7623f90b40b5.png";
            sha256 = "sha256-Fss41fwkmigY5hO+G7juuj9uxesIk58rlNfvpM5AaIA=";
          };
          hero = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/hero/958cf76990e9ccf502442ead34e224b0.png";
            sha256 = "sha256-JQdKmtgoiX72jPbcbYM9tlMISdYHzo6Kz5/lTFAQU3c=";
          };
        };
      };
      MEGA_MAN_3 = mkRom {
        name = "Mega Man 3";
        rom = megaMan3;
        system = "nes";
        patch = [ mm3Improvement ];
        images = {
          icon = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/icon/d17a292a4c5696d1af8cd263b0bfa3f5.png";
            sha256 = "sha256-sHMOI+mKaFE9tO1ntyePWh+GscuK7hqNRJL+4kKoU8k=";
          };
          hero = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/hero/93100e77ca06add19c1893ec36ff1dd8.png";
            sha256 = "sha256-2a0zonaTiQ9EkpACJdrsz1nJEctgtR9zB/AhmeWo8ok=";
          };
          grid = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/f2a37016e4540df77ef9a16d0df282c8.png";
            sha256 = "sha256-Pj2sfqlXWrjsM0EXVe7de1TJleDyWD2yM0ZebC0haew=";
          };
          logo = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/logo/bcfa8a783aaf938cdef361634d5f9289.png";
            sha256 = "sha256-dLvLqARPLC2JHxIHj6as+mtq0FSYzA1NzmUsykSTtr0=";
          };
          wide = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/90b48f1349008108b07d293210fec411.png";
            sha256 = "sha256-8aIhwlQlgudGnGhXabwEx4s2ngBhLlY1IsBq6K5My8k=";
          };
        };
      };
      MEGA_MAN_4 = mkRom {
        name = "Mega Man 4";
        rom = megaMan4;
        system = "nes";
        images = {
          icon = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/icon/60b5b22c8caf9f96a50b9de57355be83.png";
            sha256 = "sha256-lcGCu9naxqpAmSX3HJPhxmcLEHNYbpEDBypNqEDEiMA=";
          };
          hero = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/hero/89a5499ee65c1b2533ab100e11fa2e54.png";
            sha256 = "sha256-RjY1R9F36+ZHsFCCRxlKIRQqqAcEZKtNluAZ9S9u9yU=";
          };
          grid = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/f98e878a46c6cf03660a2ee4ed9925b4.png";
            sha256 = "sha256-kJnBGiLlY2opuNvJ7wKCprOMSm4Ribi31QSzNzvRRbQ=";
          };
          logo = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/logo/89d29b60192d1138df19ad3521fe5a29.png";
            sha256 = "sha256-TeCSDfGJRPzKiRWADUa4ZVWdeogapqcsggLZz4xFirI=";
          };
          wide = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/61d9bc3d1e7f56bd7c4e71a11581d43b.png";
            sha256 = "sha256-ovYjlDf6YCrCjLrbg+WJYZj41kVsCwLz/IPsWm0gHW4=";
          };
        };
      };
      MEGA_MAN_5 = mkRom {
        name = "Mega Man 5";
        rom = megaMan5;
        system = "nes";
        images = {
          icon = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/icon/6c1941a1c1c95552c36a9785cacf865f.png";
            sha256 = "sha256-SSgiihiseIqMB8XDsY2NgwFmc7qbGxZziPHmTNlb/Dg=";
          };
          hero = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/hero/21eab4e033c379d31c61a4e64419028c.png";
            sha256 = "sha256-Cm/2QfIMemxu+a9Uc0Axc76Hzxyr2B9c8GlGNrSgi68=";
          };
          grid = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/d875f401fc66d7fe96649715edda117a.png";
            sha256 = "sha256-bpOV4FMs7mTD5O+qsp3HbISqI2b/y6ZLpk4kIhp0hkE=";
          };
          logo = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/logo/97e907221af01aec5f7adcdc49d72b39.png";
            sha256 = "sha256-EQsfsO7gyZv7IakPxZ09E65fY+Bm5Tje31rK9uf1gVE=";
          };
          wide = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/e6e2a0dc8cd78a041463c07171c460b3.png";
            sha256 = "sha256-5MGpDOOyIta21XI76NKvgeyK2pFn9aQm6dhadGj9tuI=";
          };
        };
      };
      MEGA_MAN_6 = mkRom {
        name = "Mega Man 6";
        rom = megaMan6;
        system = "nes";
        images = {
          icon = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/icon/db0bf3f62afd5db8507a45341c7f48fa.png";
            sha256 = "sha256-G8AXpLSUzHwBQMy11Xuvq62I5uYAPPIVLWov7SuAL94=";
          };
          hero = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/hero/872b9409d89a588af072c3c414022400.png";
            sha256 = "sha256-ElB/+lQ6K24sYI/2uMKifPQ2CMgdA66UeMmpLLbl6r4=";
          };
          grid = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/a0b8baaadb45895ea51d461f7d9670ff.png";
            sha256 = "sha256-gVY8TEdraWFmv6/u2IOiTDIZVyL2zmHxwN/5L50EQ0E=";
          };
          logo = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/logo/81dae96e79ec97a41a71b87f6abd8968.png";
            sha256 = "sha256-AbxCjtWo7qHr70HZfXG8LCp0d2FyojAsmrPBe9GB2Hw=";
          };
          wide = pkgs.fetchurl {
            url = "https://cdn2.steamgriddb.com/grid/8852c526a9fc69b287837b28ca90fb2f.png";
            sha256 = "sha256-tEB/tUhei20m8jLpZx5UAUFBZTH/B8XPqKQvtnn7DVw=";
          };
        };
      };

      MEGA_MAN_LEGACY_COLLECTION = {
        disabled = true;
        name = "Mega Man Legacy Collection";
        steamAppId = 363440;
      };
    };
}
