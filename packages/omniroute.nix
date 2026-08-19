{
  pkgs,
  lib,
  sources,
  ...
}:
pkgs.buildNpmPackage rec {
  pname = "omniroute";
  inherit (sources.ai.services.omniroute) version;

  src = pkgs.fetchurl {
    inherit (sources.ai.services.omniroute) url hash;
  };

  npmDepsHash = sources.ai.services.omniroute.npmDepsHash;
  # Various deps' postinstalls try to fetch platform binaries over the network
  # (playwright chromium, onnxruntime-node's CUDA build, bun's own binary,
  # ...) -- unreachable in the sandbox. Skip all install scripts wholesale
  # rather than chase each one, then rebuild just the two packages that
  # genuinely need native compilation (below).
  npmFlags = [
    "--legacy-peer-deps"
    "--ignore-scripts"
  ];

  # registry tarball ships no lock file -- update-sources.py synthesized one
  # (npmLockFile) at hash-calc time; materialize it the same way here.
  postPatch = ''
    cp ${pkgs.writeText "package-lock.json" sources.ai.services.omniroute.npmLockFile} package-lock.json
  '';

  # better-sqlite3/keytar need a real node-gyp rebuild (no prebuilt binary
  # fetchable in the sandbox) -- give them a C/C++ toolchain, python, and
  # (keytar) libsecret via pkg-config, then rebuild just those two after
  # --ignore-scripts skipped their postinstalls above.
  nativeBuildInputs = [
    pkgs.python3
    pkgs.pkg-config
  ];
  buildInputs = [ pkgs.libsecret ];

  preInstall = ''
    npm rebuild better-sqlite3 keytar --legacy-peer-deps
  '';

  dontNpmBuild = true;

  meta = {
    description = "Unified local AI gateway/router with automatic provider fallback";
    homepage = "https://omniroute.online";
    license = lib.licenses.mit;
    mainProgram = "omniroute";
    platforms = lib.platforms.linux;
  };
}
