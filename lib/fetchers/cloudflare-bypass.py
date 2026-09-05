import os
import sys
import time

from playwright.sync_api import sync_playwright

URL = os.environ["TARGET_URL"]
OUT = os.environ["OUT_PATH"]
CLICK_SELECTOR = os.environ.get("CLICK_SELECTOR")
POST_BYPASS_SCRIPT = os.environ.get("POST_BYPASS_SCRIPT")

launch_args = {
    "headless": False,
    "args": [
        "--no-sandbox",
        "--disable-gpu",
        "--disable-dev-shm-usage",
        "--disable-breakpad",
        "--ozone-platform=x11",
        "--disable-blink-features=AutomationControlled",
    ],
    "timeout": 30000,
}

print("[*] Starting Cloudflare bypass", file=sys.stderr)
print(f"[*] URL: {URL}", file=sys.stderr)
print(f"[*] CLICK_SELECTOR: {CLICK_SELECTOR}", file=sys.stderr)
print(f"[*] POST_BYPASS_SCRIPT: {POST_BYPASS_SCRIPT}", file=sys.stderr)

with sync_playwright() as p:
    browser = p.chromium.launch(**launch_args)
    ctx = browser.new_context(
        viewport={"width": 1280, "height": 800}, ignore_https_errors=True
    )
    page = ctx.new_page()

    download_path = [None]

    def on_download(download):
        download_path[0] = download.suggested_filename
        download.save_as(os.path.join(OUT, download_path[0]))
        print(f"[*] Download event: {download_path[0]}", file=sys.stderr)

    page.on("download", on_download)

    print("[*] Navigating to page...", file=sys.stderr)
    try:
        page.goto(URL, wait_until="domcontentloaded", timeout=60000)
    except Exception as e:  # noqa: BLE001 - navigation can fail in many browser-specific ways
        print(f"[!] goto error: {e}", file=sys.stderr)

    bypassed = False
    for i in range(60):
        time.sleep(1)
        try:
            title = page.title()
            print(f"[+] [{i}s] title={title!r}", file=sys.stderr)
        except Exception as e:  # noqa: BLE001 - polling loop, any error means the page/browser went away
            print(f"[!] [{i}s] Browser closed: {e}", file=sys.stderr)
            break

        if "Just a moment" not in title and i > 3:
            print(f"[+] Challenge passed at {i}s", file=sys.stderr)
            bypassed = True

            if CLICK_SELECTOR:
                el = page.query_selector(CLICK_SELECTOR)
                if el:
                    print(f"[+] Clicking {CLICK_SELECTOR}", file=sys.stderr)
                    el.click()
                    time.sleep(3)
                else:
                    print(f"[!] Selector {CLICK_SELECTOR} not found", file=sys.stderr)

            break

        frames = page.frames
        turnstile_frame = next(
            (f for f in frames if "challenges.cloudflare.com" in f.url), None
        )
        if turnstile_frame:
            try:
                body = turnstile_frame.query_selector("body")
                if body:
                    box = body.bounding_box()
                    if box and box["width"] > 0 and box["height"] > 0:
                        print(
                            f"[+] [{i}s] Clicking Turnstile at ({box['x'] + 28}, {box['y'] + box['height'] / 2})",
                            file=sys.stderr,
                        )
                        page.mouse.click(box["x"] + 28, box["y"] + box["height"] / 2)
                        time.sleep(2)
            except Exception as e:  # noqa: BLE001 - Turnstile iframe can vanish mid-click
                print(f"[!] [{i}s] Turnstile click failed: {e}", file=sys.stderr)

    if bypassed and POST_BYPASS_SCRIPT:
        print(
            f"[*] Executing post-bypass script: {POST_BYPASS_SCRIPT}", file=sys.stderr
        )
        with open(POST_BYPASS_SCRIPT) as f:
            exec(f.read())  # noqa: S102 - POST_BYPASS_SCRIPT is a trusted, repo-local script

    page.close()
    browser.close()
    print("[*] Done", file=sys.stderr)
