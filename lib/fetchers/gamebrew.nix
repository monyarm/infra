# Fetch a homebrew archive linked from a gamebrew.org wiki page.
# dlhb.gamebrew.org 403s unless the request carries `Referer:` naming the wiki
# page, so: read the page, pick the link, curl it with the referer.
{
  pkgs,
  fetchToolOutput,
  ...
}:
{
  fetchGameBrew =
    {
      url,
      hash,
      name ? "gamebrew-${builtins.replaceStrings [ "/" ] [ "_" ] url}",
      file ? null,
    }:
    fetchToolOutput {
      inherit name;
      outputHash = hash;
      outputHashMode = "recursive";
      nativeBuildInputs = [
        pkgs.curl
        pkgs.p7zip
        pkgs.gnused
      ];
      script = ''
        # The page is the referer the CDN checks, and also where the real
        # download URL comes from.
        curl -fsSL ${url} -o page.html

        # Pull every download URL off the page, sorted so selection is
        # deterministic. `[^"]+` stops cleanly at the href's closing quote.
        downloads=$(grep -oE 'https://dlhb\.gamebrew\.org/[^"]+' page.html | sort -u)

        # Decided here rather than in the shell: `file` is a Nix argument, not
        # an environment variable, so a runtime test would always see it empty.
        ${
          if file == null then
            ''
              download=$(printf '%s\n' "$downloads" | head -n1)
            ''
          else
            ''
              # Some links carry a `?k...` cache key. It is stable rather than a
              # per-request nonce, but strip it before matching the basename.
              download=$(printf '%s\n' "$downloads" \
                | sed 's/?.*$//' \
                | grep -E "/${file}\$" \
                | head -n1)
            ''
        }

        if [ -z "''${download}" ]; then
          echo "gamebrew: no download link for ${if file == null then "<any>" else file} on ${url}" >&2
          printf '%s\n' "$downloads" >&2
          exit 1
        fi

        mkdir -p "$out"
        curl -fsSL -H "Referer: ${url}" "$download" -o archive
        chmod +w archive

        # Branch on the download's own name, not the local "archive", and drop
        # any cache key first so the extension is visible.
        name=$(basename "''${download%%\?*}")
        case "$name" in
          *.7z | *.rar)
            7z x -y -o"$out" archive > /dev/null
            ;;
          *.zip)
            ${pkgs.unzip}/bin/unzip -q archive -d "$out"
            ;;
          *)
            # Not an archive: the download is the file itself.
            cp archive "$out/$name"
            ;;
        esac
      '';
    };
}
