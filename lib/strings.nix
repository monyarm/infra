{
  pkgs,
  lib,
  alphabets,
  parallel,
  ...
}:
rec {
  searchChars = lib.flatten (
    parallel (map (c: [
      c
      (lib.toUpper c)
    ])) alphabets
  );

  casefoldRegex =
    str:
    lib.strings.replaceStrings searchChars (lib.flatten (
      parallel (map (
        c:
        let
          regex = "[${c}${lib.toUpper c}]";
        in
        [
          regex
          regex
        ]
      )) alphabets
    )) str;

  urlEncode' =
    charset: text:
    let
      # 1. Custom EUC-JP mapping database
      eucJpDb = {
        # Characters for: シナリオ置き場≪2≫
        "シ" = "%a5%b7";
        "ナ" = "%a5%ca";
        "リ" = "%a5%ea";
        "オ" = "%a5%aa";
        "置" = "%c3%d0";
        "き" = "%a4%ad";
        "場" = "%c1%ec";
        "≪" = "%a1%ec";
        "≫" = "%a1%ed";

        # Keep the original core characters just in case
        "日" = "%c6%fc";
        "本" = "%cb%dc";
        "語" = "%b8%ec";
      };

      # 2. Characters to escape for the URL
      unsafeAscii = {
        " " = "%20";
        "%" = "%25";
        "&" = "%26";
        "+" = "%2b";
        "/" = "%2f";
        "=" = "%3d";
        "?" = "%3f";
        "#" = "%23";
        "<" = "%3c";
        ">" = "%3e";
      };

      # 3. Validation Logic (Strict error tracking for unmapped Multibyte Unicode)
      validateAndEncodeEuc =
        textVal:
        let
          # Strip out all our safely mapped EUC-JP characters
          allowedChars = builtins.attrNames eucJpDb;
          clearedText = builtins.replaceStrings allowedChars (builtins.genList (_: "") (
            builtins.length allowedChars
          )) textVal;

          # Break down the cleared text into individual Unicode characters
          rawChars = lib.strings.stringToCharacters clearedText;

          # Detect non-ASCII elements.
          # Any non-ASCII UTF-8 character will have a byte length greater than 1!
          hasUnmappedMultibyte = lib.lists.any (char: (builtins.stringLength char) > 1) rawChars;
        in
        if hasUnmappedMultibyte then
          throw "EUC-JP Encoder Error: String contains unsupported non-ASCII characters! Please add them to the `eucJpDb` map inside urlEncode'."
        else
          # Run the encoding replacement
          let
            fullMap = unsafeAscii // eucJpDb;
          in
          builtins.replaceStrings (builtins.attrNames fullMap) (builtins.attrValues fullMap) textVal;
    in
    if charset == "euc-jp" then
      validateAndEncodeEuc text
    else if charset == "utf-8" then
      pkgs.lib.strings.escapeURL text
    else
      throw "urlEncode': Unsupported charset: '${charset}'";

  urlEncode = urlEncode' "utf-8";
  urlEncodeEucJp = urlEncode' "euc-jp";

  sanitizeName =
    name:
    let
      # Fast path: an already-clean name (the overwhelming majority --
      # store basenames, archive entries) is returned by the general case
      # below unchanged, so skip straight to truncation instead of paying
      # the split/filter/concat machinery. This pipeline is ~10% of inner
      # eval self-time at 7k files (trace-function-calls), most of it here.
      fastPath = builtins.match "[a-zA-Z0-9_.-]*" name != null;
      # Replace spaces with underscores
      noSpaces = lib.replaceStrings [ " " ] [ "_" ] name;
      # Filter out any other character that isn't alphanumeric, -, _, or .
      # Not stringToCharacters + filter: one call per char, biggest per-file
      # cost (trace-function-calls). split = single regex call.
      filtered = builtins.concatStringsSep "" (
        builtins.filter builtins.isString (builtins.split "[^a-zA-Z0-9_.-]+" noSpaces)
      );
    in
    # Some sources (e.g. itch's multi-upload names, which concatenate every
    # upload's id+hash+timestamp) are already 150+ chars on their own; this
    # gets re-derived (via getName) at every pipeline stage and each stage
    # appends its own suffix ("-pruned", "-optimize-instantiate.drv", ...),
    # so an uncapped name can blow past Nix's 211-char derivation name limit
    # several stages in. Truncating here is safe -- these are all
    # __contentAddressed derivations, so the name is cosmetic, not part of
    # the store path's identity.
    lib.substring 0 100 (if fastPath then name else filtered);

  removeExtension =
    filename:
    # Fast path: no dot at all -> the general case returns filename as-is.
    if builtins.match "[^.]*" filename != null then
      filename
    else
      let
        parts = builtins.filter builtins.isString (builtins.split "\\." filename);
      in
      # Fallback case if the file has no dot extension at all, or if it is a bare hash
      if (builtins.length parts) > 1 then builtins.concatStringsSep "." (lib.init parts) else filename;

  # Strips a leading store-path hash ("<32 chars>-") if present, e.g. from a
  # derivation's .name or a bare path's own baseNameOf -- both carry one.
  stripStoreHash =
    name:
    if builtins.match "[a-z0-9]{32}-.*" name != null then
      builtins.substring 33 (builtins.stringLength name) name
    else
      name;

  getFileName =
    src:
    if lib.isDerivation src then
      stripStoreHash src.name
    else
      let
        strSrc = builtins.unsafeDiscardStringContext (toString src);
        baseName = builtins.baseNameOf strSrc;
        # Check if the string is purely a 52-character content-addressed placeholder hash
        isCaPlaceholder = builtins.match "[a-z0-9]{52}" baseName != null;
      in
      if isCaPlaceholder then
        "ca-file" # Safe fallback name so the pipeline doesn't crash on name generation
      else
        stripStoreHash baseName;

  # Derivation-name-safe stem for a src: strip the store-path hash prefix
  # (getFileName), drop the extension, then strip anything Nix would reject
  # in a derivation name (sanitizeName) -- shared by lib/optimize/ and
  # lib/compressRom/ for naming every intermediate build step.
  getName = src: sanitizeName (removeExtension (getFileName src));

  getFileNameFromUrl =
    url:
    let
      # Try to get query parameter (e.g., ?v=sFVJVWVDIMg)
      queryMatch = builtins.match ".*[?&]v=([^&]+).*" url;
      # Try to get last path segment (e.g., /video.mp4)
      pathMatch = builtins.match ".*/([^/]+)$" url;
    in
    if queryMatch != null then
      builtins.head queryMatch
    else if pathMatch != null then
      builtins.head pathMatch
    else
      "video";
}
