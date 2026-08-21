{ pkgs, ... }:
let
  script =
    pkgs.writers.writePython3Bin "game-library-scan"
      {
        libraries = [ pkgs.python3Packages.tomli-w ];
        flakeIgnore = [
          "E501"
          "W503"
        ];
      }
      ''
        import argparse
        import difflib
        import json
        import os
        import re
        import subprocess
        import sys
        import tempfile
        import urllib.parse
        import urllib.request
        from pathlib import Path

        import tomli_w

        SOPS = "${pkgs.sops}/bin/sops"
        LGOGDOWNLOADER = "${pkgs.lgogdownloader}/bin/lgogdownloader"
        LEGENDARY = "${pkgs.legendary-gl}/bin/legendary"
        SCUMMVM = "${pkgs.scummvm}/bin/scummvm"
        MAXIMA_CLI = "${pkgs.maxima-cli}/bin/maxima-cli"

        # Stripped before fuzzy-matching so editions/remasters/trademark cruft
        # (e.g. "Beneath a Steel Sky (GOG Deluxe Edition)") don't tank the ratio
        # against ScummVM's terser titles (e.g. "Beneath a Steel Sky").
        NOISE_RE = re.compile(
            r"[™®©:]"
            r"|\((?:gog|steam|deluxe|goty|remaster\w*|special|"
            r"anniversary|definitive|enhanced|complete|hd)[^)]*\)"
            r"|\b(?:remastered|deluxe edition|special edition|"
            r"definitive edition|goty edition|complete edition)\b",
            re.IGNORECASE,
        )


        def normalize(title):
            cleaned = NOISE_RE.sub("", title)
            cleaned = re.sub(r"[^\w\s]", " ", cleaned)
            return re.sub(r"\s+", " ", cleaned).strip().lower()


        # Below this length a "substring" match is meaningless noise (nearly
        # every title contains some single-letter ScummVM game like "glk:o").
        MIN_CONTAINMENT_LEN = 6


        # A ScummVM library with thousands of titles makes a naive O(owned x
        # scummvm) full ratio() comparison far too slow (each SequenceMatcher
        # comparison rebuilds its internal index from scratch). Instead: block
        # candidates by shared significant words (like a cheap inverted index),
        # then only run the real fuzzy comparison -- reusing one SequenceMatcher
        # with set_seq2 fixed, as difflib.get_close_matches itself does -- on
        # that small candidate set.
        def significant_words(norm):
            return [w for w in norm.split() if len(w) >= MIN_CONTAINMENT_LEN]


        def build_index(games):
            entries = []
            word_index = {}
            for gid, name in games:
                norm_name = normalize(name)
                if not norm_name:
                    continue
                i = len(entries)
                entries.append((gid, name, norm_name))
                for w in significant_words(norm_name):
                    word_index.setdefault(w, set()).add(i)
            return entries, word_index


        def fuzzy_matches(title, index, threshold):
            entries, word_index = index
            norm_title = normalize(title)
            if not norm_title:
                return []

            candidate_idx = set()
            for w in significant_words(norm_title):
                candidate_idx |= word_index.get(w, set())
            if not candidate_idx:
                return []

            matcher = difflib.SequenceMatcher()
            matcher.set_seq2(norm_title)
            scored = []
            for i in candidate_idx:
                gid, name, norm_name = entries[i]
                matcher.set_seq1(norm_name)
                if matcher.real_quick_ratio() < threshold:
                    continue
                if matcher.quick_ratio() < threshold:
                    continue
                ratio = matcher.ratio()
                if norm_name in norm_title or norm_title in norm_name:
                    ratio = max(ratio, 0.85)
                if ratio >= threshold:
                    scored.append((ratio, gid, name))
            scored.sort(reverse=True)
            return scored[:3]


        def get_secret(secrets_file, key):
            out = subprocess.run(
                [SOPS, "-d", secrets_file],
                check=True,
                capture_output=True,
                text=True,
            ).stdout
            return json.loads(out).get(key)


        def gog_titles(secrets_file):
            auth = get_secret(secrets_file, "GOG_AUTH")
            if not auth:
                print(
                    "Warning: GOG_AUTH not found in secrets, skipping GOG.",
                    file=sys.stderr,
                )
                return []
            with tempfile.TemporaryDirectory() as home:
                cfg = Path(home) / ".config" / "lgogdownloader"
                cfg.mkdir(parents=True)
                (cfg / "cookies.txt").write_text(auth["cookies"])
                (cfg / "galaxy_tokens.json").write_text(
                    json.dumps(auth["galaxy_tokens"])
                )
                env = {**os.environ, "HOME": home}
                res = subprocess.run(
                    [LGOGDOWNLOADER, "--list=json"],
                    env=env,
                    capture_output=True,
                    text=True,
                )
                try:
                    data = json.loads(res.stdout)
                except json.JSONDecodeError:
                    print(
                        "Warning: failed to parse GOG library listing.",
                        file=sys.stderr,
                    )
                    return []
                return [(g.get("gamename"), g["title"]) for g in data]


        def epic_titles(secrets_file):
            raw = get_secret(secrets_file, "EPIC_LEGENDARY_AUTH")
            if not raw:
                print(
                    "Warning: EPIC_LEGENDARY_AUTH not found in secrets, "
                    "skipping Epic.",
                    file=sys.stderr,
                )
                return []
            with tempfile.TemporaryDirectory() as home:
                cfg = Path(home) / ".config" / "legendary"
                cfg.mkdir(parents=True)
                text = raw if isinstance(raw, str) else json.dumps(raw)
                (cfg / "user.json").write_text(text)
                env = {**os.environ, "HOME": home}
                res = subprocess.run(
                    [LEGENDARY, "list", "--json"],
                    env=env,
                    capture_output=True,
                    text=True,
                )
                try:
                    data = json.loads(res.stdout)
                except json.JSONDecodeError:
                    print(
                        "Warning: failed to parse Epic library listing.",
                        file=sys.stderr,
                    )
                    return []
                return [(g.get("app_name"), g["app_title"]) for g in data]


        # maxima-cli logs every line through a custom log::Log impl (see
        # maxima-lib/src/util/log.rs) that ANSI-colorizes and prefixes every
        # message with "LEVEL - [module::path] - " before the actual text --
        # confirmed against source at the pinned commit, not assumed. Strip
        # both before matching the list_games format string itself:
        # "{slug:<35} - {name:<35} - {offer_id:<25} - Installed: {bool}".
        MAXIMA_ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")
        MAXIMA_LOG_PREFIX_RE = re.compile(r"^\S+ - \[[^\]]+\] - ", re.MULTILINE)
        # Rust's `:<N` pads only when content is shorter than N -- long
        # titles/slugs get no padding, so field boundaries can't be told
        # apart by counting spaces. Slugs/offer IDs never contain " - ", so
        # anchor slug at the start and offer_id+Installed at the end; greedy
        # `.+` for name then finds the true rightmost separator even when
        # the title itself contains " - " (e.g. "S.T.A.L.K.E.R. - Shadow of
        # Chernobyl").
        MAXIMA_GAME_LINE_RE = re.compile(
            r"^\S+\s+-\s+(.+)\s+-\s+(\S+)\s*-\s*Installed:\s*\w+\s*$",
            re.MULTILINE,
        )


        def maxima_titles(secrets_file):
            auth = get_secret(secrets_file, "MAXIMA_AUTH")
            if not auth:
                print(
                    "Warning: MAXIMA_AUTH not found in secrets, skipping Maxima.",
                    file=sys.stderr,
                )
                return []
            with tempfile.TemporaryDirectory() as home:
                maxima_dir = Path(home) / ".local" / "share" / "maxima"
                maxima_dir.mkdir(parents=True)
                with open(maxima_dir / "auth.toml", "wb") as f:
                    tomli_w.dump(auth, f)
                env = {**os.environ, "HOME": home}
                res = subprocess.run(
                    [MAXIMA_CLI, "list-games"],
                    env=env,
                    capture_output=True,
                    text=True,
                )
                clean = MAXIMA_LOG_PREFIX_RE.sub(
                    "", MAXIMA_ANSI_RE.sub("", res.stdout)
                )
                return [
                    (m.group(2).strip(), m.group(1).strip())
                    for m in MAXIMA_GAME_LINE_RE.finditer(clean)
                ]


        def steam_installed_titles():
            steamapps = Path.home() / ".steam" / "steam" / "steamapps"
            vdf = steamapps / "libraryfolders.vdf"
            if not vdf.exists():
                return []
            paths = re.findall(r'"path"\s*"([^"]+)"', vdf.read_text())
            games = []
            for p in paths:
                acf_dir = Path(p) / "steamapps"
                for acf in acf_dir.glob("appmanifest_*.acf"):
                    text = acf.read_text(errors="ignore")
                    m = re.search(r'"name"\s*"([^"]+)"', text)
                    if not m:
                        continue
                    appid_m = re.match(r"appmanifest_(\d+)\.acf", acf.name)
                    appid = appid_m.group(1) if appid_m else None
                    games.append((appid, m.group(1)))
            return games


        def local_steamid64():
            loginusers = (
                Path.home() / ".steam" / "steam" / "config" / "loginusers.vdf"
            )
            if not loginusers.exists():
                return None
            m = re.search(r'"(\d{17})"', loginusers.read_text())
            return m.group(1) if m else None


        def steam_titles(secrets_file):
            # The full owned library (not just what's installed here) needs the
            # Steam Web API, since it isn't available locally the way installed
            # games' appmanifest_*.acf files are.
            api_key = get_secret(secrets_file, "STEAM_API_KEY")
            steamid = local_steamid64()
            if not api_key or not steamid:
                print(
                    "Warning: STEAM_API_KEY or local SteamID64 not found, "
                    "falling back to locally installed Steam games only.",
                    file=sys.stderr,
                )
                return steam_installed_titles()

            params = urllib.parse.urlencode(
                {
                    "key": api_key,
                    "steamid": steamid,
                    "format": "json",
                    "include_appinfo": 1,
                    "include_played_free_games": 1,
                }
            )
            url = (
                "https://api.steampowered.com/IPlayerService/"
                f"GetOwnedGames/v1/?{params}"
            )
            try:
                with urllib.request.urlopen(url) as resp:
                    data = json.loads(resp.read())
            except Exception as e:
                print(
                    f"Warning: Steam Web API request failed ({e}); "
                    "falling back to locally installed Steam games only.",
                    file=sys.stderr,
                )
                return steam_installed_titles()

            games = data.get("response", {}).get("games", [])
            return [(g["appid"], g["name"]) for g in games if "name" in g]


        def scummvm_games():
            res = subprocess.run(
                [SCUMMVM, "--list-games"], capture_output=True, text=True
            )
            games = []
            for line in res.stdout.splitlines():
                line = line.strip()
                if (
                    not line
                    or set(line) <= {"-"}
                    or line.lower().startswith("game id")
                ):
                    continue
                parts = line.split(None, 1)
                if len(parts) == 2:
                    games.append((parts[0], parts[1].strip()))
            return games


        # Maps each provider to the already-defined.json field holding this
        # repo's own ids for that source, so ownership can be excluded by id
        # instead of fuzzy title matching.
        PROVIDER_ID_KEYS = {
            "GOG": "gogIds",
            "Epic": "epicIds",
            "Steam": "steamAppIds",
            "Maxima": "maximaSlugs",
        }


        def already_defined():
            path = (
                Path.home()
                / ".local"
                / "share"
                / "game-library-scan"
                / "already-defined.json"
            )
            if not path.exists():
                print(
                    f"Warning: {path} not found (run `home-manager switch` "
                    "first); treating this repo's existing library as empty.",
                    file=sys.stderr,
                )
                return {key: [] for key in PROVIDER_ID_KEYS.values()}
            return json.loads(path.read_text())


        def excluded_ids(defined):
            return {
                provider: {str(x) for x in defined.get(key, [])}
                for provider, key in PROVIDER_ID_KEYS.items()
            }


        def split_owned(entries, seen_ids):
            visible, hidden = [], 0
            for gid, title in entries:
                if gid is not None and str(gid) in seen_ids:
                    hidden += 1
                else:
                    visible.append((gid, title))
            return visible, hidden


        def list_mode(sources, defined):
            already = excluded_ids(defined)
            visible = {}
            hidden_counts = {}
            for provider, entries in sources.items():
                visible[provider], hidden_counts[provider] = split_owned(
                    entries, already.get(provider, set())
                )

            title_providers = {}
            for provider, entries in visible.items():
                for gid, title in entries:
                    title_providers.setdefault(title, []).append((provider, gid))
            multi = {t: v for t, v in title_providers.items() if len({p for p, _ in v}) > 1}

            for provider in sorted(visible):
                entries = sorted(
                    (gid, title) for gid, title in visible[provider] if title not in multi
                )
                hidden = hidden_counts[provider]
                hidden_note = f", {hidden} already owned" if hidden else ""
                print(f"\n=== {provider} ({len(entries)}{hidden_note}) ===")
                for gid, title in entries:
                    id_note = f"  [{gid}]" if gid is not None else ""
                    print(f"  {title}{id_note}")

            print(f"\n=== Multi-Provider ({len(multi)}) ===")
            for title in sorted(multi):
                providers = ", ".join(f"{p} [{gid}]" for p, gid in sorted(multi[title]))
                print(f"  {title}  ({providers})")


        def scummvm_mode(sources, defined, threshold):
            already = excluded_ids(defined)
            index = build_index(scummvm_games())

            for provider in sorted(sources):
                visible, _ = split_owned(sources[provider], already.get(provider, set()))
                print(f"\n=== {provider} ({len(visible)} owned) ===")
                for gid, title in sorted(set(visible), key=lambda x: x[1]):
                    matches = fuzzy_matches(title, index, threshold)
                    if matches:
                        shown = ", ".join(
                            f"{name} [{sgid}] ({ratio:.2f})"
                            for ratio, sgid, name in matches
                        )
                        print(f"  {title}  ->  {shown}")


        def main():
            ap = argparse.ArgumentParser(
                description=(
                    "List owned GOG/Steam/Epic/Maxima games not yet defined "
                    "in this repo's config, or match them against "
                    "ScummVM-supported titles."
                )
            )
            ap.add_argument("--secrets-file", default="secrets/env.json")
            ap.add_argument("--threshold", type=float, default=0.7)
            ap.add_argument(
                "--scummvm",
                action="store_true",
                help="Fuzzy-match owned titles against ScummVM's supported "
                "games instead of just listing them.",
            )
            args = ap.parse_args()

            sources = {
                "GOG": gog_titles(args.secrets_file),
                "Epic": epic_titles(args.secrets_file),
                "Steam": steam_titles(args.secrets_file),
                "Maxima": maxima_titles(args.secrets_file),
            }
            defined = already_defined()

            if args.scummvm:
                scummvm_mode(sources, defined, args.threshold)
            else:
                list_mode(sources, defined)


        if __name__ == "__main__":
            main()
      '';
in
script
