#!/usr/bin/env python3
"""Prefetch every cache-available NAR in a toplevel closure."""

import argparse
import json
import os
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed


def run(cmd, *, check=True):
    return subprocess.run(cmd, check=check, text=True, capture_output=True)


def human_size(n):
    n = float(n)
    for unit in ("B", "KiB", "MiB", "GiB", "TiB"):
        if n < 1024 or unit == "TiB":
            return f"{n:.0f} {unit}" if unit == "B" else f"{n:.1f} {unit}"
        n /= 1024


def drv_path(toplevel, impure):
    if toplevel.endswith(".drv"):
        return toplevel
    cmd = ["nix", "eval", "--raw", f"{toplevel}.drvPath"]
    if impure:
        cmd.append("--impure")
    return run(cmd).stdout.strip()


def closure(drv):
    out = run(["nix-store", "-qR", "--include-outputs", drv]).stdout
    return [line for line in out.splitlines() if line.startswith("/nix/store/")]


def cache_info(cache, path):
    p = run(
        ["nix", "path-info", "--store", cache, "--json", path],
        check=False,
    )
    if p.returncode != 0 or not p.stdout.strip():
        return None
    try:
        return json.loads(p.stdout).get(path)
    except json.JSONDecodeError:
        return None


def main():
    ap = argparse.ArgumentParser(
        description="Download every cache NAR in a toplevel closure with "
        "`nix store prefetch-file`."
    )
    ap.add_argument("toplevel", help="flake installable or .drv path")
    ap.add_argument(
        "--cache",
        action="append",
        help="binary cache to query (repeatable; default: cache.nixos.org)",
    )
    ap.add_argument("--impure", action="store_true", help="pass --impure to nix eval")
    ap.add_argument("--jobs", type=int, default=8, help="parallel cache lookups")
    ap.add_argument("--retries", type=int, default=3, help="prefetch retries")
    ap.add_argument(
        "--dry-run", action="store_true", help="list NARs without prefetching"
    )
    ap.add_argument(
        "--skip-build-dry-run",
        action="store_true",
        help="skip the initial `nix build --dry-run`",
    )
    args = ap.parse_args()
    caches = args.cache or ["https://cache.nixos.org"]

    drv = drv_path(args.toplevel, args.impure)
    print(f"toplevel drv: {drv}", flush=True)

    if not args.skip_build_dry_run:
        cmd = ["nix", "build", args.toplevel, "--dry-run"]
        if args.impure:
            cmd.append("--impure")
        subprocess.run(cmd, check=False)

    paths = sorted(set(closure(drv)))
    print(f"closure paths: {len(paths)}", flush=True)

    paths = [p for p in paths if not os.path.exists(p)]
    print(f"missing locally: {len(paths)}", flush=True)

    def lookup(path):
        for cache in caches:
            info = cache_info(cache, path)
            if info and info.get("url"):
                size = info.get("downloadSize") or info.get("narSize") or 0
                return (
                    path,
                    cache.rstrip("/") + "/" + info["url"],
                    info.get("downloadHash"),
                    size,
                )
        return path, None, None, 0

    found = []
    with ThreadPoolExecutor(max_workers=max(1, args.jobs)) as pool:
        futures = [pool.submit(lookup, path) for path in paths]
        for future in as_completed(futures):
            path, url, digest, size = future.result()
            if url:
                found.append((path, url, digest, size))

    seen = set()
    nars = []
    for path, url, digest, size in found:
        if url in seen:
            continue
        seen.add(url)
        nars.append((path, url, digest, size))

    nars.sort(key=lambda item: (item[3], item[0]))
    total = sum(item[3] for item in nars)
    print(f"cache NARs: {len(nars)} ({human_size(total)})", flush=True)

    if args.dry_run:
        for path, url, _, size in nars:
            print(f"{human_size(size):>9}  {path} -> {url}")
        return 0

    failures = 0
    for index, (path, url, digest, size) in enumerate(nars, 1):
        cmd = ["nix", "store", "prefetch-file", "--verbose"]
        if digest:
            cmd += ["--expected-hash", digest]
        cmd.append(url)
        print(f"[{index}/{len(nars)}] {human_size(size):>9}  {path}", flush=True)
        for attempt in range(1, args.retries + 1):
            if subprocess.run(cmd, check=False, text=True).returncode == 0:
                break
            if attempt == args.retries:
                failures += 1
                print(f"FAILED {url}", file=sys.stderr, flush=True)
            else:
                time.sleep(min(2**attempt, 10))

    print(f"prefetched {len(nars) - failures}/{len(nars)}, {failures} failed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
