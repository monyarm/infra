{
  lib,
  stdenv,
  fetchGitTree,
  pkg-config,
  sdl3,
  openal,
  ffmpeg_8,
  freetype,
  libjpeg,
  libogg,
  libvorbis,
  opus,
  opusfile,
  zlib,
  sources,
  ...
}:
let
  source = sources.rtcw.realrtcw;
in
stdenv.mkDerivation {
  pname = "realrtcw";
  version = source.tag or "0-unstable-${source.date}";

  src = fetchGitTree source;

  nativeBuildInputs = [ pkg-config ];

  # 5.44c needs FFmpeg 8 and SDL3; the vendored copies are skipped so the
  # engine links the system ones.
  buildInputs = [
    sdl3
    openal
    ffmpeg_8
    freetype
    libjpeg
    libogg
    libvorbis
    opus
    opusfile
    zlib
  ];

  # sdl3.pc's Requires.private lists its optional backends, so pkg-config
  # refuses it without those dev outputs; pass the two flags it needs instead.
  makeFlags = [
    "USE_INTERNAL_LIBS=0"
    "USE_OPENAL_DLOPEN=0"
    "USE_CURL=0"
    "BUILD_SERVER=0"
    "SDL_CFLAGS=-I${lib.getDev sdl3}/include"
    "SDL_LIBS=-lSDL3"
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/realrtcw/main"
    cp -r main/. "$out/lib/realrtcw/main/"
    cp -r main_custom_maps "$out/lib/realrtcw/"
    # STEAM is unset, so the output dir carries the -nosteam flavour suffix.
    build=$(echo build/release-linux-x86_64*)
    install -m755 "$build"/RealRTCW.x86_64 "$out/lib/realrtcw/"
    install -m755 "$build"/renderer_sp_opengl1_x86_64.so "$out/lib/realrtcw/"
    install -m755 "$build"/main/*.so "$out/lib/realrtcw/main/"
    runHook postInstall
  '';

  meta = {
    description = "RealRTCW, a single-player overhaul of Return to Castle Wolfenstein";
    homepage = "https://github.com/wolfetplayer/RealRTCW";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
