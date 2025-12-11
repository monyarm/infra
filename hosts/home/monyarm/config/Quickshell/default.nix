{ dirs, mkOutOfStoreSymlinkRecursive, ... }:

{
  imports = [
    # keep-sorted start
    ./color.nix
    # keep-sorted end
  ];
  xdg.configFile = mkOutOfStoreSymlinkRecursive "${dirs.hmConfig}/Quickshell/.config/quickshell";
}
