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
