{ pkgs, ... }:
{
  vampireSurvivors01 = pkgs.fetchurl {
    url = "https://shared.fastly.steamstatic.com/community_assets/images/items/1794680/dd5dcd2d70a02549946e556fc5a93f4ddedb711d.jpg";
    sha256 = "19apiiwhr0yhl0aq7yri2k7sh9r70nk0i5g993hq6w6436h69cdc";
  };
}
