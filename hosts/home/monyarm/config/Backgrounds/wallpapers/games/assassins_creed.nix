{
  pkgs,
  image,
  ...
}:
with image;
{
  ezio = pkgs.fetchurl {
    url = "https://i0.hdslb.com/bfs/new_dyn/27ff8e4ee1fe0eed605fdbdfb71682451197454103.jpg";
    hash = "sha256-7CuAtQcS5uaGERbp3sF4T2xYGPsXIJ3Y20gDQCDV/jE=";
  };

  kassandra = pkgs.fetchurl {
    url = "https://i0.hdslb.com/bfs/new_dyn/680b4de0c80e35f8d63ef4f19fbfdb031197454103.jpg";
    hash = "sha256-CGsCDo+LENWbLtKVjgCTqbJUzL2FIOkymCbHmJgUC20=";
  };

  acCollage =
    pkgs.fetchurl {
      url = "https://gamecms-res.sl916.com/official_website_resource/50001/4/PICTURE/20250902/657%202436%C3%971125_fd9454a376e242a18d25c026dc24fa22.jpg";
      hash = "sha256-xV7WrEX/JUNft3/3qFVp5SRfsGLVw5nbUtegSrn/QyM=";
      name = "ac-collage.jpg";
    }
    |> crop16x9South;
}
