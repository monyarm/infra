{
  pkgs,
  lib,
  fetchToolOutput,
  extractArchiveSnippet,
  ...
}:
let
  cloudflareBypassScript = ./cloudflare-bypass.py;
in
rec {
  fetchThroughCloudflare =
    {
      name,
      hash ? null,
      sha256 ? null,
      outputHashMode ? "flat",
      extract ? false,
      archiveContent ? null,
      extraAttrs ? { },
      # Simple case: just load URL, pass turnstile, click selector
      url ? null,
      clickSelector ? null,
      # Advanced case: custom resolve script
      resolve ? null,
      ...
    }:
    let
      outputHash = if hash != null then hash else sha256;
      effectiveHashMode = if extract then "recursive" else outputHashMode;
      _resolve =
        if resolve != null then
          resolve
        else if url != null && clickSelector != null then
          ''
            export TARGET_URL="${url}"
            export OUT_PATH="$TMPDIR"
            export CLICK_SELECTOR="${clickSelector}"
            python3 ${cloudflareBypassScript}
            DOWNLOADED_FILE="$TMPDIR/downloaded"
          ''
        else
          throw "fetchThroughCloudflare: must provide either 'resolve' or both 'url' and 'clickSelector'";
    in
    fetchToolOutput {
      inherit name;
      inherit outputHash;
      outputHashMode = effectiveHashMode;
      nativeBuildInputs = [
        pkgs.xvfb
        pkgs.python3
        pkgs.python3Packages.playwright
        pkgs.playwright-driver.browsers
        pkgs.curl
        pkgs.coreutils
      ];
      extraAttrs =
        extraAttrs
        // lib.optionalAttrs (archiveContent != null) {
          passthru.archiveContent = archiveContent;
        };
      script = ''
        set -e

        cleanup() {
          kill $CHROMIUM_PID 2>/dev/null || true
          kill $XVFB_PID 2>/dev/null || true
        }
        trap cleanup EXIT

        DISPLAY_NUM=42
        Xvfb :$DISPLAY_NUM -screen 0 1920x1080x24 -ac -nolisten tcp &
        XVFB_PID=$!
        sleep 2

        if ! kill -0 $XVFB_PID 2>/dev/null; then
          echo "Error: Xvfb failed to start" >&2
          exit 1
        fi

        export DISPLAY=:''${DISPLAY_NUM}
        export HOME=$TMPDIR
        export PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers}
        export DEBUG="pw:browser"

        ${_resolve}

        if [ -z "''${DOWNLOADED_FILE:-}" ]; then
          echo "Error: resolve did not set DOWNLOADED_FILE" >&2
          exit 1
        fi

        ${
          if extract then
            ''
              mkdir -p "$out"
              ${extractArchiveSnippet {
                file = "$DOWNLOADED_FILE";
                outDir = "$out";
              }}
            ''
          else if effectiveHashMode == "recursive" then
            ''
              mkdir -p "$out"
              cp "$DOWNLOADED_FILE" "$out/"
            ''
          else
            ''
              cp "$DOWNLOADED_FILE" "$out"
            ''
        }
      '';
    };

  fetchPlanetMinecraft =
    {
      # Direct static-CDN asset URL, e.g.
      # https://static.planetminecraft.com/files/resource_media/skin/<slug>-planetminecraft-com-<id>.png
      # -- NOT the skin page URL. The page's own "download" button sits
      # behind an ad-monetized interstitial that intermittently serves the
      # page's own HTML again instead of the file (confirmed directly,
      # even with a real click and referrer); the static CDN URL is
      # Cloudflare-walled the same way but, once cleared, deterministic.
      url,
      name ? "planetminecraft-skin",
      ...
    }@args:
    let
      planetMinecraftScript = ./planetminecraft-download.py;
    in
    fetchThroughCloudflare (
      args
      // {
        inherit name;
        resolve = ''
          export TARGET_URL="${url}"
          export OUT_PATH="$TMPDIR"
          export CONVERT_BIN="${pkgs.imagemagick}/bin/convert"
          export POST_BYPASS_SCRIPT="${planetMinecraftScript}"
          python3 ${cloudflareBypassScript}
          DOWNLOADED_FILE="$TMPDIR/downloaded"
        '';
      }
    );

  fetchRomhacking =
    {
      url,
      name ? "romhacking-patch",
      ...
    }@args:
    let
      romhackingScript = ./romhacking-download.py;
    in
    fetchThroughCloudflare (
      args
      // {
        inherit name;
        resolve = ''
          export TARGET_URL="${url}"
          export OUT_PATH="$TMPDIR"
          export POST_BYPASS_SCRIPT="${romhackingScript}"
          python3 ${cloudflareBypassScript}
          DOWNLOADED_FILE="$TMPDIR/downloaded"
        '';
      }
    );
}
