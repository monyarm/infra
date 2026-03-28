{
  pkgs,
  image,
  ...
}:
with image;
{
  aos01 = pkgs.fetchurl {
    url = "https://assets.warhammer-community.com/runbgvi6w4ow2v8m-1729174148.jpg";
    hash = "sha256-+cv523EufyPTeR5MjCsTUH1HaeECPFZmH58lmFB6fng=";
  };
  aos02 = pkgs.fetchurl {
    url = "https://assets.warhammer-community.com/qiule4n4fopn9ujg-1729174153.jpg";
    hash = "sha256-4M5/Qa72JaobSO3g2S4tbe6cMcmyUqaXWbbS3gViufQ=";
  };
  aos03 = pkgs.fetchurl {
    url = "https://assets.warhammer-community.com/e9s9wuh4frizk8l3-1729174164.jpg";
    hash = "sha256-VPSlezZwfjqtm9lUKJPGF2KcmrCbShS1An9t/zlOaZY=";
  };
}
