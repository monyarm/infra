{ pkgs, lib, ... }:
let

  systemToItchPlatform =
    system:
    if builtins.match ".*linux.*" system != null then
      "linux"
    else if builtins.match ".*darwin.*" system != null then
      "osx"
    else if builtins.match ".*windows.*" system != null then
      "windows"
    else
      "linux";

  #   1. GET {url}/data.json                                     -- public,
  #      unauthenticated, gives the numeric game id.
  #   2. GET https://api.itch.io/games/{id}/uploads?api_key=...   -- lists
  #      uploads.
  #   3. GET https://api.itch.io/uploads/{id}/download?api_key=... -- redirects
  #      straight to the real file.
  fetchItchUploadScript = pkgs.writeText "fetch-itch-upload.py" ''
    import fnmatch, json, os, sys, urllib.request

    out_dir, url, platform, file_match = sys.argv[1:5]

    api_key = os.environ["ITCH_API_KEY"]
    headers = {"User-Agent": "nix-fetchItch"}

    def get_json(u):
        req = urllib.request.Request(u, headers=headers)
        with urllib.request.urlopen(req) as r:
            return json.loads(r.read())

    game_id = get_json(url.rstrip("/") + "/data.json")["id"]
    uploads = get_json(f"https://api.itch.io/games/{game_id}/uploads?api_key={api_key}")["uploads"]

    def matches_platform(u):
        if u.get("type") != "default":
            return True
        return f"p_{platform}" in (u.get("traits") or [])

    candidates = [
        u for u in uploads
        if matches_platform(u) and fnmatch.fnmatch(u.get("filename", ""), file_match)
    ]
    if not candidates:
        print(f"No upload matched platform={platform!r} fileMatch={file_match!r}.", file=sys.stderr)
        print("Uploads seen:", file=sys.stderr)
        for u in uploads:
            print(f"  - {u.get('filename')} (type={u.get('type')}, traits={u.get('traits')})", file=sys.stderr)
        sys.exit(1)

    upload = candidates[0]
    dl_url = f"https://api.itch.io/uploads/{upload['id']}/download?api_key={api_key}"
    req = urllib.request.Request(dl_url, headers=headers)
    with urllib.request.urlopen(req) as r:
        data = r.read()

    out_path = os.path.join(out_dir, upload["filename"])
    with open(out_path, "wb") as f:
        f.write(data)
    print(out_path)
  '';
in
{
  fetchItch =
    {
      url,
      hash,
      platform ? systemToItchPlatform pkgs.stdenv.hostPlatform.system,
      fileMatch ? "*", # Allows targeting a specific file string if multiple match the OS
      version ? null,
      ...
    }:

    let
      cleanUrl = lib.removeSuffix "/" url;
      pname = builtins.baseNameOf cleanUrl;
    in
    pkgs.stdenv.mkDerivation (
      {
        outputHashAlgo = "sha256";
        outputHash = hash;
        outputHashMode = "recursive";

        nativeBuildInputs = [
          pkgs.python3
          pkgs.cacert
          pkgs.unzip
          pkgs.gnutar
          pkgs.p7zip
        ];

        dontUnpack = true;
        preferLocalBuild = true;

        buildPhase = ''
          export HOME=$TMPDIR
          source /secrets

          if [ -z "$ITCH_API_KEY" ]; then
            echo "Error: ITCH_API_KEY is not set in the environment."
            echo "itch.io's API requires a key for every operation, even public games."
            echo "Get one at https://itch.io/user/settings/api-keys and run e.g.:"
            exit 1
          fi

          mkdir -p $TMPDIR/download
          DOWNLOADED_FILE=$(python3 ${fetchItchUploadScript} "$TMPDIR/download" "${url}" "${platform}" "${fileMatch}")
        '';

        installPhase = ''
          mkdir -p $out

          echo "Extracting specified target: $DOWNLOADED_FILE"

          case "$DOWNLOADED_FILE" in
            *.zip)
              unzip -q "$DOWNLOADED_FILE" -d $out
              ;;
            *.tar.gz|*.tgz)
              tar -xzf "$DOWNLOADED_FILE" -C $out
              ;;
            *.tar.xz|*.txz)
              tar -xJf "$DOWNLOADED_FILE" -C $out
              ;;
            *.rar|*.7z|*.exe)
              7z x "$DOWNLOADED_FILE" -o$out
              ;;
            *)
              echo "Raw binary, copy target directly to package layout root."
              cp "$DOWNLOADED_FILE" "$out/$(basename "$DOWNLOADED_FILE")"
              ;;
          esac
        '';

      }
      // (if version != null then { inherit version pname; } else { name = pname; })
    );
}
