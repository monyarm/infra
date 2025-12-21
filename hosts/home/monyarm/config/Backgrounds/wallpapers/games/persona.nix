{ pkgs, fetchSteamCards, ... }:
{
  persona5ThePhantomX01 = pkgs.fetchurl {
    url = "https://persona5x.com/assets/images/common/fankit/wallpaper/wallpaper01.jpg";
    sha256 = "09d8qc6fqvh4kg9n4034pyg9hp4sc2k0fkixf29ifjwdb85lv3gz";
  };

  persona5ThePhantomX02 = pkgs.fetchurl {
    url = "https://persona5x.com/assets/images/common/fankit/wallpaper/wallpaper03.jpg";
    sha256 = "0y7mvjlwffbmp9hbm0r79i2fick627ixscyvr4v3q06bz2whwaxr";
  };

  smashUltimateTrueEnding = pkgs.fetchurl {
    name = "smash-ultimate-true-ending.jpg";
    url = "https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/8aef7915-980a-4d4b-a5b5-656ef9888d35/dcxgor6-a15d647b-3662-4b96-b237-84ab196820e6.jpg?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsIm9iaiI6W1t7InBhdGgiOiIvZi84YWVmNzkxNS05ODBhLTRkNGItYTViNS02NTZlZjk4ODhkMzUvZGN4Z29yNi1hMTVkNjQ3Yi0zNjYyLTRiOTYtYjIzNy04NGFiMTk2ODIwZTYuanBnIn1dXSwiYXVkIjpbInVybjpzZXJ2aWNlOmZpbGUuZG93bmxvYWQiXX0.yleJ4LeSkR35tTccp9ckOfd9qflyqZKRBwqTCoTweiA";
    sha256 = "sha256-IjpsTg2hJ7jRsMoiRnrXRLFglsLp6sAihcnvuDbEij0=";
  };

  persona5RoyalCards = fetchSteamCards {
    appId = 1687950;
    hash = "sha256-knRE2S5Ae4TyhrBlRRossmXUmTNaZjJvcBoOPEeINrw=";
  };

  persona4Golden = fetchSteamCards {
    appId = 1113000;
    hash = "sha256-W9pC2A1FVMuoKWD4LfXXDxtnOvnWf+WOQ/kGBcUZGrA=";
  };

  persona3Reload = fetchSteamCards {
    appId = 2161700;
    hash = "sha256-Z6/pCCytvcj2cgonADcI8dRSnMt9MDB4eGtrtZ1trGA=";
  };

  persona5Strikers = fetchSteamCards {
    appId = 1382330;
    hash = "sha256-hiXnYeq6LlfBoZW9d2zah8jk2bzRg7iRvQWv0IJUbgE=";
  };

  persona3Portable = fetchSteamCards {
    appId = 1809700;
    hash = "sha256-y1EeyuCqVACxDnu0hvQmT5tHYYoAF1lEye3R8ZASOTU=";
  };

  persona5Tactica = fetchSteamCards {
    appId = 2254740;
    hash = "sha256-yYzJuhRMUfF2oGUy7xjrS9gc7OJ7TnwCNQbaMMSFi6w=";
  };

  persona4ArenaUltimax = fetchSteamCards {
    appId = 1602010;
    hash = "sha256-AZkkPpZrmvJHHbO9t/KkA+m6edEQ/F7/aLgjMEYRRa8=";
  };
}
