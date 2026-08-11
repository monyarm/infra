{
  pkgs,
  lib,
  fetchToolOutput,
  extractArchiveSnippet,
  ...
}:
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

    # Filename substrings (case-insensitive) that mean "not the actual
    # game," regardless of how the developer tagged it -- platform traits
    # are often set carelessly (e.g. every upload checked "Windows"
    # including a press kit).
    upload_blacklist = ["presskit", "press kit"]

    def is_blacklisted(u):
        name = (u.get("filename") or "").lower()
        return any(term in name for term in upload_blacklist)

    platform_traits = {"p_windows", "p_linux", "p_osx"}

    def is_tagged_for_platform(u):
        traits = u.get("traits") or []
        return u.get("type") == "default" and f"p_{platform}" in traits

    def matches_platform_loose(u):
        if u.get("type") != "default":
            return True
        traits = u.get("traits") or []
        # An upload with no OS trait at all isn't platform-restricted (itch
        # just didn't tag it), so treat it as matching every platform rather
        # than excluding it outright.
        if not platform_traits.intersection(traits):
            return True
        return f"p_{platform}" in traits

    named = [
        u for u in uploads
        if fnmatch.fnmatch(u.get("filename", ""), file_match) and not is_blacklisted(u)
    ]
    # Prefer an upload actually tagged for this platform over the loose
    # "untagged, so it matches everything" fallback -- otherwise an
    # unrelated untagged upload (e.g. a press kit) can outrank the real
    # build just by sorting first.
    candidates = [u for u in named if is_tagged_for_platform(u)] or [
        u for u in named if matches_platform_loose(u)
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
      # update-sources.py's own staleness fingerprint -- a "|"-joined
      # id:md5:timestamp triple *per upload on the game's page* (not just the
      # one actually selected/fetched below), so it catches changes to
      # uploads this platform doesn't even use. Recorded in sources.nix for
      # that script's own before/after comparison; irrelevant here; fixed-
      # output derivations are already keyed by `hash`, not `name`, so
      # folding it into `name` bought nothing and could run past Nix's
      # 211-char derivation-name limit for games with several uploads.
      version ? null,
      # sources.nix's recorded archive member list, when this source is a
      # pk3/archive -- attached as passthru so optimize/optimize' can
      # transparently extract/optimize/repack it without a caller needing
      # to pass this same sourceEntry again explicitly.
      archiveContent ? null,
      ...
    }:

    let
      cleanUrl = lib.removeSuffix "/" url;
      name = builtins.baseNameOf cleanUrl;
    in
    fetchToolOutput {
      inherit name;
      outputHash = hash;
      outputHashMode = "recursive";
      nativeBuildInputs = [
        pkgs.python3
        pkgs.cacert
      ];
      useSecrets = true;
      extraAttrs.passthru.archiveContent = archiveContent;
      script = ''
        export HOME=$TMPDIR

        if [ -z "''${ITCH_API_KEY:-}" ]; then
          echo "Error: ITCH_API_KEY is not set in the environment."
          echo "itch.io's API requires a key for every operation, even public games."
          echo "Get one at https://itch.io/user/settings/api-keys and run e.g.:"
          exit 1
        fi

        mkdir -p $TMPDIR/download
        DOWNLOADED_FILE=$(python3 ${fetchItchUploadScript} "$TMPDIR/download" "${url}" "${platform}" "${fileMatch}")

        mkdir -p "$out"
        ${extractArchiveSnippet {
          file = "$DOWNLOADED_FILE";
          outDir = "$out";
        }}
      '';
    };
}
