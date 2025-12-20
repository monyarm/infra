{ lib, ... }:
let
  mkExtension = id: install_url: {
    "${id}" = {
      installation_mode = "force_installed";
      inherit install_url;
    };
  };

  localExtension = id: extension: mkExtension id "file://${./extensions + "/${extension}.xpi"}";
  mozillaExtension =
    slug: id: mkExtension id "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
  mozillaExtension' = id: mozillaExtension id id;
  mozillaExtensions' = ids: lib.mkMerge (map mozillaExtension' ids);
  otherWebsiteExtension = mkExtension;

  githubExtension =
    id:
    {
      owner,
      repo,
      filename ? "${repo}.xpi",
    }:
    mkExtension id "https://github.com/${owner}/${repo}/releases/latest/download/${filename}";
in
{
  programs.firefox.policies = {
    DisableTelemetry = true;
    EnableTrackingProtection = {
      Value = true;
      Locked = true;
      Cryptomining = true;
      Fingerprinting = true;
    };
    DisablePocket = true;
    SyncServiceURL = "https://sync.services.mozilla.com/";
    DisableFirefoxAccounts = false;
    DisableAccounts = false;
    DisableFirefoxScreenshots = true;
    DisableAppUpdate = true;
    OverrideFirstRunPage = "";
    OverridePostUpdatePage = "";
    DontCheckDefaultBrowser = true;
    ExtensionSettings = lib.mkMerge [
      {
        "*" = {
          installation_mode = "allowed";
          allowed_types = [
            "theme"
            "dictionary"
            "locale"
          ];
        };
      }
      (mozillaExtensions' [
        # keep-sorted start
        "@buyee-cart-extension"
        "@contain-facebook"
        "@m3u8link"
        "@react-devtools"
        "BrickLinkUnifiedUI@FillerBrick"
        "CookieClickerModManager@dashnet.org"
        "Tab-Session-Manager@sienori"
        "TitleCase@htdsoftware.com"
        "autocardanywhere-amo@autocardanywhere.com"
        "dont-track-me-google@robwu.nl"
        "enhanced-cardmarket@mave.me"
        "firefox-addon@pronoundb.org"
        "firefox-extension@steamdb.info"
        "shinigamieyes@shinigamieyes"
        "sky-follower-bridge@ryo.kawamata"
        "snaplinks@snaplinks.mozdev.org"
        "sponsorBlocker@ajay.app"
        "uBlock0@raymondhill.net"
        "userchrome-toggle@joolee.nl"
        # keep-sorted end
      ])
      # keep-sorted start
      (mozillaExtension "augmented-steam" "{1be309c5-3e4f-4b99-927d-bb500eb4fa88}")
      (mozillaExtension "blocktube" "{58204f8b-01c2-4bbc-98f8-9a90458fd9ef}")
      (mozillaExtension "brickcoin" "{0aac56f5-736c-4347-8dc5-72f5887d8f83}")
      (mozillaExtension "brickhunter" "{9f0aa561-40f6-4bf1-bbb3-73e8125430bf}")
      (mozillaExtension "copy-selected-links" "jid1-vs5odTmtIydjMg@jetpack")
      (mozillaExtension "copywebtables" "{292b92dc-b295-45e6-add6-a5ce6911a544}")
      (mozillaExtension "deviantart-filter" "{a2ce7c11-e47d-42cf-b6db-ede36265cf6c}")
      (mozillaExtension "discogs-enhancer" "{190dbc44-5dee-4ad4-86e9-a38d7a2d1c61}")
      (mozillaExtension "download-with-jdownloader" "{03e07985-30b0-4ae0-8b3e-0c7519b9bdf6}")
      (mozillaExtension "flag-cookies" "{d8d0bc2b-45c2-404d-bb00-ce54305fc39c}")
      (mozillaExtension "grammarly-1" "87677a2c52b84ad3a151a4a72f5bd3c4@jetpack")
      (mozillaExtension "indie-wiki-buddy" "{cb31ec5d-c49a-4e5a-b240-16c767444f62}")
      (mozillaExtension "load-reddit-images-directly" "{4c421bb7-c1de-4dc6-80c7-ce8625e34d24}")
      (mozillaExtension "localdn-fork-of-decentraleyes" "{b86e4813-687a-43e6-ab65-0bde4ab75758}")
      (mozillaExtension "reddit-enhancement-suite" "jid1-xUfzOsOFlzSOXg@jetpack")
      (mozillaExtension "return-youtube-dislike" "{762f9885-5a13-4abd-9c77-433dcd38b8fd}")
      (mozillaExtension "ruffle_rs" "{b5501fd1-7084-45c5-9aa6-567c2fcf5dc6}")
      (mozillaExtension "search_by_image" "{2e5ff8c8-32fe-46d0-9fc8-6b8986621f3c}")
      (mozillaExtension "steam-bulk-sell" "{c7e15941-6082-499c-a52c-94015f7eb5d1}")
      (mozillaExtension "styl-us" "{7a7a4a92-a2a0-41d1-9fd7-1e92480d612d}")
      (mozillaExtension "user-agent-string-switcher" "{a6c4a591-f1b2-4f03-b3ff-767e5bedf4e7}")
      (mozillaExtension "violentmonkey" "{aecec67f-0d10-4fa7-b7c7-609a2db280cf}")
      (mozillaExtension "vue-js-devtools" "{5caff8cc-3d2e-4110-a88a-003cc85b3858}")
      (mozillaExtension "web-scrobbler" "{799c0914-748b-41df-a25c-22d008f9e83f}")
      # keep-sorted end
      # keep-sorted start
      (otherWebsiteExtension "jid1-OY8Xu5BsKZQa6A@jetpack" "https://extensions.jdownloader.org/firefox.xpi")
      (otherWebsiteExtension "magnolia@12.34" "https://gitflic.ru/project/magnolia1234/bpc_uploads/blob/raw?file=bypass_paywalls_clean-latest.xpi")
      # keep-sorted end
      # keep-sorted start
      (localExtension "jid1-tHrhDJXsKvsiCw@jetpack" "bpm")
      # keep-sorted end
      (githubExtension "exhentaipassport@harytfw" {
        owner = "harytfw";
        repo = "Exhentai-passport-for-firefox-webextension";
        filename = "exhentai_passport-0.0.9.xpi";
      })
      (githubExtension "fx_cast@matt.tf" {
        owner = "hensm";
        repo = "fx_cast";
        filename = "fx_cast-0.3.1.xpi";
      })
    ];

  };
}
