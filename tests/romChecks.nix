{ pkgs }:

let
  romChecks = import ../hosts/home/monyarm/games/Emulation/emulators.nix { inherit pkgs; };
  romChecksSource = builtins.readFile ../hosts/home/monyarm/games/Emulation/emulators.nix;
  inherit (pkgs) lib;
  inherit ((import ../lib/misc.nix { inherit (pkgs) lib; })) addChecks;
  fixture = pkgs.runCommand "rom-checks-fixtures" { } ''
        mkdir "$out"
        OUT="$out" ${pkgs.python3}/bin/python <<'PY'
    import os
    from pathlib import Path

    out = Path(os.environ["OUT"])

    nes = bytearray(16 + 16 * 1024)
    nes[:4] = bytes.fromhex("4e45531a")
    nes[4] = 1
    (out / "nes").write_bytes(nes)

    nes2 = bytearray(nes)
    nes2[7] = 0x08
    nes2[8] = 0xA5
    (out / "nes2").write_bytes(nes2)

    reserved_version = bytearray(nes)
    reserved_version[7] = 0x0C
    (out / "nes-reserved-version").write_bytes(reserved_version)

    patched_nes = bytearray(nes)
    patched_nes[-1] = 0x42
    (out / "nes-patched").write_bytes(patched_nes)

    snes = bytearray(0x8000)
    snes[0x7fc0 : 0x7fc0 + 0x15] = b"TEST ROM".ljust(0x15, b" ")
    snes[0x7fc0 + 0x15] = 0x20
    snes[0x7fc0 + 0x3c] = 1
    (out / "snes").write_bytes(snes)
    (out / "snes-invalid").write_bytes(bytes(0x100))

    gba = bytearray(0xc0)
    gba[:4] = (0xea000000).to_bytes(4, "little")
    (out / "gba").write_bytes(gba)

    valid_gba = bytearray(0xc0)
    valid_gba[:4] = gba[:4]
    logo = bytes.fromhex(
        "24ffae51699aa2213d84820a84e409ad11248b98c0c00a24"
        + "8b98c0c00a24" * 22
    )
    valid_gba[4 : 4 + len(logo)] = logo
    valid_gba[0xa0 : 0xac] = b"VALID GBA".ljust(12, b" ")
    valid_gba[0xbd] = (-0x19 - sum(valid_gba[0xa0:0xbd])) & 0xff
    (out / "gba-valid").write_bytes(valid_gba)
    (out / "gba-invalid").write_bytes(bytes(0xc0))

    (out / "gamegear").write_bytes(bytes(0x8000))
    (out / "gamegear-invalid").write_bytes(bytes(0x100))

    genesis = bytearray(0x400)
    genesis[:4] = (0xffffff00).to_bytes(4, "big")
    genesis[4:8] = (0x200).to_bytes(4, "big")
    genesis[0x100:0x104] = b"SEGA"
    genesis[0x200:0x202] = bytes.fromhex("60fe")
    (out / "genesis").write_bytes(genesis)
    genesis_invalid = bytearray(genesis)
    genesis_invalid[4:8] = (0x100).to_bytes(4, "big")
    (out / "genesis-invalid").write_bytes(genesis_invalid)
    PY
        ${pkgs.flips}/bin/flips --create "$out/nes" "$out/nes-patched" "$out/valid.bps"
        ${pkgs.xdelta}/bin/xdelta3 -e -s "$out/nes" "$out/nes-patched" "$out/valid.xdelta"
        printf 'invalid BPS fixture\n' > "$out/invalid.bps"
        printf 'invalid xdelta fixture\n' > "$out/invalid.xdelta"
  '';
  validator = ../hosts/home/monyarm/games/Emulation/romChecks.py;
  validNes = "${pkgs.python3}/bin/python ${validator} nes ${fixture}/nes";
  validNes2 = "${pkgs.python3}/bin/python ${validator} nes ${fixture}/nes2";
  invalidNesVersion = "${pkgs.python3}/bin/python ${validator} nes ${fixture}/nes-reserved-version";
  validSnes = "${pkgs.python3}/bin/python ${validator} snes ${fixture}/snes";
  invalidSnes = "${pkgs.python3}/bin/python ${validator} snes ${fixture}/snes-invalid";
  validGba = "${pkgs.python3}/bin/python ${validator} gba ${fixture}/gba";
  validGbaHeader = "${pkgs.python3}/bin/python ${validator} gba ${fixture}/gba-valid";
  invalidGba = "${pkgs.python3}/bin/python ${validator} gba ${fixture}/gba-invalid";
  validGamegear = "${pkgs.python3}/bin/python ${validator} gamegear ${fixture}/gamegear";
  invalidGamegear = "${pkgs.python3}/bin/python ${validator} gamegear ${fixture}/gamegear-invalid";
  validGenesis = "${pkgs.python3}/bin/python ${validator} genesis ${fixture}/genesis";
  invalidGenesis = "${pkgs.python3}/bin/python ${validator} genesis ${fixture}/genesis-invalid";
  checked =
    addChecks
      {
        structure = romChecks.nes.structure {
          system = "nes";
          rom = "${fixture}/nes";
        };
        warning = romChecks.snes.structure {
          system = "snes";
          rom = "${fixture}/snes";
        };
        failedStructure = romChecks.gba.structure {
          system = "gba";
          rom = "${fixture}/gba-invalid";
        };
        continued = ''
          report PASS after-structure "later check ran"
        '';
      }
      (
        pkgs.runCommand "rom-checks-summary-input" {
          doCheck = false;
          phases = [ "installPhase" ];
        } "touch $out"
      );
  mesen = romChecks.nes.smoke { rom = "${fixture}/nes"; };
  mgba = romChecks.gba.smoke { rom = "${fixture}/gba-valid"; };
  blastem = romChecks.genesis.smoke { rom = "${fixture}/genesis"; };
  patch = romChecks.patchCommand {
    patch = "${fixture}/valid.bps";
    rom = "${fixture}/nes";
  };
  failedPatch = romChecks.patchCommand {
    patch = "${fixture}/invalid.bps";
    rom = "${fixture}/nes";
  };
  xdeltaPatch = romChecks.patchCommand {
    patch = "${fixture}/valid.xdelta";
    rom = "${fixture}/nes";
  };
  failedXdeltaPatch = romChecks.patchCommand {
    patch = "${fixture}/invalid.xdelta";
    rom = "${fixture}/nes";
  };
  runPatch = command: ''
    report() { printf '%s\n' "$*"; }
    ${command}
  '';
  runSmoke = name: command: ''
    {
      if ${pkgs.bash}/bin/bash -c ${lib.escapeShellArg command} > "${name}.out" 2>&1; then
        report PASS smoke "${name} exited 0"
      else
        status=$?
        report FAIL smoke "${name} exited $status"
        false
      fi
    } > "${name}-smoke.out" 2>&1
  '';
  passingSmoke = "true";
  failedSmoke = "false";
