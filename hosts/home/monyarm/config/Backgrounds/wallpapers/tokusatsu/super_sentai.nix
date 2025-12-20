{ fetchPixiv, ... }:
{
  garyudo = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2025/07/26/13/49/44/133129230_p0.jpg";
    sha256 = "sha256-D9j4EzR+Xyqh9/AxQ8DEjglo1FAHL3wslgeGeyhIKTQ=";
  };

  gozyuUnicorn = fetchPixiv {
    url = "https://i.pximg.net/img-original/img/2025/03/16/12/43/36/128269525_p1.jpg";
    sha256 = "sha256-NSGZHbNOziO57KrxpecS80KHWH4f3/uKB9utESLh1us=";
  };
}
