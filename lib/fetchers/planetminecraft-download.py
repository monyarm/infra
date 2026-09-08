"""
PlanetMinecraft download script — run as POST_BYPASS_SCRIPT inside
cloudflare-bypass.py.

Targets PlanetMinecraft's static asset CDN directly (e.g.
https://static.planetminecraft.com/files/resource_media/skin/<slug>-planetminecraft-com-<id>.png
for skins, or a project's own resource_media download path for mods/
resource packs), not a project page's own "download" button -- that
endpoint sits behind an ad-monetized interstitial flow that intermittently
serves the page's own HTML again instead of the file (observed directly,
not assumed, for a skin page), even with a real click and a real
referrer. The static CDN URL is stable and Cloudflare-walled the same way
the main site is (confirmed: same `cf-mitigated: challenge` response to a
plain curl), but once the challenge is cleared it serves the actual file
deterministically -- no interstitial, no ads.

cloudflare-bypass.py's own initial navigation already cleared the
challenge for this exact URL (TARGET_URL == the asset URL, set by the
caller); this script just re-requests it via a real page navigation to
capture the raw bytes (an APIRequestContext-level GET was tried first and
got a 403 even reusing the same context's cookies -- it doesn't carry
whatever fingerprint let the actual browser navigation through).

For image responses specifically (skins): the CDN serves WebP instead of
PNG when Chromium's default Accept header allows it (confirmed: content-
type image/webp, real 64x64-with-alpha skin content, not a placeholder)
-- converted to PNG since Minecraft skins must be PNG, and stripped of
metadata since response bytes aren't stable across requests (confirmed:
same skin, differing bytes each fetch). Non-image responses (mods,
resource packs -- zips) are saved as-is; their byte-stability across
requests hasn't been checked, only skins' has.

page/OUT are available from the exec() scope of cloudflare-bypass.py.
"""
# ruff: noqa: F821 - page comes from the enclosing exec() scope

import os
import subprocess
import sys

OUT = os.environ["OUT_PATH"]
TARGET_URL = os.environ["TARGET_URL"]

response = page.goto(TARGET_URL, timeout=30000)
body = response.body()
content_type = response.headers.get("content-type", "")
print(
    f"[*] planetminecraft-download: status={response.status}, "
    f"content-type={content_type!r}, size={len(body)}",
    file=sys.stderr,
)
if response.status != 200:
    sys.exit(f"planetminecraft-download: bad response ({response.status})")

out_path = os.path.join(OUT, "downloaded")

if content_type.startswith("image/"):
    raw_path = os.path.join(OUT, "raw")
    with open(raw_path, "wb") as f:
        f.write(body)
    # -strip: response bytes aren't stable across requests (varying
    # metadata) -- normalize so the FOD hash is deterministic. png: prefix
    # on both ends since the input has no file extension for ImageMagick
    # to sniff, and the CDN may have served WebP instead of PNG regardless
    # of the source URL's own extension.
    subprocess.run(
        [
            os.environ["CONVERT_BIN"],
            f"{content_type.split('/')[1]}:{raw_path}",
            "-strip",
            f"png:{out_path}",
        ],
        check=True,
    )
else:
    with open(out_path, "wb") as f:
        f.write(body)

print(f"[*] planetminecraft-download: saved to {out_path}", file=sys.stderr)
