{
  lib,
  fetchGitTree,
  sources,
  builders,
  ...
}:

# Reads "RXC1.exe" from cwd, writes extracted SNES roms (Rockman/Mega Man
# X-X3) back into that same cwd -- caller stages the exe beforehand.
builders.mkPythonToolWrapper {
  pname = "mmxlc-rom-extractor";
  version = sources.tools.mmxlcRomExtractor.date;
  src = fetchGitTree sources.tools.mmxlcRomExtractor;
  scripts = [
    {
      bin = "mmxlc-rom-extractor";
      path = "mmxlc_rom_extract.py";
    }
  ];
  meta = {
    description = "Extracts SNES ROMs (Rockman/Mega Man X-X3) from the Mega Man X Legacy Collection";
    homepage = "https://github.com/s3phir0th115/MMXLC1-Rom-Extractor";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
