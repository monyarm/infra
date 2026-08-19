{
  lib,
  pkgs,
  buildFHSEnv,
  ...
}:

# steamcmd binary only need plain 32-bit glibc -- nixpkgs' own package
# wraps it in `steam-run`'s whole fhs rootfs (~2.7GB) instead, overkill here.
# Reuses pkgs.steamcmd.src (the same archived Valve bootstrapper tarball
# nixpkgs' own steamcmd derivation fetches) rather than pinning our own copy.
buildFHSEnv {
  name = "steamcmd-minimal";
  targetPkgs = p: [
    p.pkgsi686Linux.glibc
    p.gnutar
    p.gzip
  ];
  runScript = pkgs.writeShellScript "steamcmd-minimal-run" ''
    set -e
    STEAMROOT="''${STEAMCMD_ROOT:-$HOME/.steamcmd}"
    mkdir -p "$STEAMROOT"
    if [ ! -e "$STEAMROOT/steamcmd.sh" ]; then
      tar -xzf ${pkgs.steamcmd.src} -C "$STEAMROOT"
    fi
    exec "$STEAMROOT/steamcmd.sh" "$@"
  '';

  meta = {
    description = "Minimal FHS environment for running steamcmd's raw Linux binary, without steam-run's desktop-app closure";
    mainProgram = "steamcmd-minimal";
    platforms = lib.platforms.linux;
  };
}
