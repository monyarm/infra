{ lib, ... }:
rec {
  alphabets = builtins.stringToCharacters "abcdefghijklmnopqrstuvwxyz";

  user = {
    name = "monyarm";
    email = "monyarm@gmail.com";
    fullName = "Simeon Armenchev";
  };

  stateVersion = "24.11";
  timeZone = "Europe/Sofia";

  bluetoothMacs = {
    headphones = "A4:77:58:76:71:A5";
    proController = "E4:17:D8:CE:B3:0B";
  };

  dirs = rec {
    HOME = builtins.getEnv "HOME";
    repo = "${HOME}/.nix";
    xdg = {
      config = "${HOME}/.config";
    };
    # keep-sorted start
    Games = "/mnt/Media/Games";
    HM = "${hosts}/home/monyarm";
    MediaSSD = "/mnt/mediaSSD";
    SteamLibrarySSD = "${dirs.MediaSSD}/SteamLibrary";
    hmConfig = "${HM}/config";
    hosts = "${repo}/hosts";
    lib = "${repo}/lib";
    modules = "${hosts}/modules";
    scripts = "${repo}/scripts";
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
