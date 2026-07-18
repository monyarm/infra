{
  lib,
  pkgs,
  linkFiles,
  parallel,
  sources,
  fetchGitTree,
  ...
}:

let
  uosc = pkgs.buildGoModule rec {
    pname = "uosc";
    version = "unstable-${sources.mpv.uosc.date}";

    src = fetchGitTree sources.mpv.uosc;

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
    # outdated, but still works; No need to update
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
        parallel (lib.mapAttrsToList (
          shaderName: shaderOpts:
          parallel (lib.mapAttrsToList (param: value: "${shaderName}/${param}=${toString value}")) shaderOpts
        )) opts
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
