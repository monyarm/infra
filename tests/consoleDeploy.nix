# Console deployment engine tests.
#
# Runs the Python unittest suite inside the sandbox. This proves the ownership
# invariants on a real filesystem: unmanaged data survives, only previously
# managed files are deleted, external edits are never silently overwritten.
{ pkgs }:

let
  source = ../apps/console;
in
pkgs.runCommand "test-console-deploy"
  {
    nativeBuildInputs = [ pkgs.python3 ];
    src = source;
    dontConfigure = true;
    dontBuild = true;
    dontInstall = true;
  }
  ''
    # `src` is apps/console, so its contents need a parent directory named
    # "console" for `import console` to resolve as a package.
    work="$TMPDIR/work"
    mkdir -p "$work"
    cp -r "$src" "$work/console"
    cd "$work"
    export PYTHONPATH="$work:$work/console"
    cd "$work/console"
    python3 -m unittest -v test_deploy 2>&1 | tee "$work/test-output.log"
    log="$work/test-output.log"
    grep -q "^OK$" "$log" || {
      echo "FAIL: unittest suite did not report OK" >&2
      exit 1
    }
    # Guard against the suite silently losing coverage.
    count=$(grep -c "\.\.\. ok$" "$log")
    echo "passed tests: $count"
    if [ "$count" -lt 40 ]; then
      echo "FAIL: expected at least 40 passing tests, got $count" >&2
      exit 1
    fi
    touch $out
  ''
