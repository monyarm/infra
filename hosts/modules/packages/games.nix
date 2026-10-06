# Game-adjacent tooling: ROM utilities and account helpers rather than
# emulators themselves (those live in hosts/home/monyarm/games/Emulation/).
# Home-manager only.
{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    ccd2iso
    gamescope
    # mame's `tools` OUTPUT -- chdman, romcmp, unidasm, split (as mame-split),
    # castool and friends. Same drvPath as pkgs.mame, but mame alone only
    # exposes $out, so the tools would not be on PATH.
    mame-tools
    maxcso
    steamguard-cli
  ];
}
