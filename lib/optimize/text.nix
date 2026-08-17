{
  pkgs,
  lib,
  getName,
  ...
}:
let
  # Filter descriptors -- { name; nativeBuildInputs; cmd; protectAfter; },
  # not derivations. applyFilter (below, one filter -> one derivation) and
  # pipeFilters (several filters piped into ONE derivation, instead of one
  # chained derivation per filter) both consume this same shape, so callers
  # can compose arbitrary combinations without duplicating filter
  # definitions or paying for an extra derivation per stage.

  # Drops empty (or whitespace-only) lines.
  blankLinesFilter =
    {
      protectAfter ? null,
    }:
    {
      name = "noblank";
      nativeBuildInputs = [ pkgs.gnused ];
      cmd = ''${pkgs.gnused}/bin/sed "/^[[:space:]]*$/d"'';
      inherit protectAfter;
    };

  # Drops a whole line whose first non-whitespace bytes are one of
  # `prefixes`. Only matches at the start of a line -- never mid-line,
  # since some formats reuse the same character as real data mid-line
  # (e.g. DeHackEd's "ID # = 64" directive).
  lineCommentsFilter =
    {
      prefixes,
      protectAfter ? null,
    }:
    let
      pattern = "^[[:space:]]*(" + lib.concatMapStringsSep "|" lib.escapeRegex prefixes + ")";
    in
    {
      name = "nocomment";
      nativeBuildInputs = [ pkgs.gnugrep ];
      cmd = "${pkgs.gnugrep}/bin/grep -vE ${lib.escapeShellArg pattern}";
      inherit protectAfter;
    };

  # Drops one or more block-comment styles (e.g. C's { start = "/*"; end =
  # "*/"; }), matched anywhere -- including mid-line and across newlines --
  # like real block comments.
  blockCommentsFilter =
    {
      pairs,
      protectAfter ? null,
    }:
    let
      pairsStr = lib.concatMapStringsSep "\n" (p: "${p.start}\t${p.end}") pairs;
    in
    {
      name = "noblockcomment";
      nativeBuildInputs = [ pkgs.gawk ];
      cmd = "${pkgs.gawk}/bin/gawk -v pairs=${lib.escapeShellArg pairsStr} -f ${./awk/block-comments.awk}";
      inherit protectAfter;
    };

  # Runs one filter's cmd (a plain stdin-to-stdout shell filter, no
  # filename args) over src -- directly if protectAfter is unset, or via
  # protect-byte-ranges.sh (skipping marker-protected byte ranges
  # untouched) if it's set. No guardSize: these are line-based strips,
  # never bigger than the input.
  applyFilter =
    filter: src:
    let
      # grep -v exits 1, not 0, when it filters out every line -- a valid
      # result (nothing survived), not an error.
      run =
        if filter.protectAfter == null then
          ''${filter.cmd} < "${src}" > "$out" || [ "$?" = 1 ]''
        else
          ''${pkgs.bash}/bin/bash ${./sh/protect-byte-ranges.sh} ${lib.escapeShellArg filter.protectAfter} "${src}" "$out" -- ${filter.cmd}'';
    in
    derivation {
      name = "${getName src}-${filter.name}";
      system = pkgs.stdenv.hostPlatform.system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        ''
          export PATH="${pkgs.coreutils}/bin:${pkgs.gawk}/bin:$PATH"
          if [ -s "${src}" ]; then
            ${run}
          else
            ${pkgs.coreutils}/bin/cp "${src}" "$out"
          fi
        ''
      ];
      __contentAddressed = true;
      allowSubstitutes = false;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";
    };

  # Chains several filters as one piped shell pipeline in ONE derivation --
  # same fallback semantics as applyFilter (empty/missing src ->
  # passthrough), checked once against the original input, instead of once
  # per stage. None of the filters may use protectAfter: protect-byte-
  # ranges.sh wraps a single command, not a multi-stage pipe -- a filter
  # needing it has to run through applyFilter (as its own derivation)
  # instead.
  pipeFilters =
    filters: src:
    if lib.any (f: f.protectAfter != null) filters then
      throw "pipeFilters: protectAfter filters can't be piped together, only used with applyFilter individually"
    else
      derivation {
        name = "${getName src}-${lib.concatMapStringsSep "-" (f: f.name) filters}";
        system = pkgs.stdenv.hostPlatform.system;
        builder = "${pkgs.bash}/bin/bash";
        args = [
          "-c"
          ''
            if [ -s "${src}" ]; then
              # Grouped: `cmd1 | cmd2 < in > out` attaches BOTH redirects to
              # cmd2 alone (cmd1 gets no stdin at all and hangs) -- wrapping
              # the whole pipe applies < to its first stage and > to its last.
              { ${lib.concatMapStringsSep " | " (f: f.cmd) filters} ; } < "${src}" > "$out" || [ "$?" = 1 ]
            else
              ${pkgs.coreutils}/bin/cp "${src}" "$out"
            fi
          ''
        ];
        __contentAddressed = true;
        allowSubstitutes = false;
        outputHashAlgo = "sha256";
        outputHashMode = "flat";
      };
in
{
  removeBlankLines = args: src: applyFilter (blankLinesFilter args) src;
  removeLineComments = args: src: applyFilter (lineCommentsFilter args) src;
  removeBlockComments = args: src: applyFilter (blockCommentsFilter args) src;

  inherit
    blankLinesFilter
    lineCommentsFilter
    blockCommentsFilter
    pipeFilters
    ;
}
