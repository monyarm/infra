{ fetchSteamStoreAsset, ... }:
{

  spartanAssault01 = fetchSteamStoreAsset {
    appid = 277430;
    assetid = "ss_0b5eda6b3dfdc5cd9d521a235360591870df374a";
    sha256 = "sha256-1mCECOwYD40+iAvzy1s3n0b/C7xkfLiHcfBWBAamrYY=";
  };

  spartanAssault02 = fetchSteamStoreAsset {
    appid = 277430;
    assetid = "ss_683ea0ae83e53d3c882c84e44f6532f52d7997a1";
    sha256 = "sha256-rFGFpMgpWiB/6urTFf9iLM8iOonyaDQncmfVEGJsuuA=";
  };
}
