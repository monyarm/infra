{
  pkgs,
  image,
  fetchChaosium,
  ...
}:
with image;
let
  fetchCallOfCthulhu = attrs: fetchChaosium (attrs // { game = "Call of Cthulhu"; });
in
{
  library = pkgs.fetchurl {
    url = "https://cdn10.bigcommerce.com/s-9zhx02uo/product_images/uploaded_images/chaosium-background-the-library.png";
    sha256 = "sha256-MaAFpaY9/nT89MLU68a/tpnGyH/d7g6FMgc70H1Wn+U=";
  };
  cthulhu = fetchCallOfCthulhu {
    name = "Cthulhu";
    sha256 = "sha256-xBVEWvpAiqFIkCcXIQD3eoiAfBckaEFcBkdzXaGk3tY=";
  };
  investigation = fetchCallOfCthulhu {
    name = "Investigation";
    sha256 = "sha256-ssNQRyVcmaOpVfywQqNEjDkrs3U9WqTgidftEFiubec=";
  };
  cultists = fetchCallOfCthulhu {
    name = "Cultists";
    sha256 = "sha256-tvGEXgyWmz69hA7WjvoGovreIca8yP6D09Q1rjpJf8w=";
  };
  idol = fetchCallOfCthulhu {
    name = "Idol";
    sha256 = "sha256-QN1np+kAbCUCj6Yz4PfREZVf2ROHKmMvC5l5IlgMusc=";
  };
}
