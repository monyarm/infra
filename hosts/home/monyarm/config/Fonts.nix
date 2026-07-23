{
  pkgs,
  lib,
  sources,
  fetchGitTree,
  getFile,
  fetchDafont,
  ...
}:

let
  mkFont' =
    fontFolder: src:
    let
      filename = builtins.baseNameOf (lib.getName src);
    in
    pkgs.stdenv.mkDerivation {
      name = "${filename}-font";
      inherit src;
      dontUnpack = true;
      installPhase = ''
        mkdir -p $out/share/fonts/${fontFolder}
        find "$src" -type f \( -iname "*.ttf" -o -iname "*.otf" \) -exec cp {} $out/share/fonts/${fontFolder}/ \;
        chmod -R 644 $out/share/fonts/${fontFolder}/*
      '';
    };
  mkTrueType' = mkFont' "truetype";

  mkMseFontPack =
    name: repo:
    pkgs.stdenv.mkDerivation {
      inherit name;
      src = fetchGitTree sources.fonts.mse."${repo}";
      installPhase = ''
        runHook preInstall
        mkdir -p $out/share/fonts
        cp -r "$src/"*" - Fonts" $out/share/fonts/
        find $out -type f -exec chmod 644 {} \;
        runHook postInstall
      '';
    };

  mse-fonts-magic = mkMseFontPack "mse-fonts-magic" "magic";

  mse-fonts-other = mkMseFontPack "mse-fonts-other" "other";

  keyrune-font = mkTrueType' (fetchGitTree sources.fonts.keyrune |> getFile "fonts/keyrune.ttf");

  mana-font = mkTrueType' (fetchGitTree sources.fonts.mana |> getFile "fonts/mana.ttf");

  dafont-pack = pkgs.stdenv.mkDerivation {
    name = "dafont-pack";
    srcs = lib.mapAttrsToList fetchDafont {
      daedra = "10jnfz5kzw4sv9abp1xkj5cpb4l8df5wsl87wmbhqcg0d33fcpp2";
      overseer = "1yhldrqi4ahp97gd5504rkhc6520cqn8r18g4j392w4mdnvs5xv3";
      equestria = "0ijx1vq2jvf4l09xgdsqixsrm74djl9lbbvdnds4wnx0j4rrngqn";
      dovahkiin = "19dnnmdy0zq6njrswi9z4608sbc26w313py1qlz54ipsph6n035z";
      indiana = "0ns5jdh6bqfvd2clj7ivdhl9n5427mkdplq0cm3s5rz51cybn2b4";
      turtles = "1fa2czbvmakd0891ycs91c47fhikbk4mp76gajm847gx2bpprcl7";
      dpoly = "1ja3ixx4vdapzslic4jpvpndxa4i82ks58271kwyi8z5jhrfkca2";
      transdings = "01l8s3w5v9x3fxpdk5ghd90af51vcng1lsjacas0g9l5m6ff84f4";
      neverwinter = "0nl8v9fppx4bq3jv3vnv9raaa7whksx0w1v22b9bjlqdkvj8kzpg";
      steampips = "1jd5p99na7i5h2536mj3ffjzcd9x3ph9yzps5vzqjys8cwwrgrvh";
      medabots = "12v0477vgq3xizhmzsw2chwg907an0gkdc6vgfbkjpv7xb2iv169";
      trekarrowheads = "0mzwx890si6qrqf5w5f95bwsa4p930622vqsxmm684zvbg25i4kl";
      trek_arrowcaps = "1wy6jayjc5df8qxn3wxfrcgb9pw8iblvjfdi2i0320d8mkfa3cqz";
    };
    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/share/fonts/opentype
      for src_dir in $srcs; do
        find "$src_dir" -iname "*.otf" -exec cp -t $out/share/fonts/opentype/ {} +
      done
      find $out -type f -exec chmod 644 {} +
    '';
  };

in
{
  home.packages = with pkgs; [
    mse-fonts-magic
    mse-fonts-other
    keyrune-font
    mana-font
    dafont-pack
  ];

  fonts.fontconfig.enable = true;
}
