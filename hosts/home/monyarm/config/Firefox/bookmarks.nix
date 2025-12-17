{
  importSopsNix,
  urlEncodeEucJp,
  ...
}:
let
  # Helper functions
  mkBookmark = name: url: {
    inherit name url;
  };
  mkFolder = name: bookmarks: {
    inherit name bookmarks;
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
    (mkBookmark "Downloads - Yog-Sothoth" (yogSothoth "files"))
    (mkBookmark "[YSDC] Into The Deep" (yogSothoth "wiki/index.php/Main_Page"))
    (seesaaWiki 1)
    (seesaaWiki 2)
  ];

  miniatureBookmarks = [
    (mkBookmark "Miniatures | Miniset.net - Miniatures Collectors Guide" "https://miniset.net/persons/juan-diaz/sculpts")
    (mkBookmark "Kingdom Death Minis Recasts from China on Aliexpress" "https://pandahelper.com/kingdom-death-minis-recasts-from-china/")
    (mkBookmark "Gormiti Series III by Giochi Preziosi ~ Rubberfever" "http://www.rubberfever.com/?section=collections&voice=gormiti3")
    (mkBookmark "MinifiguresXD: Gormiti" "http://minifigures.blogspot.com/2008/04/gormiti.html")
  ];
in
{
  programs.firefox.profiles.default.bookmarks = {
    force = true;
    settings = [
      {
        name = "Bookmarks Toolbar";
        toolbar = true;
        bookmarks = [
          (mkBookmark "Superpower" "https://powerlisting.fandom.com/wiki/Special:Random/main")
          (mkBookmark "Random Card" (scryfall "random"))
          (mkBookmark "Random Commander" (scryfall "random?q=is:commander"))
          (mkBookmark "Sentai Collectibles – GrnRngr.com" "https://www.grnrngr.com/sentai/collectibles")
          (mkFolder "Call of Cthulhu" cthulhuBookmarks)
          (mkFolder "Tabletop Minatures" miniatureBookmarks)
        ]
        ++ (importSopsNix ./bookmarks-private.sops.nix);
      }
    ];
  };
}
