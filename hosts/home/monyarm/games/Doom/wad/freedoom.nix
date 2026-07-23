{
  config,
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
{
  games.doom.wads = {
    freedoom1 = pkgs.freedoom |> getFile "share/games/doom/freedoom1.wad";
    freedoom2 = pkgs.freedoom |> getFile "share/games/doom/freedoom2.wad";
    inherit blasphemer lastermaul;
  };

  programs.steam.games = with config.games.doom.wads; {
    freedoom1 = mkDoom {
      name = "Freeomd: Phase 1";
      iwad = freedoom1;
    };
    freedoom2 = mkDoom {
      name = "Freeomd: Phase 2";
      iwad = freedoom2;
    };
    Blasphemer = mkDoom {
      name = "Blasphemer";
      iwad = blasphemer;
    };
    Lastermaul = mkDoom {
      name = "Lastermaul";
      iwad = lastermaul;
    };
  };
}
