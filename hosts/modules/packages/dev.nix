# Developer toolchain: language runtimes, C/C++ cross support, and the
# library headers needed to build against. Home-manager only -- the gentoo
# system-manager host is a server and has no use for a bare-metal ARM
# toolchain or a dev environment.
{
  lib,
  pkgs,
  ...
}:
let
  # Each lib plus its .dev output, if any. The lib itself stays: several
  # are dlopen'd at runtime (SDL2, libvpx, openh264), so the shared object
  # matters, not just the headers.
  libs = lib.concatMap (p: [ p ] ++ lib.optional (p ? dev) p.dev) (
    with pkgs;
    [
      SDL2
      SDL2_net
      a52dec
      curl
      faad2
      flac
      fluidsynth
      freetype
      fribidi
      giflib
      gtk3
      libjpeg
      libmad
      libmikmod
      libmpeg2
      libogg
      libpng
      libtheora
      libvorbis
      libvpx
      openh264
      speechd
      vips
      zlib
      # xorgproto deliberately absent: it ships the same
      # include/X11/extensions/*.h as libx11.dev, and home.packages is one
      # buildEnv, which hard-fails on conflicting subpaths. libx11.dev wins.
      libx11
    ]
  );

  armEmbedded = with pkgs; [
    # Already carries newlib 4.6.0.20260123 + binutils 2.46, matching
    # devkitARM r68's floor. No devkitPro flake needed. No arm-none-eabi-gdb
    # exists in nixpkgs (devkitARM ships none either) -- debug via qemu+openocd.
    pkgsCross.arm-embedded.stdenv.cc
    openocd
    qemu
  ];

  toolchain = with pkgs; [
    android-tools
    autoconf
    automake
    clang-tools
    cmake
    direnv
    gdb
    gnumake
    libtool
    meson
    ninja
    nix-direnv
    pkg-config
    radare2
    valgrind
    yarn
  ];

  runtimes = with pkgs; [
    cargo
    beamPackages.elixir
    luajit
    luarocks
    nim
    nimble
    jdk
    nodejs
    sops
    typescript
  ];

  tooling = with pkgs; [
    dotnet-sdk_8
    espeak-ng
    hyperfine
    rust-analyzer
  ];

  # One interpreter on PATH with the libraries actually importable. Loose
  # python3Packages entries are not: home.packages is one buildEnv, so
  # python3Packages.numpy drops its site-packages where no interpreter looks.
  pythonEnv = pkgs.python3.withPackages (
    ps: with ps; [
      aiohttp
      beautifulsoup4
      capstone
      click
      cryptography
      httpx
      lxml
      numpy
      pandas
      pillow
      pydantic
      pytest
      pyyaml
      requests
      rich
      tqdm
    ]
  );
in
{
  programs.gcc.enable = true;
  programs.gh.enable = true;

  home.packages = libs ++ armEmbedded ++ toolchain ++ runtimes ++ tooling ++ [ pythonEnv ];
}
