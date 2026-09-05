#!/usr/bin/env python3
"""Local-only proxy between open-steam-report.sh's report.html and the
SteamGridDB API v2. Holds STEAMGRIDDB_API_KEY server-side so the (world-
readable, Nix-store-hosted) report page never sees it; the browser only
ever talks to 127.0.0.1. See hosts/home/monyarm/games/Steam/report.nix's
sgdbScript for the client side.

Search results carry the SteamGridDB CDN urls directly, so downloading a
chosen image (in /submit) needs no auth at all.
"""

import base64
import hashlib
import http.server
import json
import os
import re
import sys
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

API_BASE = "https://www.steamgriddb.com/api/v2"
PORT = 8743
OUT_FILE = os.path.join(os.environ.get("TMPDIR", "/tmp"), "steamgriddb-apply.json")
CACHE_FILE = os.path.join(os.environ.get("TMPDIR", "/tmp"), "steamgriddb-cache.json")
USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64; rv:144.0) Gecko/20100101 Firefox/144.0"
REPO_ROOT = os.environ.get("REPO_ROOT")

# shortcuts.vdf.nix strips the "/nix/store/<hash>-" prefix before handing
# this to us (embedding literal store-path-shaped text in a derivation
# makes Nix warn loudly, even with no real string context behind it), so
# this is just "<dirname>/<relative-path>", not a real store path.
STORE_TAIL_RE = re.compile(r"^([^/]+)/(.+)$")

# name -> SteamGridDB game id barely ever changes once resolved, so cache it
# for a year; a game's available images change often (people upload new art
# constantly), so cache those results for only a few minutes.
LOOKUP_TTL = 365 * 24 * 3600
SEARCH_TTL = 5 * 60

API_KEY = os.environ.get("STEAMGRIDDB_API_KEY")
if not API_KEY:
    print(
        "STEAMGRIDDB_API_KEY is not set. Add it to secrets/env.json (sops secrets/env.json), "
        "same pattern as the other API keys .envrc's TODO comment lists.",
        file=sys.stderr,
    )
    sys.exit(1)

# type -> (endpoint, extra query params). `grid`/`wide` are handled
# separately below (see GRID_ORIENTATIONS) -- SteamGridDB tags grids with
# an exact "dimensions" bucket per upload rather than a fixed convention,
# and filtering to a guessed subset of buckets silently dropped real
# results twice in a row (hdoom's 920x430 "wide" grids; a "300x450"
# portrait bucket that turned out not to even exist). Simpler and robust
# to whatever buckets SteamGridDB actually uses: fetch every grid once,
# unfiltered, and classify each by its own reported width vs height.
TYPE_ENDPOINTS = {
    "hero": ("heroes", {}),
    "logo": ("logos", {}),
    "icon": ("icons", {}),
}

# "grid" (portrait) vs "wide" (landscape) -- landscape = width > height, so
# a perfectly square grid image (neither > the other) matches neither and
# is excluded from both; real grid/wide art is never square in practice.
GRID_ORIENTATIONS = {
    "grid": lambda w, h: h > w,
    "wide": lambda w, h: w > h,
}

# Persisted across proxy restarts (TMPDIR survives the session, not just
# this process) -- otherwise every run re-does a full autocomplete + image
# lookup for every game, which is slow and burns into SteamGridDB's rate
# limit for no reason once the answer's already known.
cache_lock = threading.Lock()


def load_cache():
    try:
        with open(CACHE_FILE) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {"ids": {}, "search": {}}


cache = load_cache()
cache.setdefault("resolve", {})
cache.setdefault("search", {})


def save_cache():
    tmp = CACHE_FILE + ".tmp"
    with open(tmp, "w") as f:
        json.dump(cache, f)
    os.replace(tmp, CACHE_FILE)


def cache_get(section, key, ttl):
    with cache_lock:
        entry = cache[section].get(key)
    try:
        if entry is not None and time.time() - entry["ts"] <= ttl:
            return entry["value"], True
    except (KeyError, TypeError):
        pass  # stale/pre-TTL cache file shape -- treat as a miss
    return None, False


def cache_set(section, key, value):
    with cache_lock:
        cache[section][key] = {"value": value, "ts": time.time()}
        save_cache()


