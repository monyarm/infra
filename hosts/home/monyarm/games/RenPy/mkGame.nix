{
  lib,
  pkgs,
  ...
}:
let
  # config.console = True only (not config.developer) -- Shift+O console
  # access without pulling in the broader dev-reload/debug UI.
  cheatsRpy = builtins.toFile "cheats.rpy" ''
    init python:
        config.console = True
  '';

  # name -> mkRenPyGame's own `name`; renpy -> engine override point, default
  # renpyMinimal (8.5, Python 3). mods: list of drvs whose top-level entries
  # get symlinked into game/ (or game/${modDir} if set), before compiling --
  # so mod .rpy overrides get compiled alongside the game's own scripts.
  mkRenPyGame =
    {
      name,
      src,
      renpy ? pkgs.renpyMinimal,
      mods ? [ ],
      modDir ? null,
      postPatch ? "",
      ...
    }@args:
    let
      modTarget = "game" + lib.optionalString (modDir != null) "/${modDir}";

      game = pkgs.stdenv.mkDerivation {
        pname = name;
        version = "0";
        inherit src postPatch;
        dontConfigure = true;
        nativeBuildInputs = [ renpy ];

        buildPhase = ''
          runHook preBuild

          export HOME="$TMPDIR/home"
          mkdir -p "$HOME"

          mkdir -p "${modTarget}"
          ${lib.concatMapStringsSep "\n" (m: ''
            for f in ${m}/*; do
              ln -s "$f" "${modTarget}/$(basename "$f")"
            done
          '') mods}

          cp ${cheatsRpy} game/cheats.rpy

          renpy . compile

          find game -type f -name '*.rpy' -delete

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          mkdir -p $out
          cp -r game $out/game
          runHook postInstall
        '';

        __contentAddressed = true;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      };
    in
    (lib.removeAttrs args [
      "name"
      "src"
      "renpy"
      "mods"
      "modDir"
      "postPatch"
    ])
    // {
      inherit renpy game;
    };
in
{
  inherit mkRenPyGame;
}
