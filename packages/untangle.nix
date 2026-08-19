{
  lib,
  fetchGitTree,
  sources,
  builders,
  ...
}:

builders.mkPythonToolWrapper {
  pname = "untangle";
  version = sources.tools.untangle.date;
  src = fetchGitTree sources.tools.untangle;
  scripts = [
    {
      bin = "untangle";
      path = "untangle.py";
    }
  ];
  meta = {
    description = "Extracts files from Double Fine's LPAK bundle format";
    homepage = "https://github.com/fleger/untangle";
    license = lib.licenses.mpl20;
    platforms = lib.platforms.unix;
  };
}
