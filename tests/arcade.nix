{ pkgs }:

let
  inherit (pkgs) lib;
  arcadeSource = builtins.readFile ../hosts/home/monyarm/games/Emulation/arcade/default.nix;
  bios = pkgs.runCommand "arcade-test-bios" { } "mkdir -p $out; touch $out/neogeo.zip";
  biosPath = builtins.unsafeDiscardStringContext (toString bios);
  realAddChecks = (import ../lib/misc.nix { inherit lib; }).addChecks;
  addChecks =
    checks: drv:
    let
      checked = realAddChecks checks drv;
    in
    checked.overrideAttrs (_: {
      postInstall = ''
        printf '%s' ${lib.escapeShellArg checked.checkPhase} > $out/arcade-check-phase
      '';
    });
  compressRom =
    rom:
    pkgs.runCommand "arcade-test-compressed-rom" { } ''
      mkdir -p $out
      cp ${rom} $out/compressed-rom.zip
    '';
  mame = pkgs.writeShellScriptBin "mame" ''
    test "$1" = -rompath
    case ":$2:" in
      *":${biosPath}:"*) ;;
      *) echo "incomplete rompath: $2" >&2; exit 1 ;;
    esac
    test "$3" = -video
    test "$4" = none
    test "$5" = -sound
    test "$6" = none
    test "$7" = -bench
    test "$8" = 10
    if test "''${MAME_FAIL:-0}" = 1; then
      exit 7
    fi
  '';
  arcade = import ../hosts/home/monyarm/games/Emulation/arcade/default.nix {
    inherit lib;
    pkgs = pkgs // {
      inherit mame;
    };
    config.games.emulation.arcade.neogeoBios = bios;
    inherit compressRom addChecks;
    autoImport = _: [ ];
  };
  mkArcade = arcade.config._module.args.mkArcade;
  rom = pkgs.runCommand "arcade-test-rom.zip" { } "printf test > $out";
  game = mkArcade {
    name = "Arcade check";
    romset = rom;
    shortname = "arcadetst";
    extraRomPaths = [ bios ];
  };
  rompath = lib.elemAt game.launcher.args 1;
  romDir = lib.head (lib.splitString ":" rompath);
in
assert lib.hasInfix "if \${pkgs.coreutils}/bin/timeout" arcadeSource;
assert lib.hasInfix "report FAIL smoke" arcadeSource;
assert game.launcher.package == mame;
assert game.game == "arcadetst";
assert rompath == "${romDir}:${biosPath}";
pkgs.runCommand "test-arcade-integration" { } ''
  test -L ${romDir}/arcadetst.zip
  test -e "$(readlink ${romDir}/arcadetst.zip)"
  test -e "$(readlink ${romDir}/arcadetst.zip)/compressed-rom.zip"

  set +e
  export TMPDIR="$PWD/failing-tmp"
  mkdir -p "$TMPDIR"
  MAME_FAIL=1 ${pkgs.bash}/bin/bash -c "$(cat "$(readlink ${romDir}/arcadetst.zip)/arcade-check-phase")"
  status=$?
  test "$status" -ne 0
  grep -F "smoke:smoke | FAIL" "$TMPDIR/add-checks-summary"

  touch $out
''
