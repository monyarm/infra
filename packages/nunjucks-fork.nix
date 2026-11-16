{
  lib,
  pkgs,
  fetchGitTree,
  sources,
  ...
}:
let
  src = fetchGitTree sources.ttrpg.nunjucks;
in
pkgs.buildNpmPackage {
  pname = "nunjucks-async";
  version = sources.ttrpg.nunjucks.date;

  inherit src;

  npmDepsHash = sources.ttrpg.nunjucks.npmDepsHash;
  npmFlags = [ "--ignore-scripts" ];

  # fork ships no lockfile; update-sources.py generates one
  postPatch = ''
    cp ${pkgs.writeText "nunjucks-package-lock.json" sources.ttrpg.nunjucks.npmLockFile} package-lock.json
  '';

  # `main` is index.js, which the fork's own `npm run build` generates.
  buildPhase = ''
    runHook preBuild
    npm run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    for f in package.json index.js nunjucks browser bin; do
      [ -e "$f" ] && cp -r "$f" $out/
    done
    runHook postInstall
  '';

  meta = {
    description = "nunjucks fork with async extension parsing, built for Sales & Dungeons";
    homepage = "https://github.com/ogonkov/nunjucks";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.all;
  };
}
