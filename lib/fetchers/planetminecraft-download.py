"""
PlanetMinecraft download script — run as POST_BYPASS_SCRIPT inside
cloudflare-bypass.py.

PlanetMinecraft's skin pages show a Google "Funding Choices" consent
dialog (`.fc-consent-root`) that intercepts pointer events and blocks any
click on the real page underneath it until dismissed. The real download
link (confirmed against a live page's DOM, since the site is
Cloudflare-walled even for automated HTML fetches) is
`a.skin-pair-download`, `target="_blank"`, whose destination just serves
the raw PNG bytes.

Two dead ends before this approach, both real findings worth keeping:
  - Clicking the link and waiting for Playwright's "download" event never
    fires -- the response has no Content-Disposition: attachment, so the
    browser just renders it inline instead of downloading it.
  - `page.request.get(url)` (Playwright's APIRequestContext) gets a 403
    even reusing the same context's cookies -- it doesn't go through the
    actual browser engine, so it doesn't carry whatever fingerprint let
    the real navigation past Cloudflare's challenge in the first place.

What works: open a genuinely new page in the SAME browser context (shares
cookies/session with the already-challenge-cleared original page) and
navigate it directly with `goto()`, which returns the main navigation's
Response object -- `.body()` gives the raw bytes regardless of content
type, since Playwright captures it at the network level, not through the
rendered DOM.

page/ctx are available from the exec() scope of cloudflare-bypass.py.
"""
# ruff: noqa: F821 - page/ctx come from the enclosing exec() scope

import os
import sys
import time
from urllib.parse import urljoin

OUT = os.environ["OUT_PATH"]

consent_button = page.query_selector("button.fc-cta-consent")
if consent_button:
    print("[*] planetminecraft-download: dismissing consent dialog", file=sys.stderr)
    consent_button.click()
    time.sleep(1)
else:
    print("[*] planetminecraft-download: no consent dialog found", file=sys.stderr)

download_link = page.query_selector("a.skin-pair-download")
if not download_link:
    print("[!] planetminecraft-download: a.skin-pair-download not found", file=sys.stderr)
    sys.exit(1)

href = download_link.get_attribute("href")
download_url = urljoin(page.url, href)
print(f"[*] planetminecraft-download: navigating to {download_url}", file=sys.stderr)

popup = ctx.new_page()
response = popup.goto(download_url, timeout=30000)
body = response.body()
content_type = response.headers.get("content-type", "")
print(
    f"[*] planetminecraft-download: response status={response.status}, "
    f"content-type={content_type!r}, size={len(body)}",
    file=sys.stderr,
)
if response.status != 200 or len(body) == 0:
    sys.exit(f"planetminecraft-download: bad response ({response.status}, {len(body)} bytes)")
if not content_type.startswith("image/"):
    # Seen in practice: repeated requests to the same download URL in a
    # short window get served an HTML interstitial instead of the file
    # (rate-limiting or a per-navigation challenge, not investigated
    # further) -- fail loudly rather than silently writing HTML as if it
    # were the skin.
    sys.exit(
        f"planetminecraft-download: expected an image response, got content-type "
        f"{content_type!r} (likely rate-limited or challenged again -- wait and retry)"
    )

out_path = os.path.join(OUT, "downloaded")
with open(out_path, "wb") as f:
    f.write(body)
print(f"[*] planetminecraft-download: saved to {out_path} ({len(body)} bytes)", file=sys.stderr)
