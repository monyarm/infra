{ pkgs, fetchSteamCards, ... }:

let
  fetchSonic =
    id: hash:
    pkgs.fetchurl {
      url = "https://sonic.sega.jp/sonic.sega.jp/SonicChannel/upload_images/wallpaper_${id}_pc.png";
      inherit hash;
    };
in
{
  amy = fetchSonic "245_amy_20" "sha256-e9ivgogZArJT579XO4if+ggEzhGdTPxLr78/3wFXP6I=";
  sonic = fetchSonic "247_sonic_27" "sha256-JRTARJPDoQsIDGhYslIBhnqKwUpza1mWtyETepScaXQ=";
  metal = fetchSonic "253_metal_08" "sha256-GqTc4d7uou5r9oPZBpQMSrr896Y8L9OFmMxHRDSFK2M=";
  blaze = fetchSonic "252_blaze_17" "sha256-qinYyTH9NgVhKO+lFOJ/I7x2NmbBy195xwPtAHVt5sk=";
  cream = fetchSonic "250_cream_16" "sha256-nzgBE2Vy+Tw68toNgdj+itM+vO16kuU08rbHGjczCYQ=";
  shadow = fetchSonic "251_shadow_20" "sha256-B3VmBDPMhL/WptiCzwA/pEQorkUnje8sK2kbd2dNIf0=";
  jet = fetchSonic "249_jet_05" "sha256-C2oY6CExj7/8MUmBNBy+IWGN8XK0niSqiAwn+Jpp2wk=";
  rouge = fetchSonic "248_rouge_19" "sha256-MmH+kV9pz14kbdzEyD9IigZJdS1osGiXzJW+2mgw/GM=";
  vector = fetchSonic "246_vector_07" "sha256-RmzkO1U+2r24YwyBI68622QAKaHJj52IlRbgVIM6UpY=";
  silver = fetchSonic "244_silver_19" "sha256-mPgzHtzJd9iP3HqEiFvqC9LotE+EhGYLSy2eIdIXo5o=";
  knuckles = fetchSonic "243_knuckles_19" "sha256-Yt1q9ynzmlGI21/Suhl4Ik4iXbvPlwb+YjdluIyt898=";
  tails = fetchSonic "242_tails_18" "sha256-cQhgJEjuyeK29jKDIi8bdS6Vw52RiyEna0GyLWf/qHw=";

  sonicMania = fetchSteamCards {
    appId = 584400;
    hash = "sha256-By5YQAI8jD2P6Zz8VuLU8LHI9rHHybEFRkWCEpFb9g8=";
  };
}
