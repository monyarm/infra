{
  lib,
  stdenv,
  fetchGitTree,
  sources,
  cmake,
  pkg-config,
  sdl12-compat,
  SDL_image,
  SDL_gfx,
  SDL_mixer,
  libGL,
  libGLU,
  zlib,
  ...
}:

let
  src = fetchGitTree sources.tools.openxcomExtended;
in
stdenv.mkDerivation {
  pname = "openxcom-extended";
  version = sources.tools.openxcomExtended.date;

  inherit src;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];
  buildInputs = [
    sdl12-compat
    SDL_image
    SDL_gfx
    SDL_mixer
    libGL
    libGLU
    zlib
  ];

  # upstream CMake only installs desktop files; the binary stays in the build dir
  cmakeFlags = [
    (lib.cmakeBool "BUILD_PACKAGE" false)
    (lib.cmakeBool "DEV_BUILD" false)
    (lib.cmakeFeature "DATADIR" "${placeholder "out"}/share/openxcom")
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 bin/openxcom "$out/bin/openxcom"
    mkdir -p "$out/share/openxcom"
    cp -r "${src}/bin/common" "$out/share/openxcom/common"
    runHook postInstall
  '';

  meta = {
    description = "OpenXcom Extended, an X-COM: UFO Defense engine";
    homepage = "https://openxcom.org/";
    license = lib.licenses.gpl3Plus;
    mainProgram = "openxcom";
    platforms = lib.platforms.linux;
  };
}
