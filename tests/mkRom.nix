{ pkgs }:

let
  inherit (pkgs) lib;
  inherit ((import ../lib/test.nix { inherit lib pkgs; })) addChecks;
  # No `rom` param: real emulators.nix commands read "$out" directly now.
  # Plain string, not a function: mkRom.nix reads emulator.smoke directly.
  smokeCommand = ''
    printf '%s\n' "$out" >> "$TMPDIR/smoke-paths"
    report PASS smoke "smoke check ran"
  '';
  systemEmulators = {
    nes = {
      launcher = pkgs.mesen;
      structure = _: ''report PASS structure "structure check ran"'';
      smoke = smokeCommand;
    };
    patchCommand = _: "report PASS patch \"patch check ran\"";
  };
  compressRom' =
    _parent:
    {
      rom,
      patch ? null,
      sidecar ? null,
      ...
    }:
    (pkgs.runCommand "mkrom-compressed"
      {
        doCheck = false;
        phases = [ "installPhase" ];
      }
      ''
        printf 'rom=%s\n' ${lib.escapeShellArg (toString rom)} > "$out"
        ${lib.optionalString (
          patch != null
        ) "printf 'patch=%s\\n' ${lib.escapeShellArg (toString patch)} >> \"$out\""}
        ${lib.optionalString (
          sidecar != null
        ) "printf 'sidecar=%s\\n' ${lib.escapeShellArg (toString sidecar)} >> \"$out\""}
      ''
    );
  inherit
    (
      (import ../hosts/home/monyarm/games/Emulation/mkRom.nix {
        inherit
          lib
          pkgs
          compressRom'
          addChecks
          systemEmulators
          ;
      })
    )
    mkRom
    ;
  base = pkgs.runCommand "mkrom-base" {
    doCheck = false;
    phases = [ "installPhase" ];
  } "printf base > \"$out\"";
  patch = pkgs.runCommand "mkrom-patch" { } "printf patch > \"$out\"";
  sidecar = pkgs.runCommand "mkrom-sidecar" { } "printf sidecar > \"$out\"";
  baseChecked = addChecks {
    structure = systemEmulators.nes.structure {
      rom = base;
      system = "nes";
    };
    smoke = systemEmulators.nes.smoke;
  } base;
  game = mkRom {
    rom = base;
    system = "nes";
    inherit patch sidecar;
  };
  compressed = game.game;
in
assert compressed.doCheck;
assert baseChecked.builder == compressed.builder;
assert lib.hasInfix "report PASS smoke" baseChecked.checkPhase;
assert lib.hasInfix "report PASS smoke" compressed.checkPhase;
pkgs.runCommand "test-mkrom-integration" { } ''
  export TMPDIR="$PWD/tmp"
  mkdir -p "$TMPDIR"
  out=${lib.escapeShellArg (toString base)} ${pkgs.bash}/bin/bash -c ${lib.escapeShellArg baseChecked.checkPhase}
  out=${lib.escapeShellArg (toString compressed)} ${pkgs.bash}/bin/bash -c ${lib.escapeShellArg compressed.checkPhase}
  test "$(wc -l < "$TMPDIR/smoke-paths")" -eq 2
  grep -F ${lib.escapeShellArg base.name} "$TMPDIR/smoke-paths"
  grep -F ${lib.escapeShellArg compressed.name} "$TMPDIR/smoke-paths"
  grep -F ${lib.escapeShellArg ("patch=" + toString patch)} ${compressed}
  grep -F ${lib.escapeShellArg ("sidecar=" + toString sidecar)} ${compressed}
  test -e ${compressed}
  touch "$out"
''
