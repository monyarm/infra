{
  lib,
  pkgs,
  fetchGitTree,
  sources,
  ...
}:
pkgs.buildNpmPackage {
  pname = "gemmaker";
  version = "1.0.0";

  src = fetchGitTree sources.ttrpg.gemmaker;

  npmDepsHash = sources.ttrpg.gemmaker.npmDepsHash;
  npmFlags = [ "--ignore-scripts" ];

  nativeBuildInputs = [ pkgs.makeWrapper ];

  buildPhase = ''
    runHook preBuild
    npm run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/gemmaker $out/bin
    cp -r dist node_modules package.json $out/lib/gemmaker/
    makeWrapper ${pkgs.nodejs}/bin/node $out/bin/gemmaker \
      --add-flags $out/lib/gemmaker/dist/index.js \
      --prefix NODE_PATH : $out/lib/gemmaker/node_modules
    runHook postInstall
  '';

  meta = {
    description = "Random gemstone generator for D&D and other roleplaying systems";
    homepage = "https://github.com/monyarm/GemMakerDnD";
    license = lib.licenses.mit;
    mainProgram = "gemmaker";
    platforms = lib.platforms.unix;
  };
}
