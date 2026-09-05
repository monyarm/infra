{
  config,
  lib,
  pkgs,
  getFile,
  fetchItch,
  mkDoom,
  findWad,
  sources,
  ...
}:
lib.mkIf config.games.doom.enable {
  games.doom.wads = {
    simonsdestiny = fetchItch sources.wad.simonsdestiny |> getFile "Castlevania.ipk3";
    goldenSoulsRemastered =
      fetchItch sources.wad.goldensouls |> getFile (findWad sources.wad.goldensouls.files);
    goldenSouls2 =
      fetchItch sources.wad.goldensouls2 |> getFile (findWad sources.wad.goldensouls2.files);
    goldenSouls3 =
      fetchItch sources.wad.goldensouls3 |> getFile (findWad sources.wad.goldensouls3.files);
    gzpt = fetchItch sources.wad.gzpt |> getFile "GZPT.ipk3";
  };

  programs.steam.games = with config.games.doom.wads; {
    simonsdestiny = mkDoom {
      name = "Castlevania: Simon's Destiny";
      iwad = simonsdestiny;
      images = {
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/eff9f344fdd9b97ea827134223f62586.png";
          sha256 = "sha256-QytcEh3GtiFKTihuLdrVboPY0m4pe5qLEBOL2Yjy3rM=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/5f285e4cb6488dcd667af6ec31642298.png";
          sha256 = "sha256-ks/wDAqckajW5sOeWSKUETFPFZI0ZoFxyG5X2986Lh4=";
        };
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/35716b82c3e8cb70a2c72c39316c1c05.png";
          sha256 = "sha256-FxhPuyaZzJ8tMvNT7GP3lKZmR4UnuqrmTQh6hEZImGQ=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/294e09f267683c7ddc6cc5134a7e68a8.png";
          sha256 = "sha256-LU5KuUQs6SeZQCL68Wce0qRBTJFvc7U4usEGLzu034M=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/23e7e36c046bf068233ef55ba793c073.png";
          sha256 = "sha256-4EhyCxXbBGXAhd58xqf75NEUzHfCoNFlOf8Xd5JoNME=";
        };
      };
    };
    GoldenSoulsRemastered = mkDoom {
      name = "Doom: The Golden Souls Remastered";
      iwad = doom2;
      wad = [ goldenSoulsRemastered ];
      images = {
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/b1c8157c40c810f3578df8cfb5e6c12f.jpg";
          sha256 = "sha256-KTbqJpDk0WLhn2MF2Aniyh2wq0MZTpeZXnrHLyhTJG4=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/1f3f06e84308d0358db062ec5df47998.png";
          sha256 = "sha256-fpoCSuISxx804xAV8BPvzOGFyLZUnRs6ZyauLkT0OcU=";
        };
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/1af4e757d34a34d89c040d16ec352003.png";
          sha256 = "sha256-c48ciYlL8N7NQ1/rU8NaXAcOssrPuI7+DTiKrlTezco=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/71d779e5d91a630bc0f3cfc3a6db1d93.png";
          sha256 = "sha256-12oD+lh/XSNrFa1HOYak0YFF0ICy4f5t9tObMmB+sPw=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/52edd78109c3c3adbf09443b9d5706f3.jpg";
          sha256 = "sha256-bnQzDyI4tu8PzFAtJ2qTQdbUXm00OnXzmFDnVOoqcBg=";
        };
      };
    };
    GoldenSouls2 = mkDoom {
      name = "Doom: The Golden Souls 2";
      iwad = doom2;
      wad = [ goldenSouls2 ];
      images = {
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/d6f967859a2ec3f9a1af25bcec6c2816.png";
          sha256 = "sha256-GxIqdVw4f1/6bp/4vN9MBEyTKP7s77NgXv8jBnAeYlY=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/3da03729f7154067a7be4bf1258a46a7.png";
          sha256 = "sha256-z6wh4VErvtJ8b01F8wVotOHvJ595tqZBNDQTQ/CRWIc=";
        };
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/c0c6d46d266870e0f78a58bf141c07b7.png";
          sha256 = "sha256-uv8brAa4ste+IJsvf3REdfLeokrs0d4ru9iJv49havs=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/175dd9e58031eaf4013b7c335272d7fe.png";
          sha256 = "sha256-88FjlM0bv8pLYZW0tDJC5EAfNdWQoiOARW5pK9oqXxY=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/78e50bc56c27e79c239dac9962a476f7.png";
          sha256 = "sha256-RuwdMPQ6UREz5GJ8JOvWd+mstHhMsPgz/KsPdL8LTKg=";
        };
      };
    };
    GoldenSouls3 = mkDoom {
      name = "Doom: The Golden Souls 3";
      iwad = doom2;
      wad = [ goldenSouls3 ];
      images = {
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/1558de88b4db98bdd26aa51d564fcba6.jpg";
          sha256 = "sha256-j1o//OypZFuot+Mc3cN4AojPDqomPL2bzRcYsVc+40s=";
        };
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/a20584261802c959dca8dacc298dba30.png";
          sha256 = "sha256-799dPfxOyN1t+9+shiRKGXOvB01R7uSSE2bJYbkldyM=";
        };
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/93d7899e2e4a39939729da1f02052c89.png";
          sha256 = "sha256-EtejpaWgCx8VG27ifFFr7iRVlCaAZ4f+pVzZn9hIT54=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/abc5f0fb231a8087dd8109ccf44bde19.png";
          sha256 = "sha256-mDDPGTadzjq4PLbK7Qqq3V3KZfUHe1N5VgC1HLYXcag=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/3004e3173fd000f60cd86b31e64ec50b.png";
          sha256 = "sha256-QBFb0yYHf06RvRqDMiWf94pukTAqzFovnr+JX69Cad0=";
        };
      };
    };
    GzPt = mkDoom {
      name = "GZ PT";
      iwad = gzpt;
      images = {
        hero = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/hero/434042e8eccf1ad223dd1007c60afcc7.png";
          sha256 = "sha256-vvWnBNDJwlDQY9ynd7V8efPyXBP0Xjm/laY7/4D1mGc=";
        };
        icon = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/icon/ca28b788d0380a48bfe8d58a1cda03b3.png";
          sha256 = "sha256-9x7yp44rU4YBiPk2eHBk0mlxgubrxnLdMyDzMD3xp2A=";
        };
        grid = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/0acae5952c4b845b73a0b320462ae24b.png";
          sha256 = "sha256-NeBucO9r6XN/N1ljKdvdxNIpD6WweCUHLmDprb9VYPc=";
        };
        wide = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/grid/2964fb543d5d5eb44c062fd73cbe20bf.png";
          sha256 = "sha256-GwUPI+CMZKm8oPwyWxkMQGNPiTCvslT394NJZrP9iV4=";
        };
        logo = pkgs.fetchurl {
          url = "https://cdn2.steamgriddb.com/logo/7768300a518fbd5066d77cfefcbad813.png";
          sha256 = "sha256-B/YDd+PLoawSQBdXqirc3SxISz+tyGSdQzxck9Lehz4=";
        };
      };
    };
  };
}
