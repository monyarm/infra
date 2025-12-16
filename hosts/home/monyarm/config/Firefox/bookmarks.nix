{
  importSopsNix,
  urlEncodeEucJp,
  ...
}:
let
  # Helper functions
  mkToolbar = name: url: {
    inherit name url;
    toolbar = true;
  };
  mkToolbarFolder = name: bookmarks: {
    inherit name bookmarks;
    toolbar = true;
  };

  # URL builders
  scryfall = path: "https://scryfall.com/${path}";
  yogSothoth = path: "https://www.yog-sothoth.com/${path}";
  seesaaWiki = num: {
    name = "Scenario placement <${toString num}> - Cthulhu Mythology TRPG Yarozu Wiki";
    url = urlEncodeEucJp "https://seesaawiki.jp/trpgyarouzu/d/シナリオ置き場≪${toString num}≫";
  };

  # Bookmark collections
  cthulhuBookmarks = [
    {
      name = "Downloads - Yog-Sothoth";
      url = yogSothoth "files";
    }
    {
      name = "[YSDC] Into The Deep";
      url = yogSothoth "wiki/index.php/Main_Page";
    }
    (seesaaWiki 1)
    (seesaaWiki 2)
  ];

  miniatureBookmarks = [
    {
      name = "Miniatures | Miniset.net - Miniatures Collectors Guide";
      url = "https://miniset.net/persons/juan-diaz/sculpts";
    }
    {
      name = "Kingdom Death Minis Recasts from China on Aliexpress";
      url = "https://pandahelper.com/kingdom-death-minis-recasts-from-china/";
    }
    {
      name = "Gormiti Series III by Giochi Preziosi ~ Rubberfever";
      url = "http://www.rubberfever.com/?section=collections&voice=gormiti3";
    }
    {
      name = "MinifiguresXD: Gormiti";
      url = "http://minifigures.blogspot.com/2008/04/gormiti.html";
    }
  ];
in
{
  programs.firefox.profiles.default.bookmarks = {
    force = true;
    settings = [
      (mkToolbar "Superpower" "https://powerlisting.fandom.com/wiki/Special:Random/main")
      (mkToolbar "Sentai Collectibles – GrnRngr.com" "https://www.grnrngr.com/sentai/collectibles")
      (mkToolbarFolder "Call of Cthulhu" cthulhuBookmarks)
      (mkToolbar "Random Card" (scryfall "random"))
      (mkToolbar "Random Commander" (scryfall "random?q=is:commander"))
      (mkToolbarFolder "Tabletop Minatures" miniatureBookmarks)
    ]
    ++ (importSopsNix ./bookmarks-private.sops.nix);
  };
}
