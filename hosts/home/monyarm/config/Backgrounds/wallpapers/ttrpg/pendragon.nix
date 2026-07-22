{
  image,
  fetchChaosium,
  ...
}:
with image;
let
  fetchPendragon = attrs: fetchChaosium (attrs // { game = "Pendragon"; });
in
{
  visitor = fetchPendragon {
    name = "Visitor";
    sha256 = "sha256-vfT6IEumGw6trS89jxMCZ8g/0koRpLRp7zQstQ1lNPo=";
  };
  captiveKnights = fetchPendragon {
    name = "Captive Knights";
    sha256 = "sha256-iYXasIfiQ8r6IeGI+ziZYsRZQoOZDmTxOQH+3ySuJ3k=";
  };
  chase = fetchPendragon {
    name = "Chase";
    sha256 = "sha256-88MwyZmLHZ5nU0jprT3zHHOPJrjbrnd3283Ips8Ne08=";
  };
  isleOfAvalon = fetchPendragon {
    name = "Isle of Avalon";
    sha256 = "sha256-i0ERwoYBRyagpvTSL6FHO4cNeniMWwNsBZzs1yW0EYQ=";
  };
}
