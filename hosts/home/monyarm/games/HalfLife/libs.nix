{
  config,
  lib,
  pkgs,
  sources,
  ...
}:
let
  # fetchGitTree skips submodules; these two trees need them, so fetchgit.
  fetchSub =
    source: hash:
    pkgs.fetchgit {
      inherit (source) url rev;
      fetchSubmodules = true;
      inherit hash;
    };

  # nixpkgs' pin is months behind the rolling `continuous` tag.
  xash3d = pkgs.xash3d-fwgs.overrideAttrs (_: {
    version = sources.hl.xash3d.date;
    src = fetchSub sources.hl.xash3d "sha256-qclKeXMUy7ocNp4AqkAXyFS1aSQO4vlKb1SfnTp/sMo=";
  });

  # Same waf recipe as nixpkgs' hlsdk-portable, one per game dir.
  mkLibs =
    gametype: hash:
    pkgs.stdenv.mkDerivation {
      pname = "hlsdk-portable-${gametype}";
      version = "2.4";
      src = fetchSub sources.hl.hlsdk.${gametype} hash;

      nativeBuildInputs = [
        pkgs.python3
        pkgs.wafHook
      ];
      dontAddPrefix = true;
      wafConfigureFlags = [ "-T release" ] ++ lib.optional pkgs.stdenv.hostPlatform.is64bit "-8";
      wafInstallFlags = [ "--destdir=${placeholder "out"}" ];

      meta = {
        description = "Half-Life SDK, game libraries for ${gametype}";
        license = lib.licenses.unfree;
        platforms = lib.platforms.linux;
      };
    };
in
lib.mkIf config.games.halfLife.enable {
  games.halfLife.engine = xash3d;
  games.halfLife.libs = {
    valve = mkLibs "valve" "sha256-rzU7/drGX+BnklUsv7jBgMxtHSVlaUV/wllbrKecQkc=";
    opfor = mkLibs "opfor" "sha256-ndEJVmv4L3Lz/D6xeBsDo9xcCiFs8FH3pryuXPqMwDE=";
    bshift = mkLibs "bshift" "sha256-+j4mWVSJ2JxBF88Ntj+tqvid+zg7nDxMAQkW+Z7nYO8=";
  };
}
