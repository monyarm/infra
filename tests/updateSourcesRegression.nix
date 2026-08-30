{ pkgs }:

pkgs.runCommand "test-update-sources" { } ''
  export PYTHONDONTWRITEBYTECODE=1
  cp ${../update-sources.py} update-sources.py
  cp ${./test_update_sources_regression.py} test_update_sources_regression.py
  export UPDATE_SOURCES_PATH="$PWD/update-sources.py"
  ${pkgs.python3}/bin/python -m unittest test_update_sources_regression.py
  touch $out
''
