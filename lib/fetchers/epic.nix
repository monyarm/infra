{
  pkgs,
  fetchToolOutput,
  ...
}:
{
  fetchEpic =
    {
      app,
      sha256,
      name ? "epic-${app}",
    }:
    fetchToolOutput {
      inherit name;
      outputHash = sha256;
      outputHashMode = "recursive";
      useSecrets = true;
      nativeBuildInputs = [
        pkgs.legendary-gl
        pkgs.cacert
      ];
      extraAttrs = {
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      };
      script = ''
        export HOME=$TMPDIR/HOME
        mkdir -p "$HOME/.config/legendary"

        if [ -z "''${EPIC_LEGENDARY_AUTH:-}" ]; then
          echo "Error: EPIC_LEGENDARY_AUTH is not set in the environment." >&2
          echo "Generate it once out-of-band via 'legendary auth' (needs a real" >&2
          echo "browser login) then copy the content of ~/.config/legendary/user.json." >&2
          exit 1
        fi
        # legendary refreshes its own access_token from the stored
        # refresh_token using its embedded client credentials, so seeding
        # user.json directly (no manual OAuth exchange, unlike GOG) is enough.
        printf '%s' "$EPIC_LEGENDARY_AUTH" >"$HOME/.config/legendary/user.json"

        mkdir -p "$out"
        legendary -y install "${app}" --base-path "$out" --download-only --skip-sdl
      '';
    };
}
