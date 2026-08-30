#!/usr/bin/env python3
"""Build every registered Doom WAD / ScummVM game twice -- once through the
real compression pipeline, once with the optimize/getFiles/removeFiles/
compressScummvmGame module args force-overridden to passthrough stubs (via
extendModules, from this script -- nothing in the repo's lib is touched) --
and record both sizes in compression-savings.csv.

Two build phases, not one eval: (1) cheap `nix eval` resolves each target to
a `.drv` path via a symlink wrapper (`.drvPath` never forces a build, even
through dynamic derivations -- see lib/optimize/dynamic.nix); (2) each `.drv`
builds via its own `nix build "<drv>^out" --print-out-paths` -- building the
wrapper realizes the real target too, at a real local path `du` reads
directly. No IFD.

Default: every target builds concurrently, one subprocess each -- not one
multi-target `nix build` call. Two reasons: a dynamic-derivation chain's
output path is unknown until built (`nix-store -q --outputs` errors on it),
so paths can't be pre-resolved; and a single multi-target `nix build` prints
*no* paths at all -- not even for successes -- if any one target fails.
Separate subprocesses keep failures independent; the nix daemon's own
job-slot admission still paces the real concurrency.

Safe now that instantiateDrv (lib/optimize/dynamic.nix) takes a real flock
around its own nix-instantiate step -- used to freeze the machine when many
ran concurrently. `--sequential` opts back into one-drv-at-a-time.

Usage:
  ./measure-compression.py                    # all games, batch-built
  ./measure-compression.py --sequential        # all games, one at a time
  ./measure-compression.py teenagent grim      # only games whose name
                                                # contains "teenagent"/"grim"
  ./measure-compression.py --doom              # only Doom wads
  ./measure-compression.py --scummvm           # only ScummVM games
  ./measure-compression.py --emulation         # only games.emulation.roms.*
  ./measure-compression.py --list              # print available game names
  ./measure-compression.py --list --missing    # ...only those with no CSV row yet
"""

import argparse
import concurrent.futures
import csv
import datetime
import fcntl
import json
import os
import pty
import re
import signal
import subprocess
import sys
import termios
import threading
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent
CSV_PATH = REPO_ROOT / "compression-savings.csv"
CSV_FIELDS = [
    "category",
    "game",
    "real_bytes",
    "mock_bytes",
    "savings_pct",
    "updated_at",
]
USER = "monyarm"

# nix's own build progress (downloads, "building '...'") is left inherited
# so the user can see something's happening; these two prefixes are the
# only thing filtered out, since a single pk3 can emit hundreds of them
# (one per member with no dedicated optimizer) and they add nothing here.
NOISY_TRACE_PREFIXES = b"trace: "

# Matches a leading ANSI escape (color codes etc) so a filtered trace line
# is still recognized even if nix colorizes its output first.
_ANSI_PREFIX_RE = re.compile(rb"^(?:\x1b\[[0-9;]*[a-zA-Z])*")


def human_size(n):
    size = float(n)
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if abs(size) < 1024 or unit == "TB":
            return f"{size:.0f}{unit}" if unit == "B" else f"{size:.1f}{unit}"
        size /= 1024


def format_pct(savings):
    """1 decimal by default, but keeps adding decimals until a genuinely
    nonzero difference actually shows -- otherwise e.g. a real 0.037%
    savings (89112920 vs 89145712 bytes) silently displays as "0.0%"."""
    if savings == 0:
        return "+0.0"
    for decimals in range(1, 11):
        s = f"{savings:+.{decimals}f}"
        if float(s) != 0.0:
            return s
    return f"{savings:+.10f}"


