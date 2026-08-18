{
  lib,
  fetchGitTree,
  sources,
  builders,
  ...
}:

# Each script reads a game executable ("Proteus.exe"/etc.) from its own
# cwd and writes extracted .nes files back into that same cwd -- the
# caller stages the exe into a working directory before invoking these.
builders.mkPythonToolWrapper {
  pname = "mmlc-dac-extractor";
  version = sources.tools.mmlcDacExtractor.date;
  src = fetchGitTree sources.tools.mmlcDacExtractor;
  scripts = [
    {
      bin = "mmlc-extractor";
      path = "src/mmlc-extractor.py";
    }
    {
      bin = "mmlc-extractor-rockman";
      path = "src/mmlc-extractor-rockman.py";
    }
    {
      bin = "dac-extractor";
      path = "src/dac-extractor.py";
    }
  ];
  meta = {
    description = "Extracts NES ROMs from the Mega Man Legacy Collection and Disney Afternoon Collection";
    homepage = "https://github.com/HTV04/mmlc-dac-extractor";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
