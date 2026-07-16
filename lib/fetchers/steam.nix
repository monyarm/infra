{
  pkgs,
  splitFiles,
  fetchzipNoSubst,
  ...
}:
{
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