# Module args that stand between a fetched game and its final registered
# derivation; forcing each to a passthrough gives the pre-optimization
# baseline. removeFiles/getFiles cover installer-cruft pruning (e.g. GOG's
# gogCruft, Grim Fandango's FontsHD/MoviesHD trim); optimize/optimize' cover
# WAD/PK3 recompression (optimizePk3 was a separate, pk3-specific module arg
# -- removed when hosts/home/monyarm/games/Doom/wad's registration lines
# were unified to plain `optimize`, same as every other file type; there's
# nothing left to mock there anymore); compressScummvmGame covers
# per-engine audio.
MOCK_ARGS_NIX = """
{
  getFiles = lib.mkForce (paths: folderDrv: folderDrv);
  removeFiles = lib.mkForce (paths: folderDrv: folderDrv);
  optimize = lib.mkForce (src: src);
  optimize' = lib.mkForce (src: src);
  compressScummvmGame = lib.mkForce (opts: gameDrv: gameDrv);
}
"""

CONFIG_EXPR = """
let
  flake = builtins.getFlake (toString ./.);
  real = flake.homeConfigurations.{user};
  mocked = real.extendModules {
    modules = [ { _module.args = {mock_args}; } ];
  };
  # Not real.pkgs: that forces it through home-manager's own _module.args
  # resolution (fragile -- the same mechanism behind a real infinite-
  # recursion bug elsewhere in this repo), and isn't even guaranteed to
  # match the base pkgs, since other home-manager modules can layer their
  # own nixpkgs.overlays/config on top. Mirrors hosts/default.nix's own
  # pkgsGen construction directly instead.
  pkgs = import flake.inputs.nixpkgs {
    system = builtins.currentSystem;
    overlays = flake.lib.overlays;
    config.allowUnfree = true;
  };
  lib = pkgs.lib;
  sources = import ./sources.nix;
  # optimize's own tool invocations (oxipng/ffmpeg/wadptr/minijson/...) are
  # pinned to a *separate* nixpkgs revision (flake.nix's optimize-nixpkgs
  # input) so they don't get invalidated by unrelated nixpkgs bumps --
  # skipping this and just passing `pkgs` below silently rebuilds every
  # tool under the wrong pin, missing every cache hit real usage already
  # has. Mirrors hosts/modules/lib.nix's own optimizePkgs construction.
  optimizePkgs = import flake.inputs.optimize-nixpkgs {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
    overlays = import ./lib/optimize/overlays.nix {
      inherit sources;
      determinateNix = flake.inputs.determinate-nix-optimize.packages.${pkgs.stdenv.hostPlatform.system}.nix;
      craneLib = flake.inputs.crane.mkLib pkgs;
    };
  };
  # Doom WAD/PK3 registry entries (games.doom.wads.*) are never compressed
  # at registration -- every entry (wad or pk3 alike) only gets optimize
  # applied later, at mkDoom consumption time (hosts/home/monyarm/games/
  # Doom/wad/default.nix's args/game construction), never stored back onto
  # the registry value itself. Reaching for a standalone real customLib
  # here (not the module-threaded one) lets the "real" leg apply that same
  # final step directly on the registry value instead.
  customLib = import ./lib {
    inherit pkgs lib optimizePkgs;
    system = pkgs.stdenv.hostPlatform.system;
    mkOutOfStoreSymlink = p: p;
    # Must match hosts/modules/lib.nix's own customLib call -- this feeds
    # dynamic.nix's toolPathsJSON, baked into instantiateDrv's derivation
    # hash, so omitting it here builds a *different* instantiateDrv than
    # the real deploy needs (looks cached, isn't).
    nixWasmRustPath = flake.inputs.nix-wasm-rust;
    nixWasmRustOptimizePath = flake.inputs.nix-wasm-rust-optimize;
    niccupLib = flake.inputs.niccup.lib;
    config = {};
  };
  
  # `value` can be a derivation or a context-bearing string (e.g.
  # "${someDrv}/subdir") -- either works as a `ln -s` interpolation. A plain
  # symlink to `value`'s real store path, not a du-computing IFD: once
  # `nix build` realizes this target, `value` itself is realized too (as
  # its input) at a real, resolvable local path -- `du` can then just read
  # it directly in the driver, no second nix eval needed at all.
  mkTarget = value:
    pkgs.runCommand "target" { } ''
      ln -s "${value}" "$out"
    '';
  # .drvPath alone never forces a build -- even a dynamic-derivation
  # placeholder embeds fine into a new .drv's text unresolved -- so this is
  # safe to call in a cheap, no-building eval pass.
  getDrvPath = value: (mkTarget value).drvPath;
in
{body}
""".replace("{user}", USER).replace("{mock_args}", MOCK_ARGS_NIX)


