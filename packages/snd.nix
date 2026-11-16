{
  lib,
  pkgs,
  fetchGitTree,
  sources,
  ...
}:
let
  src = fetchGitTree sources.ttrpg.snd;
  version = sources.ttrpg.snd.tag;

  # the frontend's nunjucks fork needs a real build step, see the package file
  nunjucks = import ./nunjucks-fork.nix {
    inherit
      lib
      pkgs
      fetchGitTree
      sources
      ;
  };

  frontend = pkgs.buildNpmPackage {
    pname = "snd-frontend";
    inherit version;

    src = "${src}/frontend";

    npmDepsHash = sources.ttrpg.snd.npmDepsHash;
    forceGitDeps = true;
    # the nunjucks git fork generates its dist in `prepare`; skipping
    # install scripts leaves it without an entry point.
    makeCacheWritable = true;

    # nunjucks is a git fork whose prebuilt dist only exists after its
    # `prepare` script runs, which npm vendoring disables; point the entry at
    # the CJS sources instead so vite can bundle them directly.
    postConfigure = ''
      ${pkgs.jq}/bin/jq '.main = "nunjucks/index.js"' \
        node_modules/nunjucks/package.json > nunjucks.json
      mv nunjucks.json node_modules/nunjucks/package.json
    '';

    postPatch = ''
      cp ${pkgs.writeText "snd-frontend-package-lock.json" sources.ttrpg.snd.npmLockFile} package-lock.json
    '';

    # replace the vendored fork, whose index.js is never generated
    preBuild = ''
      chmod -R u+w node_modules/nunjucks || true
      rm -rf node_modules/nunjucks
      cp -r ${nunjucks} node_modules/nunjucks
    '';

    installPhase = ''
      runHook preInstall
      cp -r dist $out
      runHook postInstall
    '';
  };
in
pkgs.buildGoModule {
  pname = "snd";
  inherit version src;

  vendorHash = "sha256-DuOVk0gEX80BDAuEG+5okqvbRamWXAyP/uIu173NHPY=";
  proxyVendor = true;
  subPackages = [ "cmd/app" ];

  ldflags = [
    "-X github.com/BigJk/snd.GitCommitHash=${sources.ttrpg.snd.rev}"
    "-X github.com/BigJk/snd.GitBranch=${sources.ttrpg.snd.tag}"
  ];

  nativeBuildInputs = [ pkgs.makeWrapper ];

  postInstall = ''
    mv $out/bin/app $out/bin/snd

    # server serves ./frontend/dist relative to its cwd
    install -d $out/share/snd/frontend/dist $out/share/snd/data
    cp -r ${frontend}/. $out/share/snd/frontend/dist/
    install -m644 ${src}/data/icon.png $out/share/snd/data/icon.png

    # snd reads frontend/ and data/ from the cwd and keeps its Badger DB in
    # ./userdata, so run it from a writable dir with the store bits linked in.
    wrapProgram $out/bin/snd \
      --prefix PATH : ${
        lib.makeBinPath [
          pkgs.cups
          pkgs.chromium
        ]
      } \
      --set SND_CHROME_BIN ${lib.getExe pkgs.chromium} \
      --run '
        d="''${XDG_DATA_HOME:-$HOME/.local/share}/snd"
        mkdir -p "$d/userdata"
        ln -sfn ${placeholder "out"}/share/snd/frontend "$d/frontend"
        ln -sfn ${placeholder "out"}/share/snd/data "$d/data"
        cd "$d"
      '
  '';

  meta = {
    description = "Sales & Dungeons — thermal printer toolset for TTRPGs";
    homepage = "https://sales-and-dungeons.app/";
    license = lib.licenses.mit;
    mainProgram = "snd";
    platforms = lib.platforms.linux;
  };
}
