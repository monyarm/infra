{
  lib,
  binFile,
  ...
}:

with lib;

{
  xdg.configFile."yay/config.json".text = builtins.toJSON {
    aururl = "https://aur.archlinux.org";
    buildDir = "$HOME/.cache/yay";
    absdir = "$HOME/.cache/yay/abs";
    editor = "";
    editorflags = "";
    makepkgbin = "/home/monyarm/.local/bin/custpkg";
    makepkgconf = "";
    pacmanbin = "pacman";
    pacmanconf = "/etc/pacman.conf";
    redownload = "no";
    rebuild = "no";
    batchinstall = false;
    answerclean = "";
    answerdiff = "";
    answeredit = "";
    answerupgrade = "";
    gitbin = "git";
    gpgbin = "gpg";
    gpgflags = "";
    mflags = "--skippgpcheck";
    sortby = "votes";
    searchby = "name-desc";
    gitflags = "";
    removemake = "ask";
    sudobin = "sudo";
    sudoflags = "";
    requestsplitn = 150;
    sortmode = 0;
    completionrefreshtime = 7;
    sudoloop = true;
    timeupdate = false;
    devel = false;
    cleanAfter = false;
    provides = true;
    pgpfetch = false;
    upgrademenu = true;
    cleanmenu = true;
    diffmenu = true;
    editmenu = false;
    combinedupgrade = false;
    useask = false;
  };

  home.file = binFile ./.local/bin/custpkg;
}
