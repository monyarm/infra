{
  lib,
  pkgs,
  uosc,
  ulyssescaballes-mpv-config,
  linkMPV,
  ...
}:

let
  mkSimpleLuaScript =
    {
      pname,
      version,
      src,
      scriptPath ? pname,
    }:
    pkgs.stdenv.mkDerivation rec {
      inherit pname version src;
      installPhase = ''
        cp $src/${scriptPath} $out
      '';
    };

  mpvInteractiveVideo = mkSimpleLuaScript {
    pname = "interactive-video.lua";
    version = "unstable-2019-09-20";
    src = pkgs.fetchFromGitHub {
      owner = "mosquito-byte";
      repo = "mpv-interactive-video";
      rev = "0018812d44b17168410dd8eb2f16c64604ac2076";
      sha256 = "sha256-n3OCM1hhD0XgNpjUzsPedzQUo58h5J2hayiwDVnGsLQ=";
    };
  };

  guess-media-title = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/zenwarr/mpv-config/refs/heads/master/scripts/guess-media-title.lua";
    sha256 = "sha256-lKFqWst4ol/JPIfYTzAnIxuqiL11gE6dLoBXIcWGbU4=";
  };

  mpvCoverArt = mkSimpleLuaScript {
    pname = "coverart.lua";
    version = "unstable-2021-04-07";
    src = pkgs.fetchFromGitHub {
      owner = "CogentRedTester";
      repo = "mpv-coverart";
      rev = "6ee71b97db10906bf0c97dc1e1a68305b4892c4a";
      sha256 = "sha256-igSjrnFpzblLWyF5+7rbGRU7TDtgw1S3NLGsoHrDL1c=";
    };
  };

  mpvLRC = pkgs.stdenv.mkDerivation rec {
    pname = "mpv-lrc";
    version = "unstable-2025-09-22";
    src = pkgs.fetchFromGitHub {
      owner = "guidocella";
      repo = "mpv-lrc";
      rev = "bb1c653a05e382dddef1f702745be76c17f786d0";
      sha256 = "sha256-fQCMYWvXrZ3KuXI3cQHKHyC4zKP++K+D+98Ilt2vfII=";
    };
    installPhase = ''
      mkdir -p $out
      cp $src/lrc.lua $out/main.lua
      cp $src/lrc.sh $src/lrc.vim $src/chinese-to-kanji.txt $out/
    '';
  };

  mpvScrollList = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/CogentRedTester/mpv-scroll-list/b8a3498b35fbb1d1d08aff98079acdb0da672277/scroll-list.lua";
    sha256 = "sha256-Jyw1hj4ptUYjtff8NlyGNvVBc07R11G3EWy3kYWbY0k=";
  };

  mpvDvdBrowser = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/CogentRedTester/mpv-dvd-browser/refs/heads/master/dvd-browser.lua";
    sha256 = "sha256-LZRKLdz3i9TakaD1RSbF+fpipXQ88wp8yy+MODQ7pmk=";
  };

  mpvSegmentLinking = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/CogentRedTester/mpv-segment-linking/master/segment-linking.lua";
    sha256 = "sha256-UwwYT6FP+MVVIpV3EMm2LgYqdgsrjGcoPXjQQlwpS08=";
  };

  mpvSponsorblockMinimal = pkgs.fetchurl {
    url = "https://codeberg.org/jouni/mpv_sponsorblock_minimal/raw/branch/master/sponsorblock_minimal.lua";
    sha256 = "sha256-PPlQGE4YZczpPhVsV+JMWtozvUpDmoUoaGIISy9uc7U=";
  };

  mpv360 = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/kasper93/mpv360/master/scripts/mpv360.lua";
    sha256 = "sha256-SBFe3MeWOh953crDYcSjv2ctT1qc0IW/cIDcxAEmJs8=";
  };

  galleryDlHook = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/jgreco/mpv-scripts/refs/heads/master/gallery-dl_hook.lua";
    sha256 = "sha256-6qAVOR5+KcEVsBDFoYrEyZlmVM7JqQa9sTYsPHMZTKs=";
  };

  nodeDatachannel = pkgs.buildNpmPackage rec {
    pname = "node-datachannel";
    version = "0.10.1";

    src = pkgs.fetchFromGitHub {
      owner = "murat-dogan";
      repo = "node-datachannel";
      rev = "refs/tags/v${version}";
      hash = "sha256-r5tBg645ikIWm+RU7Muw/JYyd7AMpkImD0Xygtm1MUk=";
    };

    npmFlags = [ "--ignore-scripts" ];

    makeCacheWritable = true;

    npmDepsHash = "sha256-1ZJd0Y45B3CT2YPXDYfCuFMBo5uggWRuDH11eCobyyY=";

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

  celebi = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/po5/celebi/master/celebi.lua";
    sha256 = "16hj99mdf0i44qksha1iqnj94mgqb2n76a2n0h5lavlnldnqd722";
  };

  evafast = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/po5/evafast/master/evafast.lua";
    sha256 = "07f248102g31l9dkilzv8fycfj3p6ywc7xlpazmmxl9cgj29cjjj";
  };

  memo = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/po5/memo/master/memo.lua";
    sha256 = "17ihhs9vwhyhbgwm826lk67h9281bzk38rvi8qnn1mm8flizaw46";
  };

  mpris = pkgs.stdenv.mkDerivation rec {
    pname = "mpris.so";
    version = "1.1";

    src = pkgs.fetchFromGitHub {
      owner = "hoyon";
      repo = "mpv-mpris";
      rev = "1.1";
      sha256 = "sha256-vZIO6ILatIWa9nJYOp4AMKwvaZLahqYWRLMDOizyBI0=";
    };

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

  thumbfast = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/po5/thumbfast/master/thumbfast.lua";
    sha256 = "0j7la7vrlf72bas0w06cb9xv7gs9nmvsrkbx67wifrxkh4y4xxl1";
  };

  trackselect = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/po5/trackselect/master/trackselect.lua";
    sha256 = "0carzv88v9cd3lqxxcvp7gfsm8av4ya8jn3h2ygbmzsfp4g10b0i";
  };

  auto-save-state = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/AN3223/dotfiles/master/.config/mpv/scripts/auto-save-state.lua";
    sha256 = "00v0gifa7n1jvgchw21icxzalhbncs5s55p7i2f20wccsklj03sq";
  };

  quality-menu = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/christoph-heinrich/mpv-quality-menu/refs/heads/master/quality-menu.lua";
    sha256 = "sha256-pf2/3JvZDYfKEqNCmHPQjuRuq2WNPXg10kFOtBbEY9A=";
  };

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
      guess-media-title
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