def sgdb_get(path, params=None):
    url = API_BASE + path
    if params:
        url += "?" + urllib.parse.urlencode(params)
    # Cloudflare blocks urllib's default User-Agent outright (error code
    # 1010) regardless of a valid API key -- same UA as fetch_and_hash.
    req = urllib.request.Request(
        url,
        headers={"Authorization": f"Bearer {API_KEY}", "User-Agent": USER_AGENT},
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.load(resp)


# Returns {"id":.., "name":..} -- the "name" is SteamGridDB's own title for
# whatever autocomplete matched, so the modal can show the user what game it
# actually searched for (autocomplete sometimes matches the wrong game).
def resolve_sgdb_match(name):
    cached, hit = cache_get("resolve", name, LOOKUP_TTL)
    if hit:
        return cached
    try:
        data = sgdb_get(f"/search/autocomplete/{urllib.parse.quote(name)}")
    except urllib.error.HTTPError as e:
        print(f"lookup failed for {name!r}: {e} {e.read()}", file=sys.stderr)
        match = {"id": None, "name": None}
    else:
        results = data.get("data") or []
        if data.get("success") and results:
            match = {"id": results[0]["id"], "name": results[0]["name"]}
        else:
            match = {"id": None, "name": None}
    cache_set("resolve", name, match)
    return match


def resolve_sgdb_id(name):
    return resolve_sgdb_match(name)["id"]


# nsfw/humor are separate booleans on the real API (confirmed against the
# PySteamGridDB wrapper's query building -- "true"/"false" strings, not a
# combined "any" value), so getting regular+nsfw+humor images in one search
# means querying all 4 combinations and tagging each hit with which one it
# came from; the modal's filter checkboxes then just show/hide by tag,
# client-side, with no need to re-query.
NSFW_HUMOR_COMBOS = [(False, False), (True, False), (False, True), (True, True)]


def fetch_type_results(endpoint, sgdb_id, extra_params):
    results = []
    seen_ids = set()
    for nsfw, humor in NSFW_HUMOR_COMBOS:
        params = {
            **extra_params,
            "nsfw": str(nsfw).lower(),
            "humor": str(humor).lower(),
        }
        try:
            data = sgdb_get(f"/{endpoint}/game/{sgdb_id}", params)
        except urllib.error.HTTPError as e:
            print(
                f"search combo nsfw={nsfw} humor={humor} failed: {e} {e.read()}",
                file=sys.stderr,
            )
            continue
        for d in data.get("data", []):
            if d["id"] in seen_ids:
                continue
            seen_ids.add(d["id"])
            results.append(
                {
                    "thumb": d["thumb"],
                    "url": d["url"],
                    "nsfw": nsfw,
                    "humor": humor,
                    "width": d["width"],
                    "height": d["height"],
                }
            )
    return results


# shortcuts.vdf.nix's `sourceFile` option reports a file's position via
# options.game.files, but this repo's autoImport (hosts/default.nix) copies
# each games/ subdirectory into the store *separately*, so the position is
# only relative to that small per-directory copy (e.g. "nes/castlevania.nix",
# not the full repo-relative path) -- the intermediate directories
# (games/Emulation/nes/) are lost. Recovered here by searching the real
# checkout for a directory with the same basename as the store copy that
# also contains the same relative file; ambiguous only if two same-named
# directories both happen to contain a same-named file, which doesn't
# occur in this repo.
def resolve_repo_path(store_file):
    if not store_file or not REPO_ROOT:
        return store_file
    m = STORE_TAIL_RE.match(store_file)
    if not m:
        return store_file
    dirname, rel = m.groups()
    for candidate in Path(REPO_ROOT).rglob(dirname):
        if candidate.is_dir() and (candidate / rel).is_file():
            return str(candidate / rel)
    return store_file


def fetch_and_hash(url):
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=30) as resp:
        data = resp.read()
    digest = hashlib.sha256(data).digest()
    return "sha256-" + base64.b64encode(digest).decode()


# Started (fire-and-forget, from the report's JS) the moment a thumbnail is
# clicked in the modal, well before the user hits Submit -- overlaps the
# fetch+hash work with however long they keep browsing/picking, instead of
# doing it all serially, one URL at a time, only after Submit is clicked.
prefetch_lock = threading.Lock()
prefetch_cache = {}  # url -> {"event": threading.Event(), "sha256": str|None}


def start_prefetch(url):
    with prefetch_lock:
        if url in prefetch_cache:
            return
        entry = {"event": threading.Event(), "sha256": None}
        prefetch_cache[url] = entry

    def worker():
        try:
            entry["sha256"] = fetch_and_hash(url)
        except urllib.error.URLError as e:
            print(f"prefetch failed for {url}: {e}", file=sys.stderr)
        finally:
            entry["event"].set()

    threading.Thread(target=worker, daemon=True).start()


