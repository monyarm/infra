# Developer toolchain: language runtimes, C/C++ cross support, and the
# library headers needed to build against. Home-manager only -- the gentoo
# system-manager host is a server and has no use for a bare-metal ARM
# toolchain or a dev environment.
{
  pkgs,
  ...
}:
let
  # Header-only/dev outputs. The non-".dev" entries are kept deliberately:
  # several are dlopen'd at runtime (SDL2, libvpx, openh264), so the shared
  # object itself matters, not just the headers.
  libs = with pkgs; [
    SDL2
    SDL2.dev
    freetype
    freetype.dev
    libmpeg2
    libogg
    libogg.dev
    libpng
    libpng.dev
    libvorbis
    libvorbis.dev
    libvpx
    libvpx.dev
    libvpx.out
    libx11.dev
    openh264
    openh264.dev
    vips.dev
    # xorgproto deliberately absent: it ships the same
    # include/X11/extensions/*.h as libx11.dev, and home.packages is one
    # buildEnv, which hard-fails on conflicting subpaths. libx11.dev wins.
    xorg.libX11
  ];

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
    direnv
    gdb
    gnumake
    pkg-config
    radare2
    valgrind
    yarn
  ];

  runtimes = with pkgs; [
    cargo
    elixir
    luajit
    luarocks
    nim
    nimble
    nodejs
    sops
  ];

  tooling = with pkgs; [
    dotnet-sdk_8
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
