# Card tree + ownership manifest generators.
# Sources go in by string interpolation, not `nativeBuildInputs`: stdenv tries
# to execute anything listed there and that fails for plain files.
{ lib, pkgs }:

let
  inherit (lib) concatMapStringsSep optionalString;

  # One `install` stanza per entry, emitted in the already-sorted order.
  installFor =
    entry:
    let
      dest = "$out/${entry.path}";
    in
    ''
      if [ -e "${dest}" ]; then
        echo "console: destination collision at '${entry.path}'" >&2
        exit 1
      fi
    ''
    + optionalString entry.recursive ''
      if [ ! -d "${entry.source}" ]; then
        echo "console: '${entry.path}' declares recursive but '${entry.source}' is not a directory" >&2
        exit 1
      fi
      if find "${entry.source}" -mindepth 1 \! -type d \! -type f -print -quit | grep -q .; then
        echo "console: '${entry.path}' source contains a symlink or non-regular file; refusing to expand" >&2
        exit 1
      fi
      mkdir -p "${dest}"
      cp -r "${entry.source}/." "${dest}/"
    ''
    + optionalString (!entry.recursive) ''
      mkdir -p "$(dirname "${dest}")"
      cp "${entry.source}" "${dest}"
    '';
in
rec {
  # The desired filesystem tree, exactly as it should appear on the card.
  mkTree =
    name: entries:
    pkgs.runCommand "console-tree-${name}" { } ''
      mkdir -p "$out"
      ${concatMapStringsSep "\n" installFor entries}
    '';

  # Sorted JSONL: one object per managed file, keys always in this order.
  # Owner comes from the longest matching declared destination prefix, which
  # is how files produced by a recursive source inherit their parent's owner.
  mkManifest =
    name: tree: entries:
    let
      # Longest destination first so the first prefix match is the most specific.
      ownerRows =
        lib.sort
          (
            a: b:
            builtins.stringLength b.dest < builtins.stringLength
              a.dest or (builtins.stringLength a.dest == builtins.stringLength b.dest && a.dest < b.dest)
          )
          (
            map (e: {
              dest = e.path;
              inherit (e) owner;
            }) entries
          );
      ownersFile = pkgs.writeText "console-owners-${name}" (
        concatMapStringsSep "\n" (e: "${e.dest}\t${e.owner}") ownerRows
      );
    in
    pkgs.runCommand "console-manifest-${name}" { } ''
      # Absolute path: the loop runs with cwd inside the tree, so a relative
            # owners.tsv would not be found.
            owners=${ownersFile}
            emit() {
              rel="$1"
              hash=$(sha256sum "$rel" | cut -d' ' -f1)
              size=$(stat -c %s "$rel")
              owner=$(awk -F'\t' -v f="$rel" '
                {
                  d = $1
                  if (f == d || (length(f) > length(d) && substr(f, 1, length(d) + 1) == d "/")) {
                    print $2
                    exit
                  }
                }
              ' "$owners")
              printf '{"path":"%s","hash":"%s","size":%s,"owner":"%s"}\n' \
                "$rel" "$hash" "$size" "$owner"
            }

            cd ${tree}
            # LC_ALL=C sort keeps ordering byte-stable regardless of locale.
            find . -type f -printf '%P\n' | LC_ALL=C sort | while IFS= read -r rel; do
              [ -n "$rel" ] && emit "$rel"
            done > "$out"
    '';
}
