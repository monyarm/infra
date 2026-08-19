{ pkgs, steamCodeScript, ... }:
let
  script =
    pkgs.writers.writePython3Bin "capcom-arcade-scan"
      {
        flakeIgnore = [
          "E501"
          "W503"
        ];
      }
      ''
        import argparse
        import json
        import os
        import re
        import subprocess
        import sys
        import time
        import urllib.parse
        import urllib.request

        SOPS = "${pkgs.sops}/bin/sops"
        STEAMCMD = "${pkgs.steamcmd-minimal}/bin/steamcmd-minimal"
        STEAM_CODE_SCRIPT = "${steamCodeScript}"
        PYTHON = "${pkgs.python3}/bin/python3"

        # 1st Stadium's ownership is already fully cataloged in
        # capcom-arcade.nix (31 shipped + 7 blocked + confirmed-not-owned) --
        # only 2nd Stadium's DLC list is unknown, so that's all this scans.
        BASE_APPS = {
            "Capcom Arcade 2nd Stadium": 1755910,
        }

        NOT_OWNED_RE = re.compile(r"No active license found for appID (\d+)\.")


        def get_secret(secrets_file, key):
            out = subprocess.run(
                [SOPS, "-d", secrets_file],
                check=True,
                capture_output=True,
                text=True,
            ).stdout
            return json.loads(out).get(key)


        def steam_guard_code(shared_secret):
            env = dict(os.environ)
            env["STEAM_SHARED_SECRET"] = shared_secret
            return subprocess.run(
                [PYTHON, STEAM_CODE_SCRIPT],
                env=env,
                check=True,
                capture_output=True,
                text=True,
            ).stdout.strip()


        # Steam's public store API has no per-key auth and is aggressively
        # rate-limited -- one request per app, throttled, with a couple
        # retries on transient failures.
        def appdetails(appid):
            url = (
                "https://store.steampowered.com/api/appdetails"
                f"?appids={appid}"
            )
            for attempt in range(3):
                try:
                    with urllib.request.urlopen(url) as resp:
                        data = json.loads(resp.read())
                    entry = data.get(str(appid), {})
                    if entry.get("success"):
                        return entry.get("data", {})
                    return {}
                except Exception as e:
                    if attempt == 2:
                        print(
                            f"Warning: appdetails failed for {appid}: {e}",
                            file=sys.stderr,
                        )
                        return {}
                    time.sleep(2)
                finally:
                    time.sleep(1.5)


        # GetOwnedGames (the public per-key Steam Web API) only ever returns
        # appids of type "game" -- it silently omits DLC-type appids no
        # matter what's actually owned, so it can't answer per-title
        # ownership for these base apps. licenses_for_app is an authenticated
        # steamcmd console command backed by the account's real license/
        # package data, so it's the only reliable source for this. One
        # steamcmd session (one login, one 2FA prompt) batches every
        # candidate id plus an app_info_print per base app, which also
        # yields each owned depot's current manifest gid for free.
        def steamcmd_query(username, password, code, candidate_ids, base_app_ids):
            cmds = ["+login", username, password, code]
            for cid in candidate_ids:
                cmds += ["+licenses_for_app", str(cid)]
            for bid in base_app_ids:
                cmds += ["+app_info_print", str(bid)]
            cmds += ["+quit"]
            print(f"Querying steamcmd: {len(candidate_ids)} candidate ids...", flush=True)
            proc = subprocess.Popen(
                [STEAMCMD] + cmds,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
            )
            lines = []
            for line in proc.stdout:
                lines.append(line)
                if "License packageID" in line or "No active license" in line or "AppID :" in line:
                    print(line.rstrip(), flush=True)
            proc.wait(timeout=900)
            return "".join(lines)


        def extract_not_owned(output):
            return {int(m) for m in NOT_OWNED_RE.findall(output)}


        # app_info_print's KeyValues output has no fixed field order, so
        # instead of a brittle single regex this walks brace depth to pull
        # out exactly the "<depotid> { ... }" block, then looks for
        # manifests.public.gid inside it.
        def depot_block(section, depot_id):
            marker = f'"{depot_id}"'
            pos = 0
            while True:
                idx = section.find(marker, pos)
                if idx == -1:
                    return None
                j = idx + len(marker)
                while j < len(section) and section[j].isspace():
                    j += 1
                if j < len(section) and section[j] == "{":
                    depth = 0
                    i = j
                    while i < len(section):
                        if section[i] == "{":
                            depth += 1
                        elif section[i] == "}":
                            depth -= 1
                            if depth == 0:
                                return section[j:i + 1]
                        i += 1
                    return None
                pos = idx + 1


        def manifest_gid(block):
            if not block:
                return None
            m = re.search(r'"public"\s*\{\s*"gid"\s*"(\d+)"', block)
            return m.group(1) if m else None


        def base_app_section(output, base_appid):
            marker = f"AppID : {base_appid},"
            start = output.find(marker)
            if start == -1:
                return ""
            nxt = output.find("AppID : ", start + len(marker))
            return output[start:nxt if nxt != -1 else len(output)]


        def main():
            ap = argparse.ArgumentParser(
                description=(
                    "Enumerate owned Capcom Arcade Stadium / 2nd Stadium "
                    "per-title DLC (+ manifest gids) against each base "
                    "app's full DLC list."
                )
            )
            ap.add_argument("--secrets-file", default="secrets/env.json")
            args = ap.parse_args()

            username = get_secret(args.secrets_file, "STEAM_USERNAME")
            password = get_secret(args.secrets_file, "STEAM_PASSWORD")
            shared_secret = get_secret(args.secrets_file, "STEAM_SHARED_SECRET")
            if not username or not password or not shared_secret:
                print(
                    "STEAM_USERNAME/STEAM_PASSWORD/STEAM_SHARED_SECRET not found.",
                    file=sys.stderr,
                )
                sys.exit(1)
            code = steam_guard_code(shared_secret)

            base_dlc = {}
            candidate_ids = []
            for base_name, base_appid in BASE_APPS.items():
                data = appdetails(base_appid)
                ids = data.get("dlc", [])
                base_dlc[base_name] = (base_appid, ids)
                candidate_ids.extend(ids)

            output = steamcmd_query(
                username, password, code, candidate_ids, BASE_APPS.values()
            )
            not_owned = extract_not_owned(output)

            for base_name, (base_appid, ids) in base_dlc.items():
                print(f"\n=== {base_name} (base appid {base_appid}) ===")
                section = base_app_section(output, base_appid)
                print(f"  {len(ids)} total DLC titles listed for this base app")
                for did in ids:
                    if did in not_owned:
                        continue
                    dd = appdetails(did)
                    name = dd.get("name", "")
                    gid = manifest_gid(depot_block(section, did))
                    print(f"  [owned] {did}  manifest={gid}  {name}")


        if __name__ == "__main__":
            main()
      '';
in
script
