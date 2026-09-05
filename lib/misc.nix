{
  lib,
  pkgs ? null,
  ...
}:
rec {
  # Must share the same thunk in both args -- a separate expression redoes
  # the work instead of reusing it. ~2.9x speedup verified.
  parallel =
    func: args:
    let
      result = func args;
    in
    builtins.parallel args result;

  parallelZipListsWith =
    f: a: b:
    let
      result = lib.zipListsWith f a b;
    in
    builtins.parallel b result;

  addChecks =
    checks: drv:
    let
      checkNames = lib.attrNames checks;
      commandFor =
        check:
        if builtins.isFunction check then
          if builtins.functionArgs check == { } then check else check drv
        else
          check;
      checkScripts = map (
        name:
        let
          command = commandFor checks.${name};
        in
        ''
          current_check=${lib.escapeShellArg name}
          echo "==> $current_check"
          reported_failure=0
          if (set -e; eval ${lib.escapeShellArg command}); then
            :
          else
            status=$?
            if [ "$status" -ne 0 ] && [ ! -e "$failure_marker" ]; then
              report FAIL exit "check exited with status $status"
            fi
          fi
          [ -e "$failure_marker" ] && failed=1
        ''
      ) checkNames;
      existingCheck = drv.checkPhase or null;
      existingScript = lib.optionalString (existingCheck != null) ''
        current_check=check
        echo "==> $current_check"
        reported_failure=0
        if (set -e; eval ${lib.escapeShellArg existingCheck}); then
          :
        else
          status=$?
          if [ "$status" -ne 0 ] && [ ! -e "$failure_marker" ]; then
            report FAIL exit "check exited with status $status"
          fi
        fi
        [ -e "$failure_marker" ] && failed=1
      '';
      checkScript = ''
        set +e
        summary="$TMPDIR/add-checks-summary"
        failure_marker="$TMPDIR/add-checks-failure"
        : > "$summary"
        rm -f "$failure_marker"
        failed=0

        report() {
          status="$1"
          subcheck="$2"
          shift 2
          message="$*"
          printf '%s:%s | %s\n' "$current_check" "$subcheck" "$status" | tee -a "$summary"
          printf '%s\n' "$message"
          if [ "$status" = FAIL ]; then
            failed=1
            reported_failure=1
            : > "$failure_marker"
            return 1
          fi
        }

        report_records() {
          records="$1"
          while IFS=$'\t' read -r status subcheck message; do
            [ -n "$status" ] || continue
            report "$status" "$subcheck" "$message" || :
          done < "$records"
        }

        ${existingScript}
        ${lib.concatStringsSep "\n" checkScripts}

        echo "==> summary"
        cat "$summary"
        exit "$failed"
      '';
    in
    if drv ? overrideAttrs then
      drv.overrideAttrs (
        _old:
        {
          doCheck = true;
          checkPhase = checkScript;
        }
        // (lib.optionalAttrs (drv ? phases) {
          phases = lib.unique ((drv.phases or [ ]) ++ [ "checkPhase" ]);
        })
      )
    else
      # Raw `derivation` (e.g. rename) has no overrideAttrs/checkPhase -- run checks in a wrapper instead.
      pkgs.runCommand (drv.name or "checked-rom")
        {
          allowSubstitutes = false;
          __contentAddressed = true;
          outputHashAlgo = "sha256";
          outputHashMode = "recursive";
        }
        ''
          ${checkScript}
          cp -as "${drv}" "$out"
        '';

  # Longest name wins across all kinds (prefix "decorate*" beats suffix
  # ".txt"). Was a linear scan, biggest per-file cost (trace-function-calls).
  # Bucketed by length instead, hashmap lookup per kind.
  sortDispatchKeys =
    extMap:
    let
      normalized = map (
        m:
        if lib.hasPrefix "$" m.name then
          {
            kind = "exact";
            compareStr = lib.toLower (lib.removePrefix "$" m.name);
            rawLen = builtins.stringLength m.name;
            inherit (m) value;
          }
        else if lib.hasSuffix "*" m.name then
          {
            kind = "prefix";
            compareStr = lib.toLower (lib.removeSuffix "*" m.name);
            rawLen = builtins.stringLength m.name;
            inherit (m) value;
          }
        else
          {
            kind = "suffix";
            compareStr = lib.toLower m.name;
            rawLen = builtins.stringLength m.name;
            inherit (m) value;
          }
      ) (lib.attrsToList (removeAttrs extMap [ "_" ]));
      byLength = lib.groupBy (e: toString e.rawLen) normalized;
      mapOfKind =
        kind: es:
        builtins.listToAttrs (
          map (e: lib.nameValuePair e.compareStr e.value) (lib.filter (e: e.kind == kind) es)
        );
      lengthBuckets = lib.mapAttrs (_: es: {
        exactMap = mapOfKind "exact" es;
        suffixMap = mapOfKind "suffix" es;
        prefixMap = mapOfKind "prefix" es;
      }) byLength;
      sortedLengths = lib.sort (a: b: a > b) (lib.unique (map (e: e.rawLen) normalized));
    in
    {
      inherit lengthBuckets sortedLengths;
    };

  # Strips a leading store-path hash ("<32 chars>-") if present. Duplicated
  # from (not shared with) lib/strings.nix's own stripStoreHash: strings.nix
  # itself depends on this file for `parallel`, so the reverse dependency
  # would be circular.
  stripStoreHash =
    name:
    if builtins.match "[a-z0-9]{32}-.*" name != null then
      builtins.substring 33 (builtins.stringLength name) name
    else
      name;

  # dispatchExt's matching logic, minus the call -- returns the handler (or
  # "_" fallback, or null). Takes the pre-sorted list separately from
  # extMap (needed whole for "_" lookup) instead of re-sorting every call.
  resolveExtSorted =
    matchableList: extMap: src:
    let
      # A "known file" src (dynamic-inner.nix's per-archive-member dispatch)
      # is a bare builtins.path value with no .name attribute, so this falls
      # back to baseNameOf (toString src) -- which, unlike a derivation's
      # .name, always carries a leading store hash. Left unstripped, that
      # hash silently breaks every "name*" prefix-matched alias (e.g.
      # decorate's own comment: "matches bare DECORATE and
      # DECORATE.ChexMonsters"), since the hash sits before the real name.
      rawFileName = stripStoreHash (src.name or (builtins.baseNameOf (toString src)));
      # Stripped: .${...} needs context-free keys. src (context intact)
      # reaches the handler, not these.
      fileName = builtins.unsafeDiscardStringContext (lib.toLower rawFileName);
      fullPath = builtins.unsafeDiscardStringContext (lib.toLower (src.fullPath or rawFileName));

      fileNameLen = builtins.stringLength fileName;
      fullPathLen = builtins.stringLength fullPath;

      # markedLen = l - 1: exact/prefix compareStr had its "$"/"*" marker
      # stripped, suffix didn't.
      tryLength =
        lengths:
        if lengths == [ ] then
          null
        else
          let
            l = builtins.head lengths;
            markedLen = l - 1;
            bucket = matchableList.lengthBuckets.${toString l};
            exactHit = if markedLen == fullPathLen then bucket.exactMap.${fullPath} or null else null;
            suffixHit =
              if l <= fileNameLen then
                bucket.suffixMap.${builtins.substring (fileNameLen - l) l fileName} or null
              else
                null;
            prefixHit =
              if markedLen >= 0 && markedLen <= fileNameLen then
                bucket.prefixMap.${builtins.substring 0 markedLen fileName} or null
              else
                null;
          in
          if exactHit != null then
            exactHit
          else if suffixHit != null then
            suffixHit
          else if prefixHit != null then
            prefixHit
          else
            tryLength (builtins.tail lengths);

      matched = tryLength matchableList.sortedLengths;
    in
    if matched != null then matched else extMap."_" or null;

  resolveExt = extMap: resolveExtSorted (sortDispatchKeys extMap) extMap;

  # Same split as resolveExtSorted/resolveExt, one layer up: calls the handler.
  dispatchExtSorted =
    matchableList: extMap: src:
    let
      handler = resolveExtSorted matchableList extMap src;
    in
    if handler != null then
      handler src
    else
      throw "dispatchExt: No matching handler found for extension in file '${
        lib.toLower (stripStoreHash (src.name or (builtins.baseNameOf (toString src))))
      }'";

  # dispatchExt accepts an attribute set where keys are extensions (e.g., ".zip")
  # and values are the functions handling them. Use "_" for a custom fallback.
  dispatchExt = extMap: dispatchExtSorted (sortDispatchKeys extMap) extMap;
}
