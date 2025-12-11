{ config, ... }:

{
  sops.templates = {
    "musixmatch_token".content = "musixmatch_token = ${config.sops.placeholder.musixmatch_token}";
  };
  programs.mpv.scriptOpts.lrc = {
    # The token to authenticate with Musixmatch's API.
    # If you get rate limited, you can obtain a new token with
    # curl --location https://apic-desktop.musixmatch.com/ws/1.1/token.get?app_id=web-desktop-app-v1.0
    # musixmatch_token = "musixmatch_token";
    include = config.sops.templates."musixmatch_token".path;

    # Give .ja.lrc extensions to lyrics with Japanese characters. This can be used
    # to give them a bigger font size by checking
    # profile-cond=p['current-tracks/sub/lang']:sub(1, 1) == 'j'
    mark_as_ja = false;

    # Japanese lyrics on Netease often randomly replace kanji with equivalent
    # Chinese characters. If you set this option to the path of the
    # chinese-to-kanji.txt file in this repository, it will be used to fix this
    # (the mappings are self-maintained because the ones I found worked badly).
    chinese_to_kanji_path = "~~/scripts/mpv-lrc/chinese-to-kanji.txt";

    # Remove lines with the names of the artists from NetEase's LRCs.
    strip_artists = false;
  };
}
