{
  pkgs,
  lib,
  splitFiles,
  fetchzipNoSubst,
  fetchToolOutput,
  fetchHtmlThenCurl,
  downloadNamedUrls,
  userAgent,
  ...
}:
rec {
  fetchProtonGE =
    version: hash:
    let
      name = "GE-Proton${version}";
    in
    fetchzipNoSubst {
      inherit name hash;
      url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${name}/${name}.tar.gz";
    };

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

  fetchSteamCards =
    {
      appId,
      cardNames ? [ ],
      sha256,
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
            outputHash = sha256;
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

  steamCodeScript = pkgs.writeText "steam_code.py" ''
    import base64
    import hmac
    import os
    import struct
    import time

    def generate_steam_code(shared_secret_b64, timestamp=None):
        secret = base64.b64decode(shared_secret_b64)
        if timestamp is None:
            timestamp = int(time.time())

        time_buffer = struct.pack(">Q", timestamp // 30)
        hmac_hash = hmac.new(secret, time_buffer, "sha1").digest()

        start = hmac_hash[19] & 0x0F
        four_bytes = struct.unpack(">I", hmac_hash[start:start + 4])[0] & 0x7FFFFFFF

        alphabet = "23456789BCDFGHJKMNPQRTVWXY"
        code = []
        for _ in range(5):
            code.append(alphabet[four_bytes % len(alphabet)])
            four_bytes //= len(alphabet)

        return "".join(code)

    if __name__ == "__main__":
        secret = os.environ.get("STEAM_SHARED_SECRET")
        if not secret:
            raise ValueError("STEAM_SHARED_SECRET environment variable is missing")
        print(generate_steam_code(secret))
  '';

  fetchSteam =
    {
      appId,
      depotId ? null,
      manifestId ? null,
      pubfileId ? null,
      ugcId ? null,
      sha256,
      filelist ? null,
      os ? "linux",
      osarch ? null,
      language ? null,
    }@args:
    fetchToolOutput {
      name = "steam-${toString (args.depotId or args.pubfileId or args.ugcId or "ERROR")}-dl";
      outputHash = sha256;
      outputHashMode = "recursive";
      nativeBuildInputs = [
        pkgs.depotdownloader
        pkgs.python3
      ];
      useSecrets = true;
      extraAttrs = {
        inherit os osarch language;
        APP_ID = toString appId;
        DEPOT_ID = toString depotId;
        MANIFEST_ID = toString manifestId;
        PUBFILE_ID = toString pubfileId;
        UGC_ID = toString ugcId;
        inherit filelist;
        passAsFile = [ "filelist" ];
      };
      script = ''
        export HOME=$TMPDIR/HOME

        FILELIST_ARG=""
        if [ -n "$filelistPath" ]; then
          FILELIST_ARG="-filelist $filelistPath"
        fi

        if [ -n "$DEPOT_ID" ] && [ -n "$MANIFEST_ID" ]; then
          ARGS="-depot $DEPOT_ID -manifest $MANIFEST_ID"
        elif [ -n "$PUBFILE_ID" ]; then
          ARGS="-pubfile $PUBFILE_ID"
        else
          ARGS="-ugc $UGC_ID"
        fi

        if [ -n "$os" ]; then
          ARGS="$ARGS -os $os"
        fi
        if [ -n "$osarch" ]; then
          ARGS="$ARGS -osarch $osarch"
        fi
        if [ -n "$language" ]; then
          ARGS="$ARGS -language $language"
        fi

        DepotDownloader \
          -username "$STEAM_USERNAME" \
          -password "$STEAM_PASSWORD" \
          -remember-password -no-mobile \
          -app "$APP_ID" \
          $FILELIST_ARG \
          $ARGS \
          -dir "$out" <<< "$(python3 ${steamCodeScript})"
      '';
    };

  # Local filenames reuse each CDN url's own extension rather than a
  # separately hardcoded one, so the two can't drift out of sync. `icon` has
  # no stable fixed-name CDN url (it needs an app-specific hash from the
  # Steam Web API), so it's intentionally not fetched here.
  fetchSteamCdnImages =
    { appId, sha256 }:
    let
      cdnBase = "https://cdn.cloudflare.steamstatic.com/steam/apps/${toString appId}";
      imageUrls = {
        hero = "${cdnBase}/library_hero.jpg";
        grid = "${cdnBase}/library_600x900_2x.jpg";
        wide = "${cdnBase}/header.jpg";
        logo = "${cdnBase}/logo.png";
      };
      extOf = url: lib.last (lib.splitString "." url);
      urlsByFileName = lib.mapAttrs' (
        type: url: lib.nameValuePair "${type}.${extOf url}" url
      ) imageUrls;
      fileNames = lib.mapAttrsToList (type: url: "${type}.${extOf url}") imageUrls;
      typeNames = lib.attrNames imageUrls;

      baseDrv =
        pkgs.runCommand "steam-cdn-images-${toString appId}"
          {
            outputHashMode = "recursive";
            outputHashAlgo = "sha256";
            outputHash = sha256;
            nativeBuildInputs = [ pkgs.curl ];
            SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          }
          ''
            mkdir -p $out
            ${downloadNamedUrls urlsByFileName "$out"}
          '';

      splitDrvs = splitFiles fileNames baseDrv;
    in
    lib.listToAttrs (lib.zipListsWith lib.nameValuePair typeNames splitDrvs);

  fetchSteamGrid =
    { id, sha256 }:
    fetchHtmlThenCurl {
      name = "steamgriddb-${toString id}";
      outputHash = sha256;
      outputHashMode = "flat";
      nativeBuildInputs = [
        pkgs.curl
        pkgs.gnused
        pkgs.gnugrep
      ];
      resolve = ''
        referrer="https://www.steamgriddb.com/grid/${toString id}"
        echo "Fetching page metadata from: $referrer"

        curl -s -H "User-Agent: ${userAgent}" "$referrer" > page.html

        img_url=$(grep -A 1 'class="asset-download"' page.html | sed -n 's|.*href="\([^"]*\)".*|\1|p' | head -n 1)

        if [ -z "$img_url" ]; then
          echo "Error: Could not extract download URL from SteamGridDB page."
          exit 1
        fi

        echo "Found direct image link: $img_url"
        RESOLVED_URL="$img_url"
      '';
      curlOpts = ''-H "User-Agent: ${userAgent}" -H "Referer: $referrer"'';
    };
}
