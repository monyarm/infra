{
  lib,
  pkgs,
  fetchGitTree,
  sources,
  writeText,
  ...
}:

let
  nodeDatachannel =
    let
      hostPlatform = pkgs.stdenv.hostPlatform;

      npmArch =
        if hostPlatform.isx86_64 then
          "x64"
        else if hostPlatform.isAarch64 then
          "arm64"
        else
          throw "Unsupported architecture for esbuild/rollup npm packages: ${hostPlatform.parsed.cpu.name}";

      npmOs =
        if hostPlatform.isLinux then
          "linux"
        else if hostPlatform.isDarwin then
          "darwin"
        else
          throw "Unsupported OS for esbuild/rollup npm packages: ${hostPlatform.parsed.kernel.name}";

      esbuildPkg = "@esbuild/${npmOs}-${npmArch}";

      rollupPkg =
        if npmOs == "linux" then
          "@rollup/rollup-linux-${npmArch}-${if hostPlatform.isMusl then "musl" else "gnu"}"
        else
          "@rollup/rollup-darwin-${npmArch}";
    in
    pkgs.buildNpmPackage rec {
      pname = "node-datachannel";
      version = sources.node-datachannel.tag;

      src = fetchGitTree sources.node-datachannel;

      npmFlags = [
        "--ignore-scripts"
      ];

      makeCacheWritable = true;

      npmDepsHash = sources.node-datachannel.npmDepsHash;

      postPatch = ''
        cp ${writeText "node-datachannel-package-lock.json" sources.node-datachannel.npmLockFile} package-lock.json
        ${pkgs.jq}/bin/jq '
          ${
            if npmOs != "darwin" then
              ''
                  (.packages | to_entries | map(
                  if .value.optionalDependencies then
                    .value.optionalDependencies |= del(.fsevents)
                  else . end
                ) | from_entries) as $patched
              ''
            else
              ""
          }
          | .packages = $patched
          | if .packages["node_modules/esbuild"]?.optionalDependencies then .packages["node_modules/esbuild"].optionalDependencies = {"${esbuildPkg}": .packages["node_modules/esbuild"].optionalDependencies["${esbuildPkg}"]} else . end
          | if .packages["node_modules/rollup"]?.optionalDependencies then .packages["node_modules/rollup"].optionalDependencies = {"${rollupPkg}": .packages["node_modules/rollup"].optionalDependencies["${rollupPkg}"]} else . end
        ' package-lock.json > package-lock.json.tmp
        mv package-lock.json.tmp package-lock.json
      '';

      nativeBuildInputs = with pkgs; [
        cmake
        pkg-config
      ];

      buildInputs = with pkgs; [
        openssl
        libdatachannel
        plog
      ];

      dontUseCmakeConfigure = true;

      env.NIX_CFLAGS_COMPILE = "-I${pkgs.nodejs-slim}/include/node";

      preBuild = ''
        # don't use static libs and don't use FetchContent
        substituteInPlace CMakeLists.txt \
            --replace-fail 'OPENSSL_USE_STATIC_LIBS TRUE' 'OPENSSL_USE_STATIC_LIBS FALSE' \
            --replace-fail 'if(NOT libdatachannel)' 'if(false)' \
            --replace-fail 'datachannel-static' 'datachannel'
        sed -i '2ifind_package(plog)' CMakeLists.txt

        # don't fetch node headers
        substituteInPlace node_modules/cmake-js/lib/dist.js \
            --replace-fail '!this.downloaded' 'false'
      '';

      installPhase = ''
        runHook preInstall
        install -Dm755 build/Release/*.node -t $out/build/Release
        runHook postInstall
      '';
    };
in
pkgs.buildNpmPackage rec {
  pname = "webtorrent.js";
  version = "1.4.7";

  src = fetchGitTree sources.mpv.webtorrent-mpv-hook;
  passthru.updateScript = pkgs.gitUpdater { rev-prefix = "v"; };

  postPatch = ''
    cp ${writeText "webtorrent-mpv-hook-package-lock.json" sources.mpv.webtorrent-mpv-hook.npmLockFile} package-lock.json
    substituteInPlace src/mpv/webtorrent.ts --replace-fail "node_path: 'node'" "node_path: '${lib.getExe pkgs.nodejs-slim}'"
    substituteInPlace package.json --replace-fail '"bin": "build/bin.mjs",' ""
  '';

  npmDepsHash = sources.mpv.webtorrent-mpv-hook.npmDepsHash;
  makeCacheWritable = true;
  npmFlags = [ "--ignore-scripts" ];

  postConfigure = ''
    # manually place our prebuilt `node-datachannel` binary into its place, since we used '--ignore-scripts'
    ln -s ${nodeDatachannel}/build node_modules/node-datachannel/build
  '';
  installPhase = ''
    cp build/webtorrent.js $out
  '';
}
