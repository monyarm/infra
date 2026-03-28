{ pkgs, fetchPixiv, ... }:

{
  groupShotRivals = pkgs.fetchurl {
    url = "https://pbs.twimg.com/media/GQCEbiiXsAAs70X?format=jpg&name=4096x4096";
    hash = "sha256-601XJGckbRUeVk2Cfa7ddXvVuXHQYs/PgEkIGjA72K4=";
    name = "marvel-rivals-group.jpg";
  };
  spiderverse01 = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2018/12/22/17/03/20/72227113_p0.jpg";
    sha256 = "sha256-xapiub3KA6GlheZA2B/C30khpQukF5LEAht7VeAXksg=";
  };
  fantasticFourRivals = pkgs.fetchurl {
    url = "https://pbs.twimg.com/media/GgTZbWjbEAEJARv?format=jpg&name=4096x4096";
    hash = "sha256-GZDvpyCJsqnso0E+QZKEj8R5xmjWcRQCcRaHzWvzKVs=";
    name = "fantastic-four-rivals.jpg";
  };
}
