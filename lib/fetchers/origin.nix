{
  pkgs,
  lib,
  fetchToolOutput,
  ...
}:
let
  # Drives maxima-cli's interactive `inquire`-based install flow over a pty
  # (plain piped stdin doesn't work -- inquire::Select needs a real raw-mode
  # terminal). There's no non-interactive full-game-download subcommand as of
  # whatever commit sources.tools.maxima currently resolves to -- see
  # packages/maxima-cli.nix for the pin. A future update-sources.py bump that
  # changes maxima-cli's prompt wording or flow breaks this script; fix it
  # and the hand-committed Cargo.lock together.
  originInstallScript = pkgs.writeText "origin-install.py" ''
    import sys

    import pexpect

    search, out_dir = sys.argv[1:3]

    child = pexpect.spawn("maxima-cli", encoding="utf-8", timeout=None)
    child.logfile = sys.stdout

    child.expect("What would you like to do?")
    child.send("Install Game")
    child.sendline("")

    child.expect("What game would you like to install\\?")
    child.sendline(search)

    child.expect("Where would you like to install the game")
    child.sendline(out_dir)

    index = child.expect(["Download took", pexpect.EOF])
    if index != 0:
        print("maxima-cli exited without completing the download.", file=sys.stderr)
        sys.exit(1)

    child.expect(pexpect.EOF)
  '';
in
{
  fetchOrigin =
    {
      search,
      sha256,
      name ? "origin-${lib.strings.sanitizeDerivationName search}",
    }:
    fetchToolOutput {
      inherit name;
      outputHash = sha256;
      outputHashMode = "recursive";
      useSecrets = true;
      nativeBuildInputs = [
        pkgs.maxima-cli
        (pkgs.python3.withPackages (ps: [ ps.pexpect ]))
      ];
      extraAttrs = {
        SEARCH = search;
      };
      script = ''
        export HOME=$TMPDIR/HOME
        mkdir -p "$HOME/.local/share/maxima"

        if [ -z "''${MAXIMA_AUTH:-}" ]; then
          echo "Error: MAXIMA_AUTH is not set in the environment." >&2
          echo "Run 'maxima-cli create-auth-code --client-id <id>' then" >&2
          echo "'maxima-cli juno-token-refresh' once locally, and set MAXIMA_AUTH" >&2
          echo "to the resulting auth.toml's contents as a sops secret." >&2
          exit 1
        fi
        printf '%s' "$MAXIMA_AUTH" > "$HOME/.local/share/maxima/auth.toml"

        python3 ${originInstallScript} "$SEARCH" "$out"
      '';
    };
}
