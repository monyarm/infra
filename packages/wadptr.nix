{
  lib,
  stdenv,
  fetchGitTree,
  sources,
  ...
}:

stdenv.mkDerivation {
  pname = "wadptr";
  version = "0-unstable-${sources.tools.wadptr.date}";

  src = fetchGitTree sources.tools.wadptr;

  installFlags = [ "PREFIX=${placeholder "out"}" ];

  meta = {
    description = "Compresses Doom WAD files by merging duplicate lumps";
    homepage = "https://github.com/fragglet/wadptr";
    license = lib.licenses.gpl2Only;
    mainProgram = "wadptr";
    platforms = lib.platforms.unix;
  };
}
