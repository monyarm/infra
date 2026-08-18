{ pkgs, ... }:
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
        import re
        import subprocess
        import sys
        import time
        import urllib.parse
        import urllib.request
        from pathlib import Path

        SOPS = "${pkgs.sops}/bin/sops"

        # Capcom Arcade Stadium and Capcom Arcade 2nd Stadium base apps --
        # each individual arcade title is sold as its own DLC appid under one
        # of these two.
        BASE_APPS = {
            "Capcom Arcade Stadium": 1515950,
            "Capcom Arcade 2nd Stadium": 1755910,
        }


        def get_secret(secrets_file, key):
            out = subprocess.run(
                [SOPS, "-d", secrets_file],
                check=True,
                capture_output=True,
                text=True,
            ).stdout
            return json.loads(out).get(key)


        def local_steamid64():
            loginusers = (
                Path.home() / ".steam" / "steam" / "config" / "loginusers.vdf"
            )
            if not loginusers.exists():
                return None
            m = re.search(r'"(\d{17})"', loginusers.read_text())
            return m.group(1) if m else None


        def owned_appids(api_key, steamid):
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
            with urllib.request.urlopen(url) as resp:
                data = json.loads(resp.read())
            games = data.get("response", {}).get("games", [])
            return {g["appid"]: g.get("name", "") for g in games}


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


        def main():
            ap = argparse.ArgumentParser(
                description=(
                    "Enumerate owned Capcom Arcade Stadium / 2nd Stadium "
                    "per-title DLC against each base app's full DLC list."
                )
            )
            ap.add_argument("--secrets-file", default="secrets/env.json")
            args = ap.parse_args()

            api_key = get_secret(args.secrets_file, "STEAM_API_KEY")
            steamid = local_steamid64()
            if not api_key or not steamid:
                print(
                    "STEAM_API_KEY or local SteamID64 not found.",
                    file=sys.stderr,
                )
                sys.exit(1)

            owned = owned_appids(api_key, steamid)

            for base_name, base_appid in BASE_APPS.items():
                print(f"\n=== {base_name} (base appid {base_appid}) ===")
                base_data = appdetails(base_appid)
                if base_appid in owned:
                    print("  [owned] base app -- includes free bundled title")
                dlc_ids = base_data.get("dlc", [])
                print(f"  {len(dlc_ids)} total DLC titles listed for this base app")
                for dlc_id in dlc_ids:
                    if dlc_id not in owned:
                        continue
                    dlc_data = appdetails(dlc_id)
                    name = dlc_data.get("name") or owned[dlc_id]
                    print(f"  [owned] {dlc_id}  {name}")


        if __name__ == "__main__":
            main()
      '';
in
script
