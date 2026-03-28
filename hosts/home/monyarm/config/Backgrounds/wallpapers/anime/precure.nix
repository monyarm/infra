{ fetchPixiv, ... }:
{
  smilePrecureBeach = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2012/08/08/14/42/05/29218831_p0.jpg";
    sha256 = "sha256-xuv/MchHedQpV4J5WuM31UFQ/EPclPrpshSBf2e/DrM=";
  };
  lalaCureMilky = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2019/04/01/17/22/00/73992268_p0.jpg";
    sha256 = "sha256-DGdihlXAySKGt/2/tu2bMpgjC16Yz2TNFtbxrpxYznE=";
  };
  cureMoonlight = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2010/09/27/09/08/31/13517034_p0.jpg";
    sha256 = "sha256-4L1aQ9PWf5xNDUGRhlmV94kbHcXvHWlyyaqW2ZdaS6g=";
  };
}
