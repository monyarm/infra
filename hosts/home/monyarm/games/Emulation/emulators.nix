{
  pkgs,
  lib ? pkgs.lib,
}:

let
  python = "${pkgs.python3}/bin/python";
  validator = ./romChecks.py;
  timeout = "${pkgs.coreutils}/bin/timeout --foreground 10s";
  arg = value: lib.escapeShellArg (toString value);

  structureCommand =
    { system, rom }:
    ''
      records="$TMPDIR/rom-structure-records"
      ${python} ${validator} ${arg system} ${arg rom} > "$records"
      validator_status=$?
      report_records "$records"
      if [ "$validator_status" -eq 0 ]; then
        :
      else
        false
      fi
    '';

  patchCommand' =
    { patch, rom }:
    let
      suffix = lib.toLower (lib.last (lib.splitString "." (toString patch)));
      apply =
        if
          builtins.elem suffix [
            "ips"
            "bps"
            "ups"
          ]
        then
          "${pkgs.flips}/bin/flips --apply ${arg patch} \"$tmp\" \"$tmp.out\" && mv \"$tmp.out\" \"$tmp\""
        else if
          builtins.elem suffix [
            "xdelta"
            "vcdiff"
          ]
        then
          "${pkgs.xdelta}/bin/xdelta3 -d -f -s ${arg rom} ${arg patch} \"$tmp.out\" && mv \"$tmp.out\" \"$tmp\""
        else
          "${pkgs.gnupatch}/bin/patch \"$tmp\" -i ${arg patch} -o \"$tmp.out\" && mv \"$tmp.out\" \"$tmp\"";
    in
    ''
      tmp="$TMPDIR/rom-patch-test"
      rm -f "$tmp" "$tmp.out"
      if ! cp ${arg rom} "$tmp"; then
        report FAIL patch "cannot copy ROM"
        false
      fi
      if ${apply}; then
        report PASS patch "patch applies"
      else
        report FAIL patch "patch failed"
        false
      fi
    '';

  mesenCommand =
    { rom }:
    ''
      HOME="$TMPDIR/mesen-home"
      mkdir -p "$HOME"
      cat > "$TMPDIR/mesen-300-frames.lua" <<'EOF'
      local frames = 0
      emu.addEventCallback(function()
        frames = frames + 1
        if frames >= 300 then
          emu.stop()
        end
      end, emu.eventType.endFrame)
      EOF
      ${timeout} ${pkgs.mesen}/bin/mesen --test --lua-script "$TMPDIR/mesen-300-frames.lua" ${arg rom}
    '';

  mgbaCommand =
    { rom }:
    ''
      SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy ${timeout} ${pkgs.mgba}/bin/mgba -F 300 ${arg rom}
    '';

  blastemCommand =
    { rom }:
    ''
      HOME="$TMPDIR/blastem-home"
      mkdir -p "$HOME"
      ${timeout} ${pkgs.blastem}/bin/blastem -b 300 ${arg rom}
    '';
in

rec {
  patchCommand = patchCommand';
  nes = {
    launcher = pkgs.mesen;
    structure = structureCommand;
    smoke = mesenCommand;
  };
  snes = {
    launcher = pkgs.snes9x-gtk;
    structure = structureCommand;
    smoke = null;
  };
  gb = {
    launcher = pkgs.mgba;
    structure = structureCommand;
    smoke = mgbaCommand;
  };
  gbc = {
    launcher = pkgs.mgba;
    structure = structureCommand;
    smoke = mgbaCommand;
  };
  gba = {
    launcher = pkgs.mgba;
    structure = structureCommand;
    smoke = mgbaCommand;
  };
  genesis = {
    launcher = pkgs.blastem;
    structure = structureCommand;
    smoke = blastemCommand;
  };
  gamegear = {
    launcher = pkgs.gearsystem;
    structure = structureCommand;
    smoke = null;
  };
}
