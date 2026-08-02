{
  pkgs,
  fetchToolOutput,
  extractArchiveSnippet,
  ...
}:
{
  fetchGDrive =
    {
      fileId,
      # `hash` matches sources.nix's field name (as update-sources.py
      # writes it), so a `sources.wad.<x>` attrset can be passed straight
      # through, same as fetchIdGames/fetchGitTree already allow; `sha256`
      # stays supported for existing call sites passing a literal directly.
      hash ? null,
      sha256 ? null,
      name ? fileId,
      # Set this when the gdrive download is an archive (zip/rar/etc) that
      # should be unpacked, rather than a single file (e.g. a .pk3) to keep
      # intact as-is.
      extract ? false,
      # sources.nix's recorded archive member list, when this source is a
      # pk3/archive -- attached as passthru so optimize/optimize' can
      # transparently extract/optimize/repack it without a caller needing
      # to pass this same sourceEntry again explicitly.
      archiveContent ? null,
      ...
    }:
    fetchToolOutput {
      inherit name;
      outputHash = if hash != null then hash else sha256;
      outputHashMode = if extract then "recursive" else "flat";
      nativeBuildInputs = [
        pkgs.gdown
        pkgs.cacert
      ];
      extraAttrs.passthru.archiveContent = archiveContent;
      script =
        if extract then
          ''
            export HOME=$TMPDIR
            DOWNLOADED_FILE="$TMPDIR/downloaded"
            gdown "${fileId}" -O "$DOWNLOADED_FILE"
            mkdir -p "$out"
            ${extractArchiveSnippet {
              file = "$DOWNLOADED_FILE";
              outDir = "$out";
            }}
          ''
        else
          ''
            export HOME=$TMPDIR
            gdown "${fileId}" -O "$out"
          '';
    };
}