def get_hash(url):
    with prefetch_lock:
        entry = prefetch_cache.get(url)
    if entry is None:
        return fetch_and_hash(url)
    entry["event"].wait(timeout=30)
    return entry["sha256"] if entry["sha256"] is not None else fetch_and_hash(url)


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        sys.stderr.write(f"{self.address_string()} - {fmt % args}\n")

    def _send_json(self, status, payload):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        query = urllib.parse.parse_qs(parsed.query)

        if parsed.path == "/health":
            return self._send_json(200, {"ok": True})

        if parsed.path == "/lookup":
            name = query.get("name", [None])[0]
            if not name:
                return self._send_json(400, {"error": "missing name"})
            return self._send_json(200, {"found": resolve_sgdb_id(name) is not None})

        if parsed.path == "/prefetch":
            url = query.get("url", [None])[0]
            if not url:
                return self._send_json(400, {"error": "missing url"})
            start_prefetch(url)
            return self._send_json(200, {"ok": True})

        if parsed.path == "/search":
            name = query.get("name", [None])[0]
            asset_type = query.get("type", [None])[0]
            if not name or (
                asset_type not in TYPE_ENDPOINTS and asset_type not in GRID_ORIENTATIONS
            ):
                return self._send_json(400, {"error": "missing/invalid name or type"})

            match = resolve_sgdb_match(name)
            sgdb_id = match["id"]

            if asset_type in GRID_ORIENTATIONS:
                # grid and wide share one unfiltered "all grids" fetch,
                # cached once, then split by orientation on every request --
                # half the SteamGridDB calls of fetching each separately,
                # and neither guesses at dimension buckets.
                raw_key = f"{name}:grids-raw"
                raw, hit = cache_get("search", raw_key, SEARCH_TTL)
                if not hit:
                    raw = (
                        []
                        if sgdb_id is None
                        else fetch_type_results("grids", sgdb_id, {})
                    )
                    cache_set("search", raw_key, raw)
                is_match = GRID_ORIENTATIONS[asset_type]
                results = [r for r in raw if is_match(r["width"], r["height"])]
                return self._send_json(
                    200, {"matchedName": match["name"], "results": results}
                )

            cache_key = f"{name}:{asset_type}"
            cached, hit = cache_get("search", cache_key, SEARCH_TTL)
            if hit:
                return self._send_json(
                    200, {"matchedName": match["name"], "results": cached}
                )

            if sgdb_id is None:
                return self._send_json(200, {"matchedName": None, "results": []})
            endpoint, extra_params = TYPE_ENDPOINTS[asset_type]
            results = fetch_type_results(endpoint, sgdb_id, extra_params)
            cache_set("search", cache_key, results)
            return self._send_json(
                200, {"matchedName": match["name"], "results": results}
            )

        return self._send_json(404, {"error": "not found"})

    def do_POST(self):
        if self.path != "/submit":
            return self._send_json(404, {"error": "not found"})

        length = int(self.headers.get("Content-Length", 0))
        picks = json.loads(self.rfile.read(length) or b"[]")

        results = []
        for pick in picks:
            try:
                sha256 = get_hash(pick["url"])
            except (urllib.error.URLError, KeyError) as e:
                self.log_message("failed to fetch %s: %s", pick.get("url"), e)
                continue
            pick = {**pick, "file": resolve_repo_path(pick.get("file"))}
            results.append({**pick, "sha256": sha256})

        with open(OUT_FILE, "w") as f:
            json.dump(
                {
                    "instructions": (
                        "For each entry below, open `file` and inside the game block "
                        "matched by `name`/`appId` (see hosts/home/monyarm/games/Steam/"
                        "shortcuts.vdf.nix's gameSubmodule `images` option), set "
                        'images.<type> = pkgs.fetchurl { url = "<url>"; sha256 = "<sha256>"; };'
                    ),
                    "picks": results,
                },
                f,
                indent=2,
            )

        self._send_json(200, {"ok": True, "path": OUT_FILE, "count": len(results)})
        threading.Thread(target=self.server.shutdown).start()


def main():
    # Plain HTTPServer handles one request at a time -- with a couple hundred
    # game cards each firing a /lookup badge check on load, that serialized
    # every real SteamGridDB API round-trip behind the last, badges took
    # minutes to appear and blocked /search too. ThreadingHTTPServer runs
    # requests concurrently (stdlib, no new dependency).
    server = http.server.ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    print(f"steamgriddb-proxy listening on http://127.0.0.1:{PORT}")
    server.serve_forever()


if __name__ == "__main__":
    main()