def _is_noisy_line(line: bytes) -> bool:
    return _ANSI_PREFIX_RE.sub(b"", line).startswith(NOISY_TRACE_PREFIXES)


def _drain_pty_filtered(master_fd):
    """Forwards nix's stderr (connected to a pty) to our real stderr as-is,
    live carriage-return redraws (nix's compact progress bar) included --
    only genuine, complete newline-terminated lines matching a noisy trace
    prefix get dropped. Without a pty nix can't tell it's talking to a
    terminal and falls back to printing a new plain-text line per event
    (no colors, no in-place updates, no --log-format flag overrides this),
    which is what was flooding the terminal before."""
    buf = b""
    out = sys.stderr.buffer
    while True:
        try:
            data = os.read(master_fd, 4096)
        except OSError:
            break
        if not data:
            break
        buf += data
        while True:
            idx_n = buf.find(b"\n")
            idx_r = buf.find(b"\r")
            if idx_n == -1 and idx_r == -1:
                break
            if idx_r != -1 and (idx_n == -1 or idx_r < idx_n):
                out.write(buf[: idx_r + 1])
                out.flush()
                buf = buf[idx_r + 1 :]
            else:
                line = buf[: idx_n + 1]
                if not _is_noisy_line(line):
                    out.write(line)
                    out.flush()
                buf = buf[idx_n + 1 :]
    if buf and not _is_noisy_line(buf):
        out.write(buf)
        out.flush()


def _ensure_terminated(proc):
    """Make sure the nix child is actually gone before we return, on every
    exit path including Ctrl-C -- nix may have an in-flight remote build
    talking to a builder daemon, and tearing down its stdio (e.g. closing
    the pty master) out from under it while it's still mid-shutdown is an
    unclean disconnect, not the graceful abort a plain SIGINT gives it.
    Escalates SIGINT -> SIGTERM -> SIGKILL, waiting between each."""
    if proc.poll() is not None:
        return
    for sig, timeout in (
        (signal.SIGINT, 10),
        (signal.SIGTERM, 5),
        (signal.SIGKILL, None),
    ):
        proc.send_signal(sig)
        try:
            proc.wait(timeout=timeout)
            return
        except subprocess.TimeoutExpired:
            continue


