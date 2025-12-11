{
  lib,
  pkgs,
  linkFiles,
  ...
}:

let
  uosc = pkgs.buildGoModule rec {
    pname = "uosc";
    version = "unstable-2025-09-28";

    src = pkgs.fetchFromGitHub {
      owner = "tomasklaen";
      repo = "uosc";
      rev = "master";
      hash = "sha256-vSs6X++WIM9NfTvcsJgwiKmTuU0eu3i3cffsdCVSyV4=";
    };

    vendorHash = "sha256-u3FOhboDgdr4BswXXZwpDb2rfajbd4R8PGLEz5hRXos=";
    proxyVendor = true;

    ziggyExecutableName =
      let
        kernel = pkgs.stdenv.hostPlatform.parsed.kernel.name;
      in
      "ziggy-${kernel}" + lib.optionalString (kernel == "windows") ".exe";

    postInstall = ''
      mkdir -p $out/bin
      cp -r $src/src/uosc/* $out/
      mv $out/bin/ziggy $out/bin/${ziggyExecutableName}
    '';
  };

  ulyssescaballes-mpv-config = pkgs.fetchgit {
    url = "https://github.com/PopeyeURS/ulyssescaballes-mpv.config";
    rev = "9aa683ecfd3753134c1914c5f89d426e01c9f77c";
    sha256 = "sha256-aCwmoHp5afpelobcrNXhrtqDHdp3xzXx9YoyoAQdfa0=";
    rootDir = "portable_config";
  };

  linkMPV = folder: linkFiles "mpv/${folder}";
  mkMpvShaderOpts =
    opts:
    lib.concatStringsSep "," (
      lib.flatten (
        lib.mapAttrsToList (
          shaderName: shaderOpts:
          lib.mapAttrsToList (param: value: "${shaderName}/${param}=${toString value}") shaderOpts
        ) opts
      )
    );

in
{
  imports = [
    # keep-sorted start
    ./bindings.nix
    ./config.nix
    ./fonts.nix
    ./profiles.nix
    ./script-opts.nix
    ./scripts.nix
    ./shaders.nix
    # keep-sorted end
  ];

  _module.args = {
    inherit
      uosc
      ulyssescaballes-mpv-config
      linkMPV
      mkMpvShaderOpts
      ;
  };

  programs.mpv = {
    enable = true;
  };
}
