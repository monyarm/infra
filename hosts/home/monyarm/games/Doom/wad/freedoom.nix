{
  config,
  lib,
  pkgs,
  getFile,
  fetchGitTree,
  mkDoom,
  sources,
  ...
}:
let
  # Blasphemer and Lastermaul both build with deutex/python3 from a Makefile
  # in essentially the same way (Lastermaul's build is itself derived from
  # Blasphemer's); only the source and the built wad's path differ. `wad` is
  # the build-tree-relative path to the single wad the Makefile produces that
  # we care about; its basename becomes the derivation name.
  mkDeutexWad =
    {
      src,
      wad,
      extraNativeBuildInputs ? [ ],
      postPatch ? "",
    }:
    pkgs.stdenvNoCC.mkDerivation {
      name = builtins.baseNameOf wad;
      inherit src postPatch;
      nativeBuildInputs = [
        pkgs.python3
        pkgs.deutex
      ]
      ++ extraNativeBuildInputs;
      # The build (not just the final $out) invokes helper scripts with
      # `#!/usr/bin/env python3` shebangs; stdenv's automatic patchShebangs
      # only runs on $out during fixupPhase, which is too late for these.
      preBuild = "patchShebangs .";
      installPhase = "cp ${wad} $out";
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";
    };

  blasphemer = mkDeutexWad {
    src = fetchGitTree sources.wad.blasphemer;
    wad = "blasphem.wad";
    postPatch = ''
      substituteInPlace Makefile --replace-fail "python blasphemer_sndcurve.py" "python3 blasphemer_sndcurve.py"
    '';
  };

  lastermaul = mkDeutexWad {
    src = fetchGitTree sources.wad.lastermaul;
    wad = "wads/lastermaul.wad";
    extraNativeBuildInputs = [ pkgs.git ];
  };
in
lib.mkIf config.games.doom.enable {
  games.doom.wads = {
    freedoom1 = pkgs.freedoom |> getFile "share/games/doom/freedoom1.wad";
    freedoom2 = pkgs.freedoom |> getFile "share/games/doom/freedoom2.wad";
    inherit blasphemer lastermaul;
  };

  programs.steam.games = with config.games.doom.wads; {
    freedoom1 = mkDoom {
      name = "Freedoom: Phase 1";
      iwad = freedoom1;
      images = {
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/c317278e95b743db5c6c6e163ab789d6.png";
          sha256 = "sha256-lfX8z9oj9O0ySILyitlEP3aTS68ouc4r5uxPlxBkndk=";
        };
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/8f2ba96517924ee3d08ec132c4bad818.ico";
          sha256 = "sha256-1QQ7PPS94IcftCyQrnoQRGjSeRHKbDtfn5R3E6en35w=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/1ba44f862155cb3a16549817de6efb35.png";
          sha256 = "sha256-hMZ8lWijtSNbYeX6YQ5FYv92Lo4Q/fSmTRQUaJfsxZI=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/2708bd65cf7109a42c039a784a0b1467.png";
          sha256 = "sha256-/46eLySLZNIHZVxawPyTaKHp9OjCzoxC9HaeByhcGyU=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/92bcb330b77c9e817c8e668f09ecd1b0.png";
          sha256 = "sha256-YRCLoCDBwVDPsHWFioG8zuENBNh1vK6YGFq0q+zz9D0=";
        };
      };
    };
    freedoom2 = mkDoom {
      name = "Freedoom: Phase 2";
      iwad = freedoom2;
      images = {
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/61aa251123372588f96122e431c771ea.png";
          sha256 = "sha256-jRpm1+CPW9Raj9BvP1BeAR3/H0vaKv1ANsGWSQWtFhc=";
        };
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/07662abf6d1635f05215d0614a1b6329.ico";
          sha256 = "sha256-1QQ7PPS94IcftCyQrnoQRGjSeRHKbDtfn5R3E6en35w=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/b8923b6bd6f03ac5e92fcb17ffd6d300.png";
          sha256 = "sha256-H/0kz832r4jhv83duM1do5UTy4UoQP2nmMkwJVBiQSY=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/0e69d3399b4a6f0293468fafc3324cdb.png";
          sha256 = "sha256-6J7L9GrRDJsCYFA4X57pGRDvdngW4n2Pko1GIi91Wl8=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/d3c17f9e7b43c173e2251b1a0ac6122c.png";
          sha256 = "sha256-rBetOPLjiXPAXmlcJM0GJqPUNt0MCdOUvL6it981Wwk=";
        };
      };
    };
    Blasphemer = mkDoom {
      name = "Blasphemer";
      iwad = blasphemer;
      images = {
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/7e8145ab66f342d033d1fec9574949bf.png";
          sha256 = "sha256-SlvJif9cW97INNF9jDUTGfRjSy0ayCf4VuDFpAAqyis=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/c30423e205b1cd1f2f25b010c3f6656d.jpg";
          sha256 = "sha256-bnJv1Vwkr/bVV0Gfxf+cGOvPJwj5jBuaehCZ50ePbuc=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/0e25859269a4e8679004d105aa4f6c71.jpg";
          sha256 = "sha256-mgxPk7AxiA+hud4fHAvDCdB+oLzXAs5OLVgXtTJwhyc=";
        };
        wide = "${./art/wide/blasphemer.png}";
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/03b5f76384df11479a886380ad85180c.png";
          sha256 = "sha256-qyKWnrD2t2NS3Sg1IJ9ZeN2A8NyYaa12wY9FoFm3jRY=";
        };
      };
    };
    Lastermaul = mkDoom {
      name = "Lastermaul";
      iwad = lastermaul;
    };
  };
}
