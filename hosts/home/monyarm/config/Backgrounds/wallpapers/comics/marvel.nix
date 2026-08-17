{
  pkgs,
  fetchPixiv,
  image,
  ...
}:
with image;
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

  xLadiesBikini =
    pkgs.fetchurl {
      url = "https://pbs.twimg.com/media/E7qCGPRWEAAqv-b?format=jpg&name=4096x4096";
      name = "xLadiesBikini.jpg";
      hash = "sha256-Ci0xesplSwWkV5QVX7FYznGBiROfdrBY34Xg+0EAaJY=";
    }
    |> crop16x9;

  ladyLoki = pkgs.fetchurl {
    url = "https://pbs.twimg.com/media/HMZ5rPlaQAA8EYT?format=jpg&name=4096x4096";
    name = "ladyLoki.jpg";
    hash = "sha256-nfcfjzAhql4GgtQizB66vhkHGWio4MAWJ4MY8w8Fcdo=";
  };

  ladyLokiEmmaBikini =
    pkgs.fetchurl {
      url = "https://pbs.twimg.com/media/HLcnrYUW4AATHcL?format=jpg&name=4096x4096";
      name = "ladyLokiEmmaBikini.jpg";
      hash = "sha256-pWWHz8cxU8BzPPbMsJZBMeXIn2VFIgJcxL9/m8M0A+c=";
    }
    |> crop16x9North;

  moonKnightKonshu =
    pkgs.fetchurl {
      url = "https://pbs.twimg.com/media/HLvy1EyboAA-dP3?format=jpg&name=4096x4096";
      name = "moonKnightKonshu.jpg";
      hash = "sha256-YBC/OBIxfL0iLQCN0blXkmg4k4BXqCsjHUSgchHj0Ds=";
    }
    |> crop16x9West;

  punisherSpawnGhostRiderRedHood =
    pkgs.fetchurl {
      url = "https://pbs.twimg.com/media/HDd7786a0AAvukx?format=jpg&name=4096x4096";
      name = "punisherSpawnGhostRiderRedHood.jpg";
      hash = "sha256-OlqScUCRRvhRQsxH0wOA20Z74joafTt//Pw1H0uZ1n4=";
    }
    |> crop16x9South;
}
