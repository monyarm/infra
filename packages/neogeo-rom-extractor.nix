{
  lib,
  fetchGitTree,
  sources,
  builders,
  ...
}:

# Batch-scans owned-game folders staged under a working directory (per
# its own per-game modules in project_files/game_modules/), writing
# rebuilt MAME-loadable zips (incl. neogeo.zip BIOS, when present in the
# source) to extracted_neogeo/ under that same working directory.
builders.mkPythonToolWrapper {
  pname = "neogeo-rom-extractor";
  version = sources.tools.neogeoRomExtractor.date;
  src = fetchGitTree sources.tools.neogeoRomExtractor;
  scripts = [
    {
      bin = "neogeo-rom-extractor";
      path = "neogeo_extractor.py";
    }
  ];
  extraShare = [ "project_files" ];
  meta = {
    description = "Rebuilds verified Neo Geo ROM zips from supported legally-owned PC releases";
    homepage = "https://github.com/DrRetroMod/neogeo-rom-extractor";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
