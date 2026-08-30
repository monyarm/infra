{
  lib,
  pkgs,
  fetchGitTree,
  sources,
  ...
}:
let
  minijsonSrc = fetchGitTree sources.tools.minijson;
  despacerSrc = fetchGitTree sources.tools.minijson-despacer;

  # fetchGitTree doesn't follow git submodules (verified: the fetched tree's
  # despacer/ is empty) -- despacer is its own pinned source (no tags
  # upstream, see sources.toml), placed here by hand instead. Also strips
  # dub.sdl's `preGenerateCommands "git submodule update --init"`: that's
  # only needed when despacer is a real git submodule, which it never is
  # here, and the build sandbox has no `git` anyway.
  combinedSrc =
    pkgs.runCommand "minijson-combined-src"
      {
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      }
      ''
        cp -r --no-preserve=mode "${minijsonSrc}" "$out"
        chmod -R u+w "$out"
        rm -rf "$out/despacer"
        cp -r --no-preserve=mode "${despacerSrc}" "$out/despacer"
        chmod -R u+w "$out/despacer"
        sed -i '/preGenerateCommands "git submodule update --init"/d' "$out/dub.sdl"
        # nixpkgs' stdenv strips -march=native for reproducibility (verified:
        # build failed with undefined references to despacer's AVX2/SSE4.1
        # symbols without it, since its D bindings call those unconditionally,
        # not through a runtime CPU dispatcher) -- pin the fixed baseline
        # despacer's own README already claims to target instead.
        sed -i 's/-march=native/-mavx2 -msse4.1/' "$out/despacer/CMakeLists.txt"
      '';

  version = lib.removePrefix "v" (
    sources.tools.minijson.tag or "0-unstable-${sources.tools.minijson.date}"
  );
in
pkgs.buildDubPackage {
  pname = "minijson";
  inherit version;

  src = combinedSrc;
  dubLock = sources.tools.minijson.dubLock;
  compiler = pkgs.ldc;
  dubBuildFlags = [ "--config=executable" ];
  nativeBuildInputs = [
    pkgs.cmake
    pkgs.gnumake
  ];
  buildInputs = [ pkgs.gcc ];
  # dub.sdl's own targetPath ("./dist").
  installPhase = "install -Dm755 dist/minijson $out/bin/minijson";
  meta = {
    description = "Minify JSON files, with support for comments";
    homepage = "https://github.com/aminya/minijson";
    license = pkgs.lib.licenses.mit;
    mainProgram = "minijson";
    platforms = pkgs.lib.platforms.unix;
  };
}
