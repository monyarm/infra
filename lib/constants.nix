{ lib, ... }:
rec {
  alphabets = builtins.stringToCharacters "abcdefghijklmnopqrstuvwxyz";
  dirs = rec {
    HOME = builtins.getEnv "HOME";
    repo = "${HOME}/.nix";
    xdg = {
      config = "${HOME}/.config";
    };
    # keep-sorted start
    Games = "/mnt/Media/Games";
    HM = "${hosts}/home/monyarm";
    hmConfig = "${HM}/config";
    hosts = "${repo}/hosts";
    lib = "${repo}/lib";
    modules = "${hosts}/modules";
    secrets = "${repo}/secrets";
    wallpapers = "${HOME}/Pictures/wallpapers";
    webdav = "${xdg.config}/webdav";
    # keep-sorted end
  }
  // (lib.genAttrs [
    # keep-sorted start
    "Documents"
    "Downloads"
    "Music"
    "Pictures"
    "Videos"
    #keep-sorted end
  ] (name: "${dirs.HOME}/${name}"));

}
