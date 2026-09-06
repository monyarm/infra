{ pkgs }:

let
  test = import ../lib/test.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };
  inherit (test) addChecks;
  base = pkgs.runCommand "add-checks-fixture-input" {
    doCheck = false;
    phases = [ "installPhase" ];
    checkPhase = ''
      report PASS existing "existing check ran"
    '';
  } "touch $out";
  noExistingCheck = pkgs.runCommand "add-checks-no-existing-check" {
    doCheck = false;
    phases = [ "installPhase" ];
  } "touch $out";
  checked = addChecks {
    first = ''
      report FAIL broken "first check failed"
    '';
    second = ''
      touch "$TMPDIR/second-ran"
      report PASS continued "second check ran"
    '';
    badpass = ''
      report PASS bad-status "reported pass before failure"
      false
    '';
    earlyFailure = ''
      false
      report WARN unreachable "failure was masked"
    '';
    quoted = ''
      value="value with spaces and 'quotes'"
      test "$value" = "value with spaces and 'quotes'"
      report PASS quoting "$value"
    '';
  } base;
  injectedOnly = addChecks {
    injected = ''
      touch "$TMPDIR/injected-ran"
      report PASS injected "injected check ran"
    '';
  } noExistingCheck;
  warningOnly = addChecks {
    warning = ''
      report WARN diagnostic "warning does not fail the suite"
    '';
  } (pkgs.runCommand "add-checks-warning-input" { } "touch $out");
in
assert checked.doCheck;
assert injectedOnly.doCheck;
assert !(noExistingCheck ? checkPhase);
assert builtins.elem "checkPhase" checked.phases;
pkgs.runCommand "test-add-checks" { } ''
  set +e
  export TMPDIR="$PWD/failing-tmp"
  mkdir -p "$TMPDIR"
  ${pkgs.bash}/bin/bash -c ${pkgs.lib.escapeShellArg checked.checkPhase}
  status=$?

  test "$status" -ne 0
  test -e "$TMPDIR/second-ran"
  grep -F "check:existing | PASS" "$TMPDIR/add-checks-summary"
  grep -F "first:broken | FAIL" "$TMPDIR/add-checks-summary"
  grep -F "second:continued | PASS" "$TMPDIR/add-checks-summary"
  grep -F "badpass:bad-status | PASS" "$TMPDIR/add-checks-summary"
  grep -F "badpass:exit | FAIL" "$TMPDIR/add-checks-summary"
  grep -F "earlyFailure:exit | FAIL" "$TMPDIR/add-checks-summary"
  grep -F "quoted:quoting | PASS" "$TMPDIR/add-checks-summary"

  export TMPDIR="$PWD/injected-tmp"
  mkdir -p "$TMPDIR"
  ${pkgs.bash}/bin/bash -c ${pkgs.lib.escapeShellArg injectedOnly.checkPhase}
  test -e "$TMPDIR/injected-ran"
  ! grep -F "check:" "$TMPDIR/add-checks-summary"
  grep -F "injected:injected | PASS" "$TMPDIR/add-checks-summary"

  export TMPDIR="$PWD/warning-tmp"
  mkdir -p "$TMPDIR"
  ${pkgs.bash}/bin/bash -c ${pkgs.lib.escapeShellArg warningOnly.checkPhase}
  test "$?" -eq 0
  grep -F "warning:diagnostic | WARN" "$TMPDIR/add-checks-summary"
  touch "$out"
''
