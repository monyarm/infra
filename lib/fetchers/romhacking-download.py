"""
Romhacking.net download script — run as POST_BYPASS_SCRIPT inside cloudflare-bypass.py.

Expected env vars:
  OUT_PATH  — directory to write downloaded file to
  HACK_URL  — the romhacking.net hack page URL (to re-read meta tags if needed)

After Cloudflare bypass + download click, reads meta tags, constructs
the download URL, handles Google Drive redirects, and saves the file.

page and browser are available from the exec() scope of cloudflare-bypass.py.
"""

# ruff: noqa: F821 - page/browser come from the enclosing exec() scope, not this module

import os
import sys
import time

OUT = os.environ["OUT_PATH"]

print(f"[*] romhacking-download: page title = {page.title()!r}", file=sys.stderr)
print(f"[*] romhacking-download: page URL = {page.url}", file=sys.stderr)

# Wait for any navigation from the click
time.sleep(3)

# Read meta tags
meta = page.evaluate("""() => ({
    id: document.querySelector('meta[name="id"]')?.content,
    token: document.querySelector('meta[name="token"]')?.content,
})""")
print(
    f"[*] romhacking-download: meta id={meta.get('id')}, token={meta.get('token')}",
    file=sys.stderr,
)

if not meta.get("id") or not meta.get("token"):
    print(
        "[!] romhacking-download: No meta tags found, page may not have loaded properly",
        file=sys.stderr,
    )
    print(f"[!] romhacking-download: page title = {page.title()!r}", file=sys.stderr)
    # Dump page content for debugging
    try:
        html = page.content()
        print(
            f"[!] romhacking-download: page HTML (first 2000 chars) = {html[:2000]}",
            file=sys.stderr,
        )
    except Exception as e:  # noqa: BLE001 - best-effort debug dump before exiting
        print(
            f"[!] romhacking-download: could not dump page content: {e}",
            file=sys.stderr,
        )
    sys.exit(1)

# Construct download URL
hack_path = meta["id"].replace("-", "/", 1)
download_url = f"https://www.romhacking.net/download/{hack_path}/{meta['token']}"
print(f"[*] romhacking-download: constructed URL = {download_url}", file=sys.stderr)

# Download via browser context (has cookies/session from bypass)
resp = page.request.get(download_url, max_redirects=20)
body = resp.body()
print(
    f"[*] romhacking-download: response status={resp.status}, size={len(body)}",
    file=sys.stderr,
)

out_path = os.path.join(OUT, "downloaded")
with open(out_path, "wb") as f:
    f.write(body)
print(
    f"[*] romhacking-download: saved to {out_path} ({len(body)} bytes)", file=sys.stderr
)
