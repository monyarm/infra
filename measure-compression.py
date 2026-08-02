#!/usr/bin/env python3
"""Build every registered Doom WAD / ScummVM game twice -- once through the
real compression pipeline, once with the optimize/getFiles/removeFiles/
compressScummvmGame module args force-overridden to passthrough stubs (via
extendModules, from this script -- nothing in the repo's lib is touched) --
and record both sizes in compression-savings.csv.

Sizes are read via a getSize derivation (du -sb wrapped in a runCommand) and
import-from-derivation, not a separate `nix build` + `nix path-info`/`du`
subprocess dance -- that way the actual build happens exactly the way any
plain `nix build`/`nix eval` on this flake would (same local/remote builder
resolution as everything else), so there's nothing for this script to get
out of sync with. Both real and mock, for every requested game, are computed
in a single `nix eval` call, so the (substantial, ~10s) cost of constructing
pkgs only gets paid once per run.

Usage:
  ./measure-compression.py                    # all games
  ./measure-compression.py teenagent grim      # only games whose name
                                                # contains "teenagent"/"grim"
  ./measure-compression.py --doom              # only Doom wads
  ./measure-compression.py --scummvm           # only ScummVM games
  ./measure-compression.py --list              # print available game names
  ./measure-compression.py --list --missing    # ...only those with no CSV row yet
"""

import argparse
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
CSV_FIELDS = ["category", "game", "real_bytes", "mock_bytes", "savings_pct", "updated_at"]
USER = "monyarm"

# nix's own build progress (downloads, "building '...'") is left inherited
# so the user can see something's happening; these two prefixes are the
# only thing filtered out, since a single pk3 can emit hundreds of them
# (one per member with no dedicated optimizer) and they add nothing here.
NOISY_TRACE_PREFIXES = (b"trace: ")

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
# gogCruft, Grim Fandango's FontsHD/MoviesHD trim); optimize'/optimizePk3
# cover WAD/PK3 recompression; compressScummvmGame covers per-engine audio.
MOCK_ARGS_NIX = """
{
  getFiles = lib.mkForce (paths: folderDrv: folderDrv);
  removeFiles = lib.mkForce (paths: folderDrv: folderDrv);
  optimize = lib.mkForce (src: src);
  optimize' = lib.mkForce (src: src);
  optimizePk3 = lib.mkForce (pk3: pk3);
  compressScummvmGame = lib.mkForce (opts: gameDrv: gameDrv);
}
"""

