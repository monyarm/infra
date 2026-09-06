{ lib, pkgs, ... }:
{
  # Shared shape for every emulator "does it run" check: real $HOME (mesen's
  # config, blastem/mgba's SDL prefs), $XDG_RUNTIME_DIR (SDL/mame error out
  # even with video/audio disabled otherwise), and a minimal fontconfig (no
  # /etc/fonts inside the build sandbox) -- then a timeout-wrapped run of
  # `command`, reporting PASS/FAIL off its exit status. extraDirs are created
  # under $HOME for emulators needing their own config subdir (Mesen2's).
  # killSignal null means `timeout --foreground` (plain SIGTERM); otherwise
  # `timeout -s <signal>` (e.g. "KILL", for emulators with no clean-exit path).
  mkSmoke =
    {
      name,
      command,
      extraDirs ? [ ],
      preSetup ? "",
      timeoutSeconds ? 10,
      killSignal ? null,
      acceptableExitCodes ? [ 0 ],
      passMessage ? "ran without crashing (status $status)",
      failMessage ? "exited with status $status",
    }:
    let
      timeoutFlag = if killSignal == null then "--foreground" else "-s ${killSignal}";
      acceptCheck = lib.concatMapStringsSep " || " (
        code: ''[ "$status" -eq ${toString code} ]''
      ) acceptableExitCodes;
    in
    ''
      export HOME="$TMPDIR/${name}-home"
      export XDG_RUNTIME_DIR="$TMPDIR/${name}-xdg"
      export FONTCONFIG_FILE=${pkgs.makeFontsConf { fontDirectories = [ ]; }}
      mkdir -p "$HOME" "$XDG_RUNTIME_DIR" ${lib.concatMapStringsSep " " (d: ''"$HOME/${d}"'') extraDirs}
      ${preSetup}
      ${pkgs.coreutils}/bin/timeout ${timeoutFlag} ${toString timeoutSeconds}s ${command}
      status=$?
      if ${acceptCheck}; then
        report PASS smoke "${passMessage}"
      else
        report FAIL smoke "${failMessage}"
      fi
    '';

  addChecks =
    checks: drv:
    let
      checkNames = lib.attrNames checks;
      commandFor =
        check:
        if builtins.isFunction check then
          if builtins.functionArgs check == { } then check else check drv
        else
          check;
      checkScripts = map (
        name:
        let
          command = commandFor checks.${name};
        in
        ''
          current_check=${lib.escapeShellArg name}
          echo "==> $current_check"
          reported_failure=0
          if (set -e; eval ${lib.escapeShellArg command}); then
            :
          else
            status=$?
            if [ "$status" -ne 0 ] && [ ! -e "$failure_marker" ]; then
              report FAIL exit "check exited with status $status"
            fi
          fi
          [ -e "$failure_marker" ] && failed=1
        ''
      ) checkNames;
      existingCheck = drv.checkPhase or null;
      existingScript = lib.optionalString (existingCheck != null) ''
        current_check=check
        echo "==> $current_check"
        reported_failure=0
        if (set -e; eval ${lib.escapeShellArg existingCheck}); then
          :
        else
          status=$?
          if [ "$status" -ne 0 ] && [ ! -e "$failure_marker" ]; then
            report FAIL exit "check exited with status $status"
          fi
        fi
        [ -e "$failure_marker" ] && failed=1
      '';
      checkScript = ''
        set +e
        summary="$TMPDIR/add-checks-summary"
        failure_marker="$TMPDIR/add-checks-failure"
        : > "$summary"
        rm -f "$failure_marker"
        failed=0

        report() {
          status="$1"
          subcheck="$2"
          shift 2
          message="$*"
          printf '%s:%s | %s\n' "$current_check" "$subcheck" "$status" | tee -a "$summary"
          printf '%s\n' "$message"
          if [ "$status" = FAIL ]; then
            failed=1
            reported_failure=1
            : > "$failure_marker"
            return 1
          fi
        }

        report_records() {
          records="$1"
          while IFS=$'\t' read -r status subcheck message; do
            [ -n "$status" ] || continue
            report "$status" "$subcheck" "$message" || :
          done < "$records"
        }

        ${existingScript}
        ${lib.concatStringsSep "\n" checkScripts}

        echo "==> summary"
        name_width=5
        sub_width=8
        while IFS= read -r line; do
          [ -n "$line" ] || continue
          check_subcheck="''${line%% | *}"
          check_name="''${check_subcheck%%:*}"
          subcheck_name="''${check_subcheck#*:}"
          [ "''${#check_name}" -gt "$name_width" ] && name_width="''${#check_name}"
          [ "''${#subcheck_name}" -gt "$sub_width" ] && sub_width="''${#subcheck_name}"
        done < "$summary"
        rule="$(printf '%*s' "$((name_width + sub_width + 10))" "" | tr ' ' '-')"
        printf '%-*s  %-*s  %s\n' "$name_width" "CHECK" "$sub_width" "SUBCHECK" "STATUS"
        printf '%s\n' "$rule"
        pass_count=0
        warn_count=0
        fail_count=0
        total_count=0
        while IFS= read -r line; do
          [ -n "$line" ] || continue
          check_subcheck="''${line%% | *}"
          status="''${line##* | }"
          check_name="''${check_subcheck%%:*}"
          subcheck_name="''${check_subcheck#*:}"
          printf '%-*s  %-*s  %s\n' "$name_width" "$check_name" "$sub_width" "$subcheck_name" "$status"
          total_count=$((total_count + 1))
          case "$status" in
            PASS) pass_count=$((pass_count + 1)) ;;
            WARN) warn_count=$((warn_count + 1)) ;;
            FAIL) fail_count=$((fail_count + 1)) ;;
          esac
        done < "$summary"
        printf '%s\n' "$rule"
        printf 'TOTAL: %d checks -- %d PASS, %d WARN, %d FAIL\n' "$total_count" "$pass_count" "$warn_count" "$fail_count"
        exit "$failed"
      '';
    in
    if drv ? overrideAttrs then
      drv.overrideAttrs (
        _old:
        # pkgs.runCommand-style derivations set `buildCommand`, which makes
        # genericBuild return before ever consulting phases/checkPhase --
        # convert it to a real installPhase first, or checkPhase silently
        # never runs no matter what doCheck/phases say.
        (
          if drv ? buildCommand then
            {
              buildCommand = null;
              installPhase = ''
                runHook preInstall
                ${drv.buildCommand}
                runHook postInstall
              '';
              phases = [
                "installPhase"
                "checkPhase"
              ];
            }
          else
            lib.optionalAttrs (drv ? phases) {
              phases = lib.unique ((drv.phases or [ ]) ++ [ "checkPhase" ]);
            }
        )
        // {
          doCheck = true;
          checkPhase = checkScript;
        }
      )
    else
      # Raw `derivation` (e.g. rename) has no overrideAttrs/checkPhase -- run checks in a wrapper instead.
      pkgs.runCommand (drv.name or "checked-rom")
        {
          allowSubstitutes = false;
          __contentAddressed = true;
          outputHashAlgo = "sha256";
          outputHashMode = "recursive";
        }
        ''
          cp -as "${drv}" "$out"
          ${checkScript}
        '';
}
