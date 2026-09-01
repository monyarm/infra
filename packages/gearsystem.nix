{
  lib,
  stdenv,
  fetchGitTree,
  sources,
  pkg-config,
  SDL2,
  libGL,
  glew,
  libX11,
  ...
}:

stdenv.mkDerivation {
  pname = "gearsystem";
  version = "0-unstable-${sources.emu.gearsystem.date}";

  src = fetchGitTree sources.emu.gearsystem;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    SDL2
    libGL
    glew
    libX11
  ];

  postPatch = ''
    sed -i 's|GIT_VERSION := $(shell git describe.*|GIT_VERSION := "${sources.emu.gearsystem.date}"|' platforms/desktop-shared/Makefile.common
  '';

  buildPhase = ''
    runHook preBuild
    make -C platforms/linux PLATFORM=Linux
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    cp platforms/linux/gearsystem "$out/bin/"
    runHook postInstall
  '';

  meta = {
    description = "Sega Master System / Game Gear / SG-1000 emulator";
    homepage = "https://github.com/drhelius/Gearsystem";
    license = lib.licenses.gpl3Plus;
    mainProgram = "gearsystem";
    platforms = lib.platforms.unix;
  };
}