def nix_eval_json(body, max_jobs, cores):
    expr = CONFIG_EXPR.replace("{body}", body)
    cmd = [
        "nix",
        "eval",
        "--impure",
        "-L",
        "--json",
        "--max-jobs",
        str(max_jobs),
        "--cores",
        str(cores),
        "--expr",
        expr,
    ]

    if not sys.stderr.isatty():
        # Not an interactive terminal ourselves (e.g. output redirected to a
        # file) -- a pty would be pointless, just filter the plain-text log.
        proc = subprocess.Popen(
            cmd, cwd=REPO_ROOT, stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        try:

            def stream_stderr():
                for line in proc.stderr:
                    if not _is_noisy_line(line):
                        sys.stderr.buffer.write(line)
                        sys.stderr.buffer.flush()

            t = threading.Thread(target=stream_stderr, daemon=True)
            t.start()
            stdout_data = proc.stdout.read()
            proc.wait()
            t.join()
        finally:
            _ensure_terminated(proc)
    else:
        master_fd, slave_fd = pty.openpty()
        try:
            winsize = fcntl.ioctl(sys.stderr.fileno(), termios.TIOCGWINSZ, b"\0" * 8)
            fcntl.ioctl(slave_fd, termios.TIOCSWINSZ, winsize)
        except OSError:
            pass
        # Disable \n -> \r\n translation (ONLCR): otherwise every ordinary
        # line gets a \r inserted right before its \n, which looks
        # identical to a live progress-bar redraw and defeats the
        # noisy-line filter below before it ever sees a real "\n".
        attrs = termios.tcgetattr(slave_fd)
        attrs[1] &= ~termios.ONLCR
        termios.tcsetattr(slave_fd, termios.TCSANOW, attrs)
        proc = subprocess.Popen(
            cmd,
            cwd=REPO_ROOT,
            stdout=subprocess.PIPE,
            stderr=slave_fd,
            stdin=slave_fd,
            close_fds=True,
        )
        os.close(slave_fd)

        try:
            stdout_holder = {}

            def read_stdout():
                stdout_holder["data"] = proc.stdout.read()

            t = threading.Thread(target=read_stdout, daemon=True)
            t.start()
            _drain_pty_filtered(master_fd)
            t.join()
            proc.wait()
            stdout_data = stdout_holder["data"]
        finally:
            # Terminate the child BEFORE closing the pty master -- otherwise
            # an interrupted _drain_pty_filtered above closes master_fd
            # first, which is what was cutting nix off mid-shutdown.
            _ensure_terminated(proc)
            os.close(master_fd)

    if proc.returncode != 0:
        sys.exit(f"nix eval failed (exit {proc.returncode})")
    return json.loads(stdout_data)


def list_names():
    return nix_eval_json(
        """{
  doom = builtins.attrNames real.config.games.doom.wads;
  scummvm = builtins.attrNames real.config.games.scummvm.games;
  emulation = builtins.attrNames real.config.games.emulation.roms;
}""",
        max_jobs=1,
        cores=1,
    )


def matches(name, patterns):
    if not patterns:
        return True
    return any(p.lower() in name.lower() for p in patterns)


def names_nix(names):
    return "[ " + " ".join(f'"{n}"' for n in names) + " ]"


def build_measure_body(targets):
    """targets: {"doom": [names], "scummvm": [names], "emulation": [names]}.
    Each leg wrapped in getDrvPath -- a plain symlink-to-value target, not a
    size computation."""
    parts = []
    if targets["doom"]:
        parts.append(f"""
  doom = let names = {names_nix(targets["doom"])}; in
    builtins.listToAttrs (map (n: {{
      name = n;
      value = {{
        real = getDrvPath (customLib.optimize real.config.games.doom.wads.${{n}});
        mock = getDrvPath mocked.config.games.doom.wads.${{n}};
      }};
    }}) names);""")
    if targets["scummvm"]:
        parts.append(f"""
  scummvm = let names = {names_nix(targets["scummvm"])}; in
    builtins.listToAttrs (map (n: {{
      name = n;
      value = {{
        real = getDrvPath real.config.games.scummvm.games.${{n}}.path;
        mock = getDrvPath mocked.config.games.scummvm.games.${{n}}.path;
      }};
    }}) names);""")
    if targets["emulation"]:
        parts.append(f"""
  emulation = let names = {names_nix(targets["emulation"])}; in
    builtins.listToAttrs (map (n: {{
      name = n;
      value = {{
        real = getDrvPath (customLib.compressRom real.config.games.emulation.roms.${{n}});
        mock = getDrvPath real.config.games.emulation.roms.${{n}};
      }};
    }}) names);""")
    return "{\n" + "\n".join(parts) + "\n}"


def get_drv_paths(targets):
    """Phase 1: one cheap eval, `.drvPath` only -- never forces a build."""
    body = build_measure_body(targets)
    result = nix_eval_json(body, max_jobs=1, cores=1)
    return {
        "doom": result.get("doom", {}),
        "scummvm": result.get("scummvm", {}),
        "emulation": result.get("emulation", {}),
    }


def read_size(path):
    """du -sb --apparent-size on an already-built local path -- no nix
    involvement at all, everything's already realized by build_sequential/
    build_batch."""
    out = subprocess.run(
        ["du", "-Llsb", "--apparent-size", path],
        capture_output=True,
        text=True,
        check=True,
    ).stdout
    return int(out.split()[0])


def build_one(category, name, leg, drv, max_jobs, cores):
    """Runs `nix build <drv>^out --print-out-paths` for a single target.
    Returns (category, name, leg, real_path), real_path None on failure --
    shared by build_batch (called concurrently, one subprocess per target)
    and build_sequential (called one at a time)."""
    cmd = [
        "nix",
        "build",
        "--no-link",
        "--print-out-paths",
        "-L",
        "--max-jobs",
        str(max_jobs),
        "--cores",
        str(cores),
        f"{drv}^out",
    ]
    print(drv)
    proc = subprocess.run(
        " ".join(cmd),
        shell=True,
        cwd=REPO_ROOT,
        stdout=subprocess.PIPE,
        text=True,
        check=False,
    )
    if proc.returncode != 0 or not proc.stdout.strip():
        return category, name, leg, None
    target_path = proc.stdout.strip().splitlines()[-1]
    return category, name, leg, os.path.realpath(target_path)


def build_batch(drv_list, max_jobs, cores):
    """drv_list: [(category, name, leg, drvpath), ...]. Launches every
    target's own `nix build` concurrently and lets the nix daemon's own
    job-slot admission pace the real work -- safe now that
    lib/optimize/dynamic.nix's instantiateDrv takes out a real flock
    (dynamic-optimize.lock) around its own expensive nix-instantiate step,
    so concurrently-invalidated games no longer pile up their eval work and
    overload the machine the way they used to. Returns (sizes, failed) with
    the same shape as build_sequential."""
    print(f"--- building {len(drv_list)} derivations concurrently ---")
    sizes = {}
    failed = set()
    with concurrent.futures.ThreadPoolExecutor(max_workers=len(drv_list)) as pool:
        futures = [
            pool.submit(build_one, c, n, leg, drv, max_jobs, cores)
            for c, n, leg, drv in drv_list
        ]
        for future in concurrent.futures.as_completed(futures):
            category, name, leg, real_path = future.result()
            if real_path is None:
                print(
                    f"WARNING: build failed for {category}/{name} ({leg}), dropping from results",
                    file=sys.stderr,
                )
                failed.add((category, name))
                continue
            sizes[(category, name, leg)] = read_size(real_path)
    return sizes, failed


def build_sequential(drv_list, max_jobs, cores):
    """drv_list: [(category, name, leg, drvpath), ...]. Builds each ^out one
    at a time -- opt-in via --sequential, for forcing every top-level game to
    build one after another (see build_batch, the default, for why this
    isn't needed just to avoid overloading the machine anymore). Returns
    (sizes, failed): sizes is {(category, name, leg): bytes} for everything
    that built; failed is the set of (category, name) pairs where either leg
    failed."""
    sizes = {}
    failed = set()
    for i, (category, name, leg, drv) in enumerate(drv_list, 1):
        print(f"--- [{i}/{len(drv_list)}] building {category}/{name} ({leg}) ---")
        _, _, _, real_path = build_one(category, name, leg, drv, max_jobs, cores)
        if real_path is None:
            print(
                f"WARNING: build failed for {category}/{name} ({leg}), dropping from results",
                file=sys.stderr,
            )
            failed.add((category, name))
            continue
        sizes[(category, name, leg)] = read_size(real_path)
    return sizes, failed


TOTAL_KEY = ("TOTAL", "")


def load_csv():
    if not CSV_PATH.exists():
        return {}
    with CSV_PATH.open(newline="") as f:
        rows = {(row["category"], row["game"]): row for row in csv.DictReader(f)}
    rows.pop(TOTAL_KEY, None)
    return rows


def save_csv(rows):
    now = datetime.datetime.now(datetime.UTC).isoformat(timespec="seconds")
    total_real = sum(int(r["real_bytes"]) for r in rows.values())
    total_mock = sum(int(r["mock_bytes"]) for r in rows.values())
    savings = 0.0 if total_mock == 0 else (1 - total_real / total_mock) * 100
    total_row = {
        "category": "TOTAL",
        "game": "",
        "real_bytes": total_real,
        "mock_bytes": total_mock,
        "savings_pct": format_pct(savings),
        "updated_at": now,
    }
    with CSV_PATH.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=CSV_FIELDS)
        writer.writeheader()
        for key in sorted(rows):
            writer.writerow(rows[key])
        writer.writerow(total_row)
    print(
        f"TOTAL    {'':30} {total_mock:>12} ({human_size(total_mock)}) -> "
        f"{total_real:>12} ({human_size(total_real)})  ({format_pct(savings)}%)"
    )


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "patterns", nargs="*", help="substrings to filter game names (default: all)"
    )
    parser.add_argument(
        "--list", action="store_true", help="list available game names and exit"
    )
    parser.add_argument(
        "--missing",
        action="store_true",
        help="with --list, only show games that have no row in compression-savings.csv yet",
    )
    parser.add_argument("--doom", action="store_true", help="restrict to Doom wads")
    parser.add_argument(
        "--scummvm", action="store_true", help="restrict to ScummVM games"
    )
    parser.add_argument(
        "--emulation", action="store_true", help="restrict to games.emulation.roms.*"
    )
    parser.add_argument(
        "--sequential",
        action="store_true",
        help="build one game at a time instead of handing the whole batch to one nix build call",
    )
    parser.add_argument("--max-jobs", type=int, default=6)
    parser.add_argument("--cores", type=int, default=6)
    args = parser.parse_args()

    # deploy.sh runs `nix fmt` (whole repo) before every build; this doesn't,
    # so a build here could measure/cache pre-format bytes that then differ
    # from what deploy.sh's build sees once it formats -- silently
    # invalidating every dynamic derivation deploy.sh's build actually needs.
    subprocess.run(["nix", "fmt"], cwd=REPO_ROOT, check=False)

    categories = []
    if args.doom:
        categories.append("doom")
    if args.scummvm:
        categories.append("scummvm")
    if args.emulation:
        categories.append("emulation")
    if not categories:
        categories = ["doom", "scummvm", "emulation"]

    names = list_names()

    if args.list or args.missing:
        measured = load_csv() if args.missing else {}
        for category in categories:
            for n in names[category]:
                if not args.missing or (category, n) not in measured:
                    print(f"{category:8} {n}")
        return

    targets = {
        c: (
            [n for n in names[c] if matches(n, args.patterns)]
            if c in categories
            else []
        )
        for c in ("doom", "scummvm", "emulation")
    }

    if not targets["doom"] and not targets["scummvm"] and not targets["emulation"]:
        sys.exit("No games matched the given patterns.")

    rows = load_csv()

    print("=== resolving derivations (1 cheap eval, no building) ===")
    drv_map = get_drv_paths(targets)
    drv_list = [
        (category, name, leg, drv_map[category][name][leg])
        for category in categories
        for name in targets[category]
        for leg in ("real", "mock")
    ]

    if args.sequential:
        print(f"=== building {len(drv_list)} derivations, one at a time ===")
        sizes, failed = build_sequential(
            drv_list, max_jobs=args.max_jobs, cores=args.cores
        )
    else:
        sizes, failed = build_batch(drv_list, max_jobs=args.max_jobs, cores=args.cores)

    for category in categories:
        targets[category] = [
            n for n in targets[category] if (category, n) not in failed
        ]
    if not targets["doom"] and not targets["scummvm"] and not targets["emulation"]:
        sys.exit("Every build failed, nothing to measure.")

    now = datetime.datetime.now(datetime.UTC).isoformat(timespec="seconds")

    for category in categories:
        for name in targets[category]:
            real_b = sizes[(category, name, "real")]
            mock_b = sizes[(category, name, "mock")]
            savings = 0.0 if mock_b == 0 else (1 - real_b / mock_b) * 100
            rows[(category, name)] = {
                "category": category,
                "game": name,
                "real_bytes": real_b,
                "mock_bytes": mock_b,
                "savings_pct": format_pct(savings),
                "updated_at": now,
            }
            print(
                f"{category:8} {name:30} {mock_b:>12} ({human_size(mock_b)}) -> "
                f"{real_b:>12} ({human_size(real_b)})  ({format_pct(savings)}%)"
            )

    save_csv(rows)
    print(f"\nWrote {CSV_PATH}")


if __name__ == "__main__":
    main()
