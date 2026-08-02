{ pkgs, lib, getName, ... }:
let
  # Runs `cmd` (a plain stdin-to-stdout shell filter, no filename args) over
  # src -- directly if protectAfter is unset, or via protect-byte-ranges.sh
  # (skipping marker-protected byte ranges untouched) if it's set. Shared by
  # every function below so they only differ in which filter they run. No
  # guardSize: these are line-based strips, never bigger than the input.
  applyFilter =
    name: nativeBuildInputs: cmd: protectAfter: src:
    let
      # grep -v exits 1, not 0, when it filters out every line -- a valid
      # result (nothing survived), not an error.
      run =
        if protectAfter == null then
          ''${cmd} < "${src}" > "$out" || [ "$?" = 1 ]''
        else
          ''bash ${./protect-byte-ranges.sh} ${lib.escapeShellArg protectAfter} "${src}" "$out" -- ${cmd}'';
    in
    pkgs.runCommand "${getName src}-${name}"
      {
        nativeBuildInputs = nativeBuildInputs ++ lib.optional (protectAfter != null) pkgs.gawk;
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      }
      ''
        if [ -s "${src}" ]; then
          ${run}
        else
          cp "${src}" "$out"
        fi
      '';

  # protectAfter (all three functions): a gawk regex whose capture groups
  # are summed for the byte count of raw content immediately following a
  # matching line, copied through completely untouched -- for formats like
  # DeHackEd's "Text <fromLen> <toLen>" blocks, whose replacement text is
  # raw, length-prefixed content that must never be touched by these.
in
{
  # Drops empty (or whitespace-only) lines.
  removeBlankLines =
    { protectAfter ? null }:
    src:
    applyFilter "noblank" [ pkgs.gnused ] ''${pkgs.gnused}/bin/sed "/^[[:space:]]*$/d"'' protectAfter src;

  # Drops a whole line whose first non-whitespace bytes are one of
  # `prefixes`. Only matches at the start of a line -- never mid-line,
  # since some formats reuse the same character as real data mid-line
  # (e.g. DeHackEd's "ID # = 64" directive).
  removeLineComments =
    { prefixes, protectAfter ? null }:
    src:
    let
      pattern = "^[[:space:]]*(" + lib.concatMapStringsSep "|" lib.escapeRegex prefixes + ")";
    in
    applyFilter "nocomment" [
      pkgs.gnugrep
    ] "${pkgs.gnugrep}/bin/grep -vE ${lib.escapeShellArg pattern}" protectAfter src;

  # Drops one or more block-comment styles (e.g. C's { start = "/*"; end =
  # "*/"; }), matched anywhere -- including mid-line and across newlines --
  # like real block comments.
  removeBlockComments =
    { pairs, protectAfter ? null }:
    src:
    let
      pairsStr = lib.concatMapStringsSep "\n" (p: "${p.start}\t${p.end}") pairs;
    in
    applyFilter "noblockcomment" [
      pkgs.gawk
    ] "${pkgs.gawk}/bin/gawk -v pairs=${lib.escapeShellArg pairsStr} -f ${./block-comments.awk}" protectAfter src;
}
