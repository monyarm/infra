{
  lib,
  pkgs,
  uosc,
  ulyssescaballes-mpv-config,
  linkMPV,
  sources,
  fetchGitTree,
  getFile,
  ...
}:
let

  fetchLua = name: fetchGitTree sources.mpv."${name}" |> getFile "${name}.lua";

  mpvInteractiveVideo = fetchLua "interactive-video";

  guessMediaTitle =
    fetchGitTree sources.mpv.zenwarr-config |> getFile "scripts/guess-media-title.lua";

  mpvCoverArt = fetchLua "coverart";

  mpvLRC = pkgs.stdenv.mkDerivation rec {
    pname = "mpv-lrc";
    version = "unstable-${sources.mpv.lrc.rev}";
    src = fetchGitTree sources.mpv.lrc;
    installPhase = ''
      mkdir -p $out
      cp $src/lrc.lua $out/main.lua
      cp $src/lrc.sh $src/lrc.vim $out/ # Used to also have chinese-to-kanji.txt
    '';
  };

  mpvScrollList = fetchLua "scroll-list";

  mpvDvdBrowser = fetchLua "dvd-browser";

  mpvSegmentLinking = fetchLua "segment-linking";

  mpvSponsorblockMinimal = fetchLua "sponsorblock_minimal";

  mpv360 = fetchGitTree sources.mpv.mpv360 |> getFile "scripts/mpv360.lua";

  galleryDlHook = fetchGitTree sources.mpv.jgreco-scripts |> getFile "gallery-dl_hook.lua";

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

      # esbuild: @esbuild/{os}-{arch}, no libc suffix
      esbuildPkg = "@esbuild/${npmOs}-${npmArch}";

      # rollup: linux needs a gnu/musl suffix; darwin has none
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

      npmDepsHash = "sha256-bQqz6v7oVhTx9xHpMW8G1OxyKVhbuox0qnDKcKHfn4s=";

      postPatch = ''
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
          | .packages["node_modules/esbuild"].optionalDependencies = {"${esbuildPkg}": .packages["node_modules/esbuild"].optionalDependencies["${esbuildPkg}"]}
          | .packages["node_modules/rollup"].optionalDependencies = {"${rollupPkg}": .packages["node_modules/rollup"].optionalDependencies["${rollupPkg}"]}
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

  webtorrentMpvHook = pkgs.buildNpmPackage rec {
    pname = "webtorrent.js";
    version = "1.4.4";

    src = pkgs.fetchFromGitHub {
      owner = "mrxdst";
      repo = pname;
      tag = "webtorrent-mpv-hook";
      hash = "sha256-qFeQBVPZZFKkxz1fhK3+ah3TPDovklhhQwtv09TiSqo=";
    };
    passthru.updateScript = pkgs.gitUpdater { rev-prefix = "v"; };

    postPatch = ''
      substituteInPlace src/webtorrent.ts --replace-fail "node_path: 'node'" "node_path: '${lib.getExe pkgs.nodejs-slim}'"
      substituteInPlace package.json --replace-fail '"bin": "build/bin.mjs",' ""
      rm -rf src/bin.ts
    '';

    npmDepsHash = "sha256-fKzXdbtxC2+63/GZdvPOxvBpQ5rzgvfseigOgpP1n5I=";
    makeCacheWritable = true;
    npmFlags = [ "--ignore-scripts" ];

    postConfigure = ''
      # manually place our prebuilt `node-datachannel` binary into its place, since we used '--ignore-scripts'
      ln -s ${nodeDatachannel}/build node_modules/node-datachannel/build
    '';
    installPhase = ''
      cp build/webtorrent.js $out
    '';
  };

  celebi = fetchLua "celebi";

  evafast = fetchLua "evafast";

  memo = fetchLua "memo";

  mpris = pkgs.stdenv.mkDerivation rec {
    pname = "mpris.so";
    version = sources.mpv.mpris.tag;

    src = fetchGitTree sources.mpv.mpris;

    nativeBuildInputs = with pkgs; [ pkg-config ];
    buildInputs = with pkgs; [
      mpv-unwrapped
      glib
      ffmpeg-headless
    ];

    installPhase = ''
      mv mpris.so $out
    '';
  };

  thumbfast = fetchLua "thumbfast";

  trackselect = fetchLua "trackselect";

  auto-save-state =
    fetchGitTree sources.mpv.AN3223-dotfiles |> getFile ".config/mpv/scripts/auto-save-state.lua";

  quality-menu = fetchLua "quality-menu";

  linkMPVScripts = linkMPV "scripts";
  linkMPVScriptModules = linkMPV "script-modules";
in
{
  xdg.configFile =
    (linkMPVScripts [
      # keep-sorted start
      "${ulyssescaballes-mpv-config}/scripts/file-name-sub-paths.lua"
      auto-save-state
      celebi
      evafast
      galleryDlHook
      guessMediaTitle
      memo
      mpris
      mpv360
      mpvCoverArt
      mpvDvdBrowser
      mpvInteractiveVideo
      #metadataOSD
      mpvLRC
      mpvSegmentLinking
      mpvSponsorblockMinimal
      quality-menu
      thumbfast
      trackselect
      uosc
      webtorrentMpvHook
      # mpvremote # looks for file in wrong place
      # { "mpvremote/remote.db" = "${dirs.config}/MPV/scripts/mpvremote/remote.db"; } # Now handled by linkMpvScripts
      # keep-sorted end
    ])
    // (linkMPVScriptModules [
      # keep-sorted start
      mpvScrollList
      # keep-sorted end
    ]);

}
