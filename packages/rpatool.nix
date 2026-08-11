{
  lib,
  stdenvNoCC,
  fetchGitTree,
  sources,
  python3,
  ...
}:

stdenvNoCC.mkDerivation {
  pname = "rpatool";
  version = "0-unstable-${sources.tools.rpatool.date}";

  src = fetchGitTree sources.tools.rpatool;

  nativeBuildInputs = [ python3 ];

  dontBuild = true;
  installPhase = ''
    install -Dm755 rpatool $out/bin/rpatool
  '';

  meta = {
    description = "Manipulates Ren'Py archive (.rpa) files";
    homepage = "https://github.com/Shizmob/rpatool";
    license = lib.licenses.mit;
    mainProgram = "rpatool";
    platforms = lib.platforms.unix;
  };
}
