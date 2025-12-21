{
  pkgs,
  lib,
  fetchSteamCards,
  ...
}:
let
  halfLifeBaseUrl = "https://cdn.fastly.steamstatic.com/half-life.com/images";

  fetchHalfLifeWallpaper =
    subPath: prefix: digit: sha256:
    pkgs.fetchurl {
      url = "${halfLifeBaseUrl}/${subPath}/${prefix}wallpaper${digit}_16x9.jpg";
      inherit sha256;
    };

  fetchAll =
    prefix: fetcher: hashes:
    lib.listToAttrs (
      map (i: {
        name = "${prefix}wallpaper${lib.fixedWidthString 2 "0" (toString i)}";
        value = fetcher (lib.fixedWidthString 2 "0" (toString i)) (builtins.elemAt hashes (i - 1));
      }) (lib.range 1 (builtins.length hashes))
    );

  fetchHL2 = fetchHalfLifeWallpaper "halflife220" "hl2";
  fetchHL = fetchHalfLifeWallpaper "halflife25" "HL";

  fetchAllHL2 = fetchAll "hl2" fetchHL2;
  fetchAllHL = fetchAll "HL" fetchHL;
in
(fetchAllHL2 [
  "1z39ahg3j08rvj05pvqq9ahc6h6s232prmbkjxwgqzzcjmc8f4wq"
  "0x7w22gn7xpiclpq9h9lmyi26lkb1sbn7iax5nxzyr24qpksnk6v"
  "1darg8r1pyi69p5kl3yljlaxwwnly3y1qid29y2smcq5gwsmr9ln"
  "0qpr678ls4yqfgnkcl5bbjfp0l2gp83h7hkszkjk46afahkqsc20"
  "0y1kvv90iricvq4j4ff673nq88b7n5qd286pz3nbilynwzzpgzjr"
  "0ji7za4jpl6sj3lilq90mjqjwzqrl69697q5xj6imykm5s5jnk3j"
  "1z5k06lnsdi2kv2i1m2xac1xyrd7a1lmhy7z5k1iggk6bhrd3dvf"
  "1nkx3xd1hv5477mccpyxwl6nymm3zk9426mpy8afs93x2iyslrbx"
  "12hhij6a5i0v716prihmypg2aqx7qj5smszszfjqjdrcgz9b812z"
  "055zwi9kf0g7cxvvbcxbh1fqfhwqikg2x15pb2xqf68wd68nj6cg"
  "1xx0d0k4h1pbxkcgl5ldh7hgmwkf6q96k69qrdc8axr8imk3glz9"
])
// (fetchAllHL [
  "0n3achkbc5i0m0nj3yxcymk4qv1gfnq9ys56mn37cqhr24x6jp2m"
  "0zs6kpvcynxmv1x7msapcnfcpdx70v0xjp0lsb3bzb2l050zn2dm"
  "0lqplqwxg7nb072c58g4i2yh6mh7nl43hhci4rkwzq98xs28mqvk"
  "0ajvr1bcz9609yvhdxjzz60p9k385m4kyxcv5m3mjfp0yhqcidk5"
  "1imqpmzcwr1pkjqvmnvbvw7ghs7yxlwdymi0lq1h8lsrsl8k22vr"
])
// {
  portal2 = fetchSteamCards {
    appId = 620;
    cardNames = [
      "destruction"
      "finale"
      "glados"
      "intro"
      "theLab"
      "mannequin"
    ];
    hash = "sha256-c9Rtd86DdhwHUu2dBCeVG5hqFzvCx91LpplAymxvOxE=";
  };
}
