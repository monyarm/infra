{
  pkgs,
  lib,
  fetchToolOutput,
  extractArchiveSnippet,
  ...
}:
{
  fetchGOG =
    {
      game,
      # Either one fileId, or a list for GOG's multi-part installers (the
      # main .exe/.sh plus its numbered .bin continuation files) -- all
      # parts must be downloaded together for innoextract/makeself to see
      # the whole archive.
      fileId,
      sha256,
      name ? "gog-${game}-${toString (if lib.isList fileId then lib.head fileId else fileId)}",
    }:
    let
      fileIds = if lib.isList fileId then fileId else [ fileId ];
      downloadFileArg = lib.concatMapStringsSep "," (id: "${game}/${toString id}") fileIds;
    in
    fetchToolOutput {
      inherit name;
      outputHash = sha256;
      outputHashMode = "recursive";
      useSecrets = true;
      nativeBuildInputs = [
        pkgs.lgogdownloader
        pkgs.innoextract
        pkgs.jq
        pkgs.cacert
      ];
      script = ''
        export HOME=$TMPDIR/HOME
        mkdir -p "$HOME/.config/lgogdownloader"

        if [ -z "''${GOG_AUTH:-}" ]; then
          echo "Error: GOG_AUTH is not set in the environment." >&2
          echo "--download-file needs both a Galaxy token and a logged-in" >&2
          echo "website session, which lgogdownloader keeps as two separate" >&2
          echo "files -- generate them once via 'lgogdownloader --login' on a" >&2
          echo "machine with a browser, then combine them into one JSON blob" >&2
          echo "(see scripts/prefetch/prefetch_gog.sh's header comment for the" >&2
          echo "exact jq command)." >&2
          exit 1
        fi

        printf '%s' "''${GOG_AUTH}" | jq -r '.cookies' > "$HOME/.config/lgogdownloader/cookies.txt"
        printf '%s' "''${GOG_AUTH}" | jq -c '.galaxy_tokens' > "$HOME/.config/lgogdownloader/galaxy_tokens.json"

        mkdir -p "$TMPDIR/download"
        lgogdownloader --download-file "${downloadFileArg}" --directory "$TMPDIR/download"

        mkdir -p "$out"
        INSTALLER=$(find "$TMPDIR/download" -iname '*.exe' -o -iname '*.sh' | head -1)
        case "$INSTALLER" in
          *.exe)
            # GOG's Windows installers are InnoSetup archives; the actual game
            # files (for old DOS-era games, alongside a bundled DOSBox port)
            # live at {app}, which --gog maps straight to the output root.
            innoextract --gog -e -d "$out" "$INSTALLER"
            ;;
          *.sh)
            # GOG's Linux installers are MojoSetup wrapped in a makeself
            # archive; makeself scripts are self-extracting, so no extra tool
            # is needed beyond --target/--noexec (skip running the embedded
            # installer). Game data then lives under data/noarch/game/.
            chmod +x "$INSTALLER"
            "$INSTALLER" --target "$out" --noexec --nox11
            ;;
          *)
            echo "Error: no .exe or .sh installer found in the GOG download" >&2
            exit 1
            ;;
        esac

        # Some CD-era games ship their actual resource files inside an ISO
        # image bundled by the installer (e.g. Return of the Phantom's
        # RotP.iso), rather than as loose files; extract each one found and
        # drop the now-redundant raw image.
        find "$out" -iname '*.iso' | while IFS= read -r iso; do
          isoDir="''${iso%.iso}"
          mkdir -p "$isoDir"
          ${extractArchiveSnippet {
            file = "$iso";
            outDir = "$isoDir";
          }}
          rm -f "$iso"
        done
      '';
    };
}
