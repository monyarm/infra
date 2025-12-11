{
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
    Pictures = "${HOME}/Pictures";
    hmConfig = "${HM}/config";
    hosts = "${repo}/hosts";
    lib = "${repo}/lib";
    modules = "${hosts}/modules";
    secrets = "${repo}/secrets";
    wallpapers = "${Pictures}/wallpapers";
    webdav = "${xdg.config}/webdav";
    # keep-sorted end
  };

}