CONFIG_EXPR = """
let
  flake = builtins.getFlake (toString ./.);
  lib = flake.inputs.nixpkgs.lib;
  real = flake.homeConfigurations.{user};
  mocked = real.extendModules {
    modules = [ { _module.args = {mock_args}; } ];
  };
  pkgs = real.pkgs;
  # Doom WAD/PK3 registry entries (games.doom.wads.*) aren't uniformly
  # compressed at registration -- pk3-sourced ones already went through
  # optimizePk3 (correctly mocked above), but plain .wad lumps only get
  # optimize' applied later, at mkDoom consumption time. Reaching for a
  # standalone real customLib here (not the module-threaded one) lets the
  # "real" leg apply that same final step directly on the registry value;
  # optimize' is a pk7/ipk7 no-op, so this is safe to layer on top of an
  # already-optimizePk3'd entry too.
  customLib = import ./lib {
    inherit pkgs lib;
    system = pkgs.stdenv.hostPlatform.system;
    mkOutOfStoreSymlink = p: p;
    config = null;
  };
  # Reads a size back via IFD instead of a separate `nix build` + query --
  # this way the build happens through the exact same mechanism (and
  # builder config) as any other `nix build`/`nix eval` on this flake, so
  # there's no separate "did the script build this the same way I would
  # have" question. `value` can be a derivation or a context-bearing string
  # (e.g. "${someDrv}/subdir") -- either works as a `du` interpolation.
  getSize = value:
    lib.toInt (
      lib.removeSuffix "\\n" (
        builtins.readFile (
          pkgs.runCommand "size" { } ''
            du -sb --apparent-size "${value}" | cut -f1 > $out
          ''
        )
      )
    );
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
    for sig, timeout in ((signal.SIGINT, 10), (signal.SIGTERM, 5), (signal.SIGKILL, None)):
        proc.send_signal(sig)
        try:
            proc.wait(timeout=timeout)
            return
        except subprocess.TimeoutExpired:
            continue


def nix_eval_json(body, max_jobs, cores):
    expr = CONFIG_EXPR.replace("{body}", body)
    cmd = ["nix", "eval", "--impure", "--json", "--max-jobs", str(max_jobs), "--cores", str(cores), "--expr", expr]

    if not sys.stderr.isatty():
        # Not an interactive terminal ourselves (e.g. output redirected to a
        # file) -- a pty would be pointless, just filter the plain-text log.
        proc = subprocess.Popen(cmd, cwd=REPO_ROOT, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
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
            cmd, cwd=REPO_ROOT, stdout=subprocess.PIPE, stderr=slave_fd, stdin=slave_fd, close_fds=True
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


def measure_all(targets, max_jobs, cores):
    """targets: {"doom": [names], "scummvm": [names]}. Returns the same
    shape with {name: {"real": bytes, "mock": bytes}} values, in one call."""
    parts = []
    if targets["doom"]:
        parts.append(f"""
  doom = let names = {names_nix(targets["doom"])}; in
    builtins.listToAttrs (map (n: {{
      name = n;
      value = {{
        real = getSize (customLib.optimize' real.config.games.doom.wads.${{n}});
        mock = getSize mocked.config.games.doom.wads.${{n}};
      }};
    }}) names);""")
    if targets["scummvm"]:
        parts.append(f"""
  scummvm = let names = {names_nix(targets["scummvm"])}; in
    builtins.listToAttrs (map (n: {{
      name = n;
      value = {{
        real = getSize real.config.games.scummvm.games.${{n}}.path;
        mock = getSize mocked.config.games.scummvm.games.${{n}}.path;
      }};
    }}) names);""")
    body = "{\n" + "\n".join(parts) + "\n}"
    result = nix_eval_json(body, max_jobs, cores)
    return {
        "doom": result.get("doom", {}),
        "scummvm": result.get("scummvm", {}),
    }


TOTAL_KEY = ("TOTAL", "")


def load_csv():
    if not CSV_PATH.exists():
        return {}
    with CSV_PATH.open(newline="") as f:
        rows = {(row["category"], row["game"]): row for row in csv.DictReader(f)}
    rows.pop(TOTAL_KEY, None)
    return rows


def save_csv(rows):
    now = datetime.datetime.now().isoformat(timespec="seconds")
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
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("patterns", nargs="*", help="substrings to filter game names (default: all)")
    parser.add_argument("--list", action="store_true", help="list available game names and exit")
    parser.add_argument(
        "--missing",
        action="store_true",
        help="with --list, only show games that have no row in compression-savings.csv yet",
    )
    parser.add_argument("--doom", action="store_true", help="restrict to Doom wads")
    parser.add_argument("--scummvm", action="store_true", help="restrict to ScummVM games")
    parser.add_argument("--max-jobs", type=int, default=6)
    parser.add_argument("--cores", type=int, default=6)
    args = parser.parse_args()

    categories = []
    if args.doom:
        categories.append("doom")
    if args.scummvm:
        categories.append("scummvm")
    if not categories:
        categories = ["doom", "scummvm"]

    names = list_names()

    if args.list or args.missing:
        measured = load_csv() if args.missing else {}
        for category in categories:
            for n in names[category]:
                if not args.missing or (category, n) not in measured:
                    print(f"{category:8} {n}")
        return

    targets = {c: ([n for n in names[c] if matches(n, args.patterns)] if c in categories else []) for c in ("doom", "scummvm")}

    if not targets["doom"] and not targets["scummvm"]:
        sys.exit("No games matched the given patterns.")

    rows = load_csv()
    now = datetime.datetime.now().isoformat(timespec="seconds")

    print("=== building real (compressed) and mock (passthrough) versions ===")
    sizes = measure_all(targets, max_jobs=args.max_jobs, cores=args.cores)

    for category in categories:
        for name in targets[category]:
            real_b = sizes[category][name]["real"]
            mock_b = sizes[category][name]["mock"]
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
