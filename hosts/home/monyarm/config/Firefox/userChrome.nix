{ pkgs, ... }:
let
  fetchChromeRepo =
    {
      url,
      sha256,
    }:
    let
      pname = (pkgs.lib.splitString "/" url) ++ [ "" ];
      pname' = pkgs.lib.last (pkgs.lib.init pname);
      src = pkgs.fetchgit {
        url = "${url}";
        inherit sha256;
      };
    in
    pkgs.runCommand "${pname'}-chrome" { inherit pname'; } ''
      mkdir -p $out
      cp -r ${src} $out
      if [ -d $out/chrome ]; then
        mv $out/chrome/* $out/
        rmdir $out/chrome
      fi
      if [ -f $out/userChrome.css ]; then
        mv $out/userChrome.css $out/${pname'}-userChrome.css
      fi
      if [ -f $out/userContent.css ]; then
        mv $out/userContent.css $out/${pname'}-userContent.css
      fi
    '';

  userChromeRepos = builtins.map fetchChromeRepo [
    {
      url = "https://github.com/CarterSnich/firefox-xtra-compact";
      sha256 = "sha256-6/Yncqb5pb7AgJAYvvtL1b2nXZOThr7aPAUXM7eY/dA=";
    }
  ];

  concatUserChromes = pkgs.lib.concatStringsSep "\n" (
    map
      (repo: ''
        /* Sourced from ${repo.pname'} */
        ${pkgs.lib.readFile (repo + "/${repo.pname'}-userChrome.css")}
      '')
      (
        pkgs.lib.filter (
          repo: pkgs.lib.pathExists (repo + "/${repo.pname'}-userChrome.css")
        ) userChromeRepos
      )
  );

  concatUserContents = pkgs.lib.concatStringsSep "\n" (
    map
      (repo: ''
        /* Sourced from ${repo.pname'} */
        ${pkgs.lib.readFile (repo + "/${repo.pname'}-userContent.css")}
      '')
      (
        pkgs.lib.filter (
          repo: pkgs.lib.pathExists (repo + "/${repo.pname'}-userContent.css")
        ) userChromeRepos
      )
  );

  userChrome = concatUserChromes + ''
    :root { --tabpanel-background-color: #00000000 !important; }
  '';
  userContent = concatUserContents + ''
    :root {
      --in-content-page-background: #00000000 !important;
      --in-content-box-background: #00000088 !important;
    }
  '';
in
{
  home.file.".mozilla/firefox/default/chrome/" = {
    recursive = true;
    source = pkgs.symlinkJoin {
      name = "user-chrome";
      paths = userChromeRepos;
    };
  };

  programs.firefox.profiles.default = {
    inherit userChrome userContent;
  };
}
