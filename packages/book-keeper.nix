{
  lib,
  pkgs,
  fetchGitTree,
  sources,
  ...
}:
let
  data = fetchGitTree sources.ttrpg.book-keeper-data;

  # The upstream default source is an SSH git URL; seed a local one so the
  # bundled data works offline and the user's own sources.json is left alone.
  seed = pkgs.writeText "book-keeper-sources.json" (
    builtins.toJSON [
      {
        name = "Book-Keeper-Data";
        type = "local";
        path = "${data}";
      }
    ]
  );
in
pkgs.buildNpmPackage {
  pname = "book-keeper";
  version = "0.1.0";

  src = fetchGitTree sources.ttrpg.book-keeper;

  npmDepsHash = sources.ttrpg.book-keeper.npmDepsHash;
  npmFlags = [ "--ignore-scripts" ];

  nativeBuildInputs = [ pkgs.makeWrapper ];

  buildPhase = ''
    runHook preBuild
    npm run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/book-keeper $out/bin
    cp -r dist package.json $out/lib/book-keeper/
    makeWrapper ${pkgs.nodejs}/bin/node $out/bin/book-keeper \
      --add-flags $out/lib/book-keeper/dist/main.js \
      --run '
        if [ ! -e "$HOME/.book-keeper/sources.json" ]; then
          mkdir -p "$HOME/.book-keeper"
          cp ${seed} "$HOME/.book-keeper/sources.json"
        fi
      '
    runHook postInstall
  '';

  meta = {
    description = "Random book generator for D&D loot, with external JSON data sources";
    homepage = "https://github.com/monyarm/Book-Keeper";
    license = lib.licenses.mit;
    mainProgram = "book-keeper";
    platforms = lib.platforms.unix;
  };
}
