{
  lib,
  stdenv,
  fetchGitTree,
  sources,
  pkg-config,
  zlib,
  flac,
  libvorbis,
  boost,
  ...
}:

stdenv.mkDerivation {
  pname = "scummvm-tools";
  version = "0-unstable-${sources.tools.scummvmTools.date}";

  src = fetchGitTree sources.tools.scummvmTools;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    zlib
    flac
    libvorbis
    boost
  ];

  # CLI-only build: skip wxWidgets (GUI) and the unrelated font-creation
  # tool's freetype2/iconv dependencies.
  configureFlags = [
    "--disable-wxwidgets"
    "--disable-freetype2"
    "--disable-iconv"
  ];

  enableParallelBuilding = true;

  # Upstream ships no `install` target (this Makefile only ever produces the
  # binary in the build root); install it by hand.
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp scummvm-tools-cli $out/bin/
    runHook postInstall
  '';

  meta = {
    description = "Compression and extraction tools for ScummVM game data files";
    homepage = "https://github.com/scummvm/scummvm-tools";
    license = lib.licenses.gpl3Plus;
    mainProgram = "scummvm-tools-cli";
    platforms = lib.platforms.unix;
  };
}
