{
  pkgs,
  fetchToolOutput,
  ...
}:
{
  fetchGOG =
    {
      game,
      fileId,
      sha256,
      name ? "gog-${game}-${toString fileId}",
    }:
    fetchToolOutput {
      inherit name;
      outputHash = sha256;
      outputHashMode = "recursive";
      useSecrets = true;
      nativeBuildInputs = [
        pkgs.lgogdownloader
        pkgs.curl
        pkgs.cacert
      ];
      extraAttrs = {
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      };
      script = ''
        export HOME=$TMPDIR/HOME
        mkdir -p "$HOME/.config/lgogdownloader"

        if [ -z "''${GOG_REFRESH_TOKEN:-}" ]; then
          echo "Error: GOG_REFRESH_TOKEN is not set in the environment." >&2
          exit 1
        fi

        # lgogdownloader has no CLI flag to feed a refresh token directly, and
        # its interactive login paths need a GUI (unusable in a sandbox), so
        # we do the OAuth refresh ourselves and drop the raw response straight
        # into galaxy_tokens.json. lgogdownloader auto-computes "expires_at"
        # from "expires_in" + the file's mtime on load if it's missing, and
        # falls back to its own hardcoded client_id/client_secret if absent,
        # so the raw token endpoint response is already a valid tokens file.
        curl -fsSL "https://auth.gog.com/token?client_id=46899977096215655&client_secret=9d85c43b1482497dbbce61f6e4aa173a433796eeae2ca8c5f6129f2dc4de46d9&grant_type=refresh_token&refresh_token=$GOG_REFRESH_TOKEN" \
          -o "$HOME/.config/lgogdownloader/galaxy_tokens.json"

        if ! grep -q access_token "$HOME/.config/lgogdownloader/galaxy_tokens.json"; then
          echo "Error: failed to refresh GOG OAuth token:" >&2
          cat "$HOME/.config/lgogdownloader/galaxy_tokens.json" >&2
          exit 1
        fi

        mkdir -p "$out"
        lgogdownloader --download-file "${game}/${toString fileId}" --directory "$out"
      '';
    };
}
