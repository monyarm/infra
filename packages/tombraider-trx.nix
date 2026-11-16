{
  lib,
  stdenv,
  fetchGitTree,
  fetchzip,
  sources,
  meson,
  ninja,
  pkg-config,
  python3,
  SDL2,
  glew,
  ffmpeg,
  pcre2,
  lua5_4,
  uthash,
  zlib,
  libGL,
  ...
}:

let
  source = sources.trx.engine;
  tree = fetchGitTree source;
  version = lib.removePrefix "trx-" (source.tag or "0-unstable-${source.date}");

  # Screenshots/title art is not in git and only ships as unversioned zips.
  artTrees = map (asset: fetchzip { inherit (asset) url hash; }) [
    sources.trx.assets.tr1
    sources.trx.assets.tr2
    sources.trx.assets.tr3
  ];
in
stdenv.mkDerivation {
  pname = "tombraider-trx";
  inherit version;

  src = tree;
  # meson writes into the source tree (and runs ../tools scripts), so build
  # from a writable copy instead of the read-only store path
  unpackPhase = ''
    cp -r ${tree}/src ${tree}/tools .
    chmod -R u+w src tools
    cd src
  '';

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    python3
  ];
  buildInputs = [
    SDL2
    glew
    ffmpeg
    pcre2
    lua5_4
    uthash
    zlib
    libGL
  ];

  mesonBuildType = "release";
  mesonFlags = [
    (lib.mesonBool "staticdeps" false)
    (lib.mesonOption "trx_version" version)
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 TRX "$out/bin/TRX"
    mkdir -p "$out/share/trx"
    cp -r ${tree}/data/trx/ship/. "$out/share/trx/"
    chmod -R u+w "$out/share/trx"
    for asset in ${lib.concatStringsSep " " (map toString artTrees)}; do
      cp -r "$asset"/. "$out/share/trx/games/"
    done
    runHook postInstall
  '';

  meta = {
    description = "Tomb Raider I-III engine reimplementation";
    homepage = "https://github.com/LostArtefacts/TRX";
    license = lib.licenses.gpl3Plus;
    mainProgram = "TRX";
    platforms = lib.platforms.unix;
  };
}
