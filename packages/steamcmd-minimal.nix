{
  lib,
  buildFHSEnv,
  ...
}:

# steamcmd binary only need plain 32-bit glibc -- nixpkgs' own package
# wraps it in `steam-run`'s whole fhs rootfs (~2.7GB) instead, overkill here.
buildFHSEnv {
  name = "steamcmd-minimal";
  targetPkgs = p: [ p.pkgsi686Linux.glibc ];
  runScript = "bash";

  meta = {
    description = "Minimal FHS environment for running steamcmd's raw Linux binary, without steam-run's desktop-app closure";
    mainProgram = "steamcmd-minimal";
    platforms = lib.platforms.linux;
  };
}
