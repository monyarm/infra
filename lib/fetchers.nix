{
  pkgs,
  dirs,
  importSopsString,
  urlEncode,
  splitFiles,
  ...
}:
let
  inherit (pkgs) lib;

  userAgent = "Mozilla/5.0 (X11; Linux x86_64; rv:144.0) Gecko/20100101 Firefox/144.0";
  getFileNameFromUrl =
    url:
    let
      # Try to get query parameter (e.g., ?v=sFVJVWVDIMg)
      queryMatch = builtins.match ".*[?&]v=([^&]+).*" url;
      # Try to get last path segment (e.g., /video.mp4)
      pathMatch = builtins.match ".*/([^/]+)$" url;
    in
    if queryMatch != null then
      builtins.head queryMatch
    else if pathMatch != null then
      builtins.head pathMatch
    else
      "video";
in
rec {

  fetchzipNoSubt =
    args:
    (pkgs.fetchzip args).overrideAttrs (_oldAttrs: {
      allowSubstitutes = false;
    });

  fetchzipSelective =
    {
      keepFiles,
      flatten ? false,
      ...
    }@args:
    let
      # 1. Strip our custom arguments so fetchzip doesn't complain about unexpected inputs
      fetchzipArgs = removeAttrs args [
        "keepFiles"
        "flatten"
      ];

      # 2. Define our custom post-processing shell script
      selectivePostFetch = ''
        STAGING=$(mktemp -d)

        # Extract specified files/dirs to staging safely
        ${pkgs.lib.concatMapStringsSep "\n" (file: ''
          if [ -e "$out/${file}" ]; then
            mkdir -p "$STAGING/$(dirname "${file}")"
            cp -r "$out/${file}" "$STAGING/${file}"
          else
            echo "Warning: keepFiles entry '${file}' was not found in the fetched archive!"
          fi
        '') keepFiles}

        # Clear target directory completely
        rm -rf $out/*

        if [ "${pkgs.lib.boolToString flatten}" = "true" ]; then
          # Deep Flatten: Find every file/symlink and copy to the root of $out/
          find "$STAGING" -type f -o -type l | while IFS= read -r file; do
            # Optional: warn on collisions
            filename=$(basename "$file")
            if [ -e "$out/$filename" ]; then
              echo "Warning: Flattening collision! Overwriting $out/$filename with $file"
            fi
            cp -dp "$file" "$out/"
          done
        else
          # Preserve exact relative structures
          cp -pr "$STAGING"/. "$out/"
        fi

        rm -rf "$STAGING"
      '';
    in
    # 3. Use overrideAttrs to APPEND our script to whatever postFetch fetchzip already runs
    (fetchzipNoSubt fetchzipArgs).overrideAttrs (oldAttrs: {
      postFetch = (oldAttrs.postFetch or "") + "\n" + selectivePostFetch;
      stripRoot = false;
    });
  fetchChaosium =
    {
      game,
      name,
      hash ? "",
    }:
    pkgs.fetchurl {
      url = "https://www.chaosium.com/content/Backgrounds/${urlEncode game}%20Background%20-%20${urlEncode name}.jpg";
      inherit hash;
    };
  fetchProtonGE =
    version: hash:
    let
      name = "GE-Proton${version}";
    in
    fetchzipNoSubt {
      inherit name hash;
      url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${name}/${name}.tar.gz";
    };

  fetchVideo =
    {
      url,
      sha256,
      name ? getFileNameFromUrl url,
      audio ? false,
    }:
    pkgs.runCommand name
      {
        outputHashMode = "flat";
        outputHashAlgo = "sha256";
        outputHash = sha256;
        nativeBuildInputs = [ pkgs.yt-dlp ];
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      }
      ''
        ;
                yt-dlp \
                  ${if audio then "-f bestvideo+bestaudio" else "-f bestvideo"} \
                  --no-playlist \
                  --no-write-subs \
                  --no-write-auto-subs \
                  --no-write-info-json \
                  --no-write-comments \
                  --user-agent "${userAgent}" \
                  -o "$out" \
                  "${url}"
      '';

  fetchSteamStoreAsset =
    {
      appid,
      assetid,
      sha256,
      extension ? "jpg",
      name ? "${toString appid}-${assetid}.${extension}",
    }:
    pkgs.fetchurl {
      inherit name sha256;
      url = "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/${toString appid}/${assetid}.${extension}";
    };

  fetchWithReferrer =
    referrer:
    {
      url,
      sha256 ? null,
      hash ? sha256,
    }:
    pkgs.fetchurl {
      inherit hash url;
      curlOptsList = [
        "--header"
        "Referer: ${referrer}"
        "--user-agent"
        userAgent
      ];
    };

  fetchPixiv = fetchWithReferrer "https://www.pixiv.net/";
  fetchGelbooru =
    args:
    fetchWithReferrer "https://gelbooru.com/" (
      args
      // {
        url = builtins.replaceStrings [
          "https://img.gelbooru.com/"
          "https://img1.gelbooru.com/"
          "https://img2.gelbooru.com/"
          "https://img3.gelbooru.com/"
        ] (lib.lists.replicate 4 "https://img4.gelbooru.com/") args.url;
      }
    );

  fetchMyNintendo =
    {
      url,
      sha256,
      name ? null,
      cookie ? (importSopsString "${dirs.secrets}/mynintendo.cookie"),
    }:
    let
      outName =
        if name == null then
          (builtins.replaceStrings [ "/" ":" ] [ "-" "-" ] (getFileNameFromUrl url))
        else
          name;
    in
    pkgs.runCommand outName
      {
        outputHashMode = "recursive";
        outputHashAlgo = "sha256";
        allowSubstitutes = false;
        outputHash = sha256;
        buildInputs = [ pkgs.curl ];
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      }
      ''
        ;
                set -e
                mkdir $out

                FINAL_URL=$(curl -s -L -o /dev/null -w '%{url_effective}' \
                  --user-agent "${userAgent}" \
                  --cookie "${cookie}" \
                  "${url}")

                CLEAN_NAME=$(basename "''${FINAL_URL%%\?*}")

                sleep 2

                curl -A "${userAgent}" --cookie "${cookie}" -o "$out/$CLEAN_NAME" -L "''${FINAL_URL}"
      '';

  # fetchSteamCards:
  #   Fetches Steam trading card images for a given app ID.
  #   Returns a derivation containing all the card images as .jpg files.

  #   Type: fetchSteamCards -> { appId, cardNames ? [], hash } -> Derivation
  #   Fetches Steam trading card images for a given app ID.
  #   cardNames: list of card names to fetch (empty list = fetch all cards)
  #   Returns a derivation containing the card images.
  #   Cards are downloaded in a single fixed-output derivation.
  #   Excludes foil cards and booster packs.
  fetchSteamCards =
    {
      appId,
      cardNames ? [ ],
      sha256 ? null,
      hash ? sha256,
    }:
    let
      # Parse the HTML to extract card information
      parseScript = pkgs.writeText "parse-steam-cards.py" ''
        import re
        import json
        import sys
        from html.parser import HTMLParser

        class SteamCardParser(HTMLParser):
            def __init__(self):
                super().__init__()
                self.cards = {}
                self.game_not_found = False
                self.in_title = False
                self.in_trading_cards_section = False
                self.in_foil_section = False
                self.current_card_name = None
                self.current_img_src = None
                self.depth = 0

            def handle_starttag(self, tag, attrs):
                attrs_dict = dict(attrs)
                if tag == 'title':
                    self.in_title = True
                    return
                # Detect section headers
                if tag == 'span':
                    text_content = attrs_dict.get('class', "")
                    # We'll track section transitions when we see the anchor tags

                if tag == 'a':
                    href = attrs_dict.get('href', "")
                    classes = attrs_dict.get('class', "")

                    # Detect start of Trading Cards section
                    if href == '#series-1-cards':
                        self.in_trading_cards_section = True
                        self.in_foil_section = False

                    # Detect start of Foil Trading Cards section (end regular cards)
                    elif href == '#series-1-foilcards':
                        self.in_trading_cards_section = False
                        self.in_foil_section = True

                    # Detect start of Booster Pack section (end foil cards)
                    elif href == '#series-1-booster':
                        self.in_foil_section = False

                    # Extract card image URLs from gallery-src links
                    # These are the full-resolution card images
                    elif self.in_trading_cards_section and 'gallery-src' in classes:
                        href = attrs_dict.get('href', "")
                        # FIX: Accept both akamai and cloudflare domains by looking at the common path
                        if '/steamcommunity/public/images/items/' in href:
                            # Store URL temporarily, wait for card name in next div
                            self.current_img_src = href

                # Extract card name from the text div
                if tag == 'div' and self.in_trading_cards_section and self.current_img_src:
                  classes = attrs_dict.get('class', "").split()
                  # FIX: Safer class checking
                  if 'text-sm' in classes and 'text-center' in classes and 'break-words' in classes:
                      # We're in the div that contains the card name
                      self.depth = 1

            def handle_data(self, data):
                if self.in_title:
                    if "Game not found!" in data:
                        self.game_not_found = True
                        return
                # Capture card name when we're in the right div
                if self.depth > 0 and self.current_img_src:
                    card_name = data.strip()
                    if card_name:
                        # Make it a valid Nix attribute name
                        # Convert to camelCase and strip special characters
                        # Only keep alphanumeric characters in each word
                        words = re.split(r'[^a-zA-Z0-9]+', card_name)
                        words = [re.sub(r'[^a-zA-Z0-9]', "", w) for w in words if w]
                        if words:
                            nix_name = words[0].lower() + "".join(w.capitalize() for w in words[1:])
                            # Ensure it doesn't start with a number
                            if nix_name and nix_name[0].isdigit():
                                nix_name = 'card' + nix_name.capitalize()
                            if nix_name:
                                self.cards[nix_name] = self.current_img_src

                        self.current_img_src = None
                        self.depth = 0

            def handle_endtag(self, tag):
                if tag == 'title':
                    self.in_title = False
                    return
                if self.depth > 0:
                    if tag == 'div':
                        self.depth = 0
                        if not self.current_card_name:
                            self.current_img_src = None

        html = sys.stdin.read()
        parser = SteamCardParser()
        parser.feed(html)
        print(json.dumps(parser.cards, indent=2))
      '';

      baseDrv =
        pkgs.runCommand ("steam-cards-" + toString appId + (if cardNames == [ ] then "" else "-subset"))
          {
            outputHashMode = "recursive";
            outputHashAlgo = "sha256";
            allowSubstitutes = false;
            outputHash = if sha256 != null then sha256 else hash;
            buildInputs = [
              pkgs.curl
              pkgs.python3
              pkgs.jq
            ];
            SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          }
          ''
            set -e

            # Fetch HTML and parse it to get card info
            CARD_INFO=$(curl -s "https://www.steamcardexchange.net/index.php?gamepage-appid-${toString appId}" | \
                        python3 ${parseScript})

            ${
              if cardNames == [ ] then
                ''
                  # Use all cards
                  FILTERED_CARDS="$CARD_INFO"
                ''
              else
                ''
                  # Filter to requested cards
                  FILTERED_CARDS=$(echo "$CARD_INFO" | jq 'with_entries(select(.key as $k | $k | IN(${builtins.toJSON cardNames}[])))')
                ''
            }
            # Download each card and always name files by the card name (with .jpg)
            mkdir -p $out
            echo "$FILTERED_CARDS" | jq -r 'to_entries[] | "\(.key) \(.value)"' | while read -r name url; do
              echo "Downloading $name..."
              # Always save as <cardName>.jpg so callers can reliably split by name
              safeName="$name.jpg"
              curl -L -o "$out/$safeName" "$url"
            done
          '';

      # Now determine list of files to split. If caller supplied cardNames, use
      # those; otherwise list every file in the derived output.
      fileList =
        if cardNames == [ ] then
          builtins.attrNames (builtins.readDir baseDrv.outPath)
        else
          map (n: "${n}.jpg") cardNames;
    in
    splitFiles fileList baseDrv;
}
