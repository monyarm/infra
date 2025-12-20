{ fetchPixiv, ... }:
{
  giantsOfNightmare = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2010/12/11/19/41/51/15118122_p0.jpg";
    sha256 = "sha256-IulhJ7hfKUg2Z61Bj5Atwt/9rnENV/CvVUs+8Rea3HY=";
  };
  shieldOfHope = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2011/01/22/05/54/35/16084388_p0.jpg";
    sha256 = "sha256-WzosH1ZD0lJmaiw9iKnUnmNUP4uGnYaLy1H0iE8wyNg=";
  };
}
