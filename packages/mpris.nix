{
  stdenv,
  fetchGitTree,
  pkg-config,
  mpv-unwrapped,
  glib,
  ffmpeg-headless,
  sources,
  ...
}:

stdenv.mkDerivation rec {
  pname = "mpris.so";
  version = sources.mpv.mpris.tag;

  src = fetchGitTree sources.mpv.mpris;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    mpv-unwrapped
    glib
    ffmpeg-headless
  ];

  installPhase = ''
    mv mpris.so $out
  '';
}
