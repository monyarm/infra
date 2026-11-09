{
  lib,
  python3Packages,
  fetchGitTree,
  sources,
  ...
}:
python3Packages.buildPythonApplication {
  pname = "game-extraction-toolbox";
  version = sources.tools.gameExtractionToolbox.date;
  src = fetchGitTree sources.tools.gameExtractionToolbox;
  pyproject = true;
  # cfc sgemf: 5 maincpu chunks but 2 names, zip drops pcf.05-07; MAME wants pcfu.03
  postPatch = ''
    substituteInPlace src/gex/lib/tasks/impl/cfc/__init__.py \
      --replace-fail '"pcfu.03a",
                "pcf.04"' '"pcfu.03",
                "pcf.04",
                "pcf.05",
                "pcf.06",
                "pcf.07"'
  '';
  build-system = [ python3Packages.setuptools ];
  dependencies = with python3Packages; [
    bitarray
    click
    click-log
    psutil
    rich
    texttable
  ];
  meta = {
    description = "Tools for extracting ROMs from game rereleases";
    homepage = "https://github.com/shawngmc/game-extraction-toolbox";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
