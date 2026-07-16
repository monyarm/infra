{
  lib,
  dirs,
  mkOutOfStoreSymlink,
  ...
}:

with lib;

{
  imports = [
    # keep-sorted start
    ./config.nix
    ./firmware.nix
    # keep-sorted end
  ];

  xdg.dataFile."scummvm/saves".source =
    mkOutOfStoreSymlink "${dirs.hmConfig}/ScummVM/.local/share/scummvm/saves";
}
