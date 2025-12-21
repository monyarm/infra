{ pkgs, ... }:

{
  groupShotRivals = pkgs.fetchurl {
    url = "https://pbs.twimg.com/media/GQCEbiiXsAAs70X?format=jpg&name=4096x4096";
    hash = "sha256-601XJGckbRUeVk2Cfa7ddXvVuXHQYs/PgEkIGjA72K4=";
    name = "marvel-rivals-group.jpg";
  };

  fantasticFourRivals = pkgs.fetchurl {
    url = "https://pbs.twimg.com/media/GgTZbWjbEAEJARv?format=jpg&name=4096x4096";
    hash = "sha256-GZDvpyCJsqnso0E+QZKEj8R5xmjWcRQCcRaHzWvzKVs=";
    name = "fantastic-four-rivals.jpg";
  };
}
