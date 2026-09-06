{
  pkgs,
  lib ? pkgs.lib,
  mkSmoke,
}:

let
  python = "${pkgs.python3}/bin/python";
  validator = ./romChecks.py;
  arg = value: lib.escapeShellArg (toString value);

  structureCommand =
    { system }:
    ''
      records="$TMPDIR/rom-structure-records"
      ${python} ${validator} ${arg system} "$out" > "$records"
      validator_status=$?
      report_records "$records"
      if [ "$validator_status" -eq 0 ]; then
        :
      else
        false
      fi
    '';

  patchCommand' =
    { patch }:
    let
      # patch is usually a floating content-addressed derivation
      # (fetchRomhacking/getFile/rename) -- toString/${...} on those only
      # resolves to the real path at build time, not eval time, so it can't
      # be used to sniff the extension here. `.name` is a plain input
      # attribute, known immediately regardless of CA/build status.
      patchName = if lib.isDerivation patch then patch.name else toString patch;
      suffix = lib.toLower (lib.last (lib.splitString "." patchName));
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
          "${pkgs.xdelta}/bin/xdelta3 -d -f -s \"$out\" ${arg patch} \"$tmp.out\" && mv \"$tmp.out\" \"$tmp\""
        else
          "${pkgs.gnupatch}/bin/patch \"$tmp\" -i ${arg patch} -o \"$tmp.out\" && mv \"$tmp.out\" \"$tmp\"";
    in
    ''
      tmp="$TMPDIR/rom-patch-test"
      rm -f "$tmp" "$tmp.out"
      if ! cp "$out" "$tmp"; then
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

  # lib/test.nix's mkSmoke owns env setup + timeout + PASS/FAIL reporting;
  # these just supply the per-emulator command and quirks.
  mesenSmoke = mkSmoke {
    name = "mesen";
    extraDirs = [ ".config/Mesen2" ];
    # With no prior settings.json, Mesen shows a first-run config wizard GUI
    # *before* it ever checks for --testrunner (see Program.cs) -- pre-seed
    # one so it skips straight to the test runner. --noVideo/--noAudio mean
    # no display is needed at all (confirmed: no xvfb-run required).
    preSetup = ''
      echo '{}' > "$HOME/.config/Mesen2/settings.json"
      cat > "$TMPDIR/mesen-300-frames.lua" <<'EOF'
      local frames = 0
      emu.addEventCallback(function()
        frames = frames + 1
        if frames >= 300 then
          emu.stop()
        end
      end, emu.eventType.endFrame)
      EOF
    '';
    # Binary name is capitalized "Mesen", not "mesen".
    command = ''${pkgs.mesen}/bin/Mesen --testrunner --noVideo --noAudio "$out" "$TMPDIR/mesen-300-frames.lua"'';
    timeoutSeconds = 30;
    killSignal = "KILL";
    passMessage = "ran 300 frames without crashing";
    failMessage = "Mesen exited with status $status";
  };

  # mgba's CLI has no frame-limit/test-mode flag -- kill it after a bounded
  # run instead. SIGKILL (not --foreground/TERM) guarantees it actually dies;
  # exit 137 means "still running fine when we killed it", same verdict as a
  # clean exit 0. Any other exit is mgba's own fast failure.
  mgbaSmoke = mkSmoke {
    name = "mgba";
    command = ''${pkgs.coreutils}/bin/env SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy ${pkgs.mgba}/bin/mgba "$out"'';
    killSignal = "KILL";
    acceptableExitCodes = [
      0
      137
    ];
    failMessage = "mgba exited with status $status";
  };

  blastemSmoke = mkSmoke {
    name = "blastem";
    command = ''${pkgs.blastem}/bin/blastem -b 300 "$out"'';
    passMessage = "ran 300 frames without crashing";
    failMessage = "blastem exited with status $status";
  };
in

rec {
  inherit mkSmoke;
  patchCommand = patchCommand';
  nes = {
    launcher = pkgs.mesen;
    structure = structureCommand;
    smoke = mesenSmoke;
    # Mesen's --testrunner can't load a compressed archive at all (confirmed:
    # no CLI/Lua path to reference an entry inside one) -- pre-compression
    # smoke coverage is still real signal, so just skip the post-compression
    # one instead of pretending it passed.
    compressedSmoke = null;
  };
  snes = {
    launcher = pkgs.snes9x-gtk;
    structure = structureCommand;
    smoke = null;
  };
  gb = {
    launcher = pkgs.mgba;
    structure = structureCommand;
    smoke = mgbaSmoke;
  };
  gbc = {
    launcher = pkgs.mgba;
    structure = structureCommand;
    smoke = mgbaSmoke;
  };
  gba = {
    launcher = pkgs.mgba;
    structure = structureCommand;
    smoke = mgbaSmoke;
  };
  genesis = {
    launcher = pkgs.blastem;
    structure = structureCommand;
    smoke = blastemSmoke;
  };
  gamegear = {
    launcher = pkgs.gearsystem;
    structure = structureCommand;
    smoke = null;
  };
}