in
assert lib.hasInfix ''flips --apply ''${arg patch} \"$tmp\" \"$tmp.out\"'' romChecksSource;
assert lib.hasInfix ''xdelta3 -d -f -s ''${arg rom} ''${arg patch} \"$tmp.out\"'' romChecksSource;
assert lib.hasInfix "if \${apply}; then" romChecksSource;
assert lib.hasInfix "report FAIL patch" romChecksSource;
pkgs.runCommand "test-rom-checks" { } ''
  set +e
  contains() {
    case "$1" in
      *"$2"*) ;;
      *) return 1 ;;
    esac
  }
  require_contains() {
    contains "$1" "$2" || exit 1
  }
  require_grep() {
    grep -F "$1" "$2" || exit 1
  }
  report_records() {
    cat "$1"
  }
  report() {
    printf '%s\n' "$*"
  }
  ${validNes} > valid.out
  test "$?" -eq 0
  require_grep $'PASS\tmagic\t' valid.out
  require_grep $'PASS\tbounds\t' valid.out

  ${validNes2} > nes2.out
  test "$?" -eq 0
  require_grep $'PASS\tmapper\tmapper 1280, submapper 10, NES version 2' nes2.out

  if ${invalidNesVersion} > invalid-version.out; then
    exit 1
  fi
  require_grep $'FAIL\tmapper\t' invalid-version.out

  ${validSnes} > snes.out
  test "$?" -eq 0
  require_grep $'PASS\theader\t' snes.out
  require_grep $'PASS\tvectors\t' snes.out
  require_grep $'WARN\tchecksum\t' snes.out

  ${invalidSnes} > invalid-snes.out
  test "$?" -ne 0
  require_grep $'FAIL\theader\t' invalid-snes.out

   ${validGba} > gba.out
   test "$?" -eq 0
   require_grep $'WARN\tlogo\t' gba.out
   require_grep $'WARN\theader-checksum\t' gba.out

   ${validGbaHeader} > gba-valid.out
   test "$?" -eq 0
   require_grep $'PASS\tlogo\t' gba-valid.out
   require_grep $'PASS\theader-checksum\t' gba-valid.out

   ${invalidGba} > invalid-gba.out
   test "$?" -ne 0
   require_grep $'FAIL\treset-vector\t' invalid-gba.out

  ${validGamegear} > gamegear.out
  test "$?" -eq 0
  require_grep $'WARN\theader\t' gamegear.out

  ${invalidGamegear} > invalid-gamegear.out
  test "$?" -ne 0
  require_grep $'FAIL\tbounds\t' invalid-gamegear.out

  ${validGenesis} > genesis.out
  test "$?" -eq 0
  require_grep $'PASS\theader\t' genesis.out
  require_grep $'WARN\tchecksum\t' genesis.out

  ${invalidGenesis} > invalid-genesis.out
  test "$?" -ne 0
  require_grep $'FAIL\tvectors\t' invalid-genesis.out

  if ${pkgs.python3}/bin/python ${../hosts/home/monyarm/games/Emulation/romChecks.py} not-a-system ${fixture}/nes > unknown.out; then
    exit 1
  fi

  export TMPDIR="$PWD/summary-tmp"
  mkdir -p "$TMPDIR"
  ${pkgs.bash}/bin/bash -c ${pkgs.lib.escapeShellArg checked.checkPhase}
  test "$?" -ne 0
  grep -F "structure:magic | PASS" "$TMPDIR/add-checks-summary"
  grep -F "structure:bounds | PASS" "$TMPDIR/add-checks-summary"
  grep -F "warning:checksum | WARN" "$TMPDIR/add-checks-summary"
  grep -F "failedStructure:reset-vector | FAIL" "$TMPDIR/add-checks-summary"
  grep -F "failedStructure:logo | WARN" "$TMPDIR/add-checks-summary"
  grep -F "continued:after-structure | PASS" "$TMPDIR/add-checks-summary"

  ${runSmoke "passing" passingSmoke}
  test "$?" -eq 0
  require_grep "PASS smoke passing exited 0" passing-smoke.out
  ${runSmoke "failed" failedSmoke}
  test "$?" -ne 0
  cat failed-smoke.out
  require_grep "FAIL smoke failed exited" failed-smoke.out

  require_contains ${pkgs.lib.escapeShellArg mesen} "300"
  require_contains ${pkgs.lib.escapeShellArg mesen} "10s"
  require_contains ${pkgs.lib.escapeShellArg mesen} "addEventCallback"
  require_contains ${pkgs.lib.escapeShellArg mesen} "eventType.endFrame"
  require_contains ${pkgs.lib.escapeShellArg mesen} "emu.stop"
  require_contains ${pkgs.lib.escapeShellArg mgba} "300"
  require_contains ${pkgs.lib.escapeShellArg mgba} "10s"
  require_contains ${pkgs.lib.escapeShellArg blastem} "-b 300"
  require_contains ${pkgs.lib.escapeShellArg blastem} "10s"
  require_contains ${pkgs.lib.escapeShellArg patch} "flips --apply"
  require_contains ${pkgs.lib.escapeShellArg patch} "report PASS patch"

  export TMPDIR="$PWD/patch-tmp"
  mkdir -p "$TMPDIR"
  ${pkgs.bash}/bin/bash -c ${pkgs.lib.escapeShellArg (runPatch failedPatch)} > failed-patch.out
  test "$?" -ne 0
  require_grep "FAIL patch patch failed" failed-patch.out
  cmp "$TMPDIR/rom-patch-test" "${fixture}/nes" || exit 1
  ${pkgs.bash}/bin/bash -c ${pkgs.lib.escapeShellArg (runPatch patch)} > successful-patch.out
  test "$?" -eq 0
  cmp "$TMPDIR/rom-patch-test" "${fixture}/nes-patched" || exit 1
  ${pkgs.bash}/bin/bash -c ${pkgs.lib.escapeShellArg (runPatch xdeltaPatch)} > xdelta.out
  test "$?" -eq 0
  require_grep "PASS patch patch applies" xdelta.out
  cmp "$TMPDIR/rom-patch-test" "${fixture}/nes-patched" || exit 1
  ${pkgs.bash}/bin/bash -c ${pkgs.lib.escapeShellArg (runPatch failedXdeltaPatch)} > failed-xdelta.out
  test "$?" -ne 0
  require_grep "FAIL patch patch failed" failed-xdelta.out
  cmp "$TMPDIR/rom-patch-test" "${fixture}/nes" || exit 1
  touch "$out"
''
