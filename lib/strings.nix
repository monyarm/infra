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
      # Replace spaces with underscores
      noSpaces = lib.replaceStrings [ " " ] [ "_" ] name;
      # Filter out any other character that isn't alphanumeric, -, _, or .
      # Nix built-in validation is picky, so keeping it to a safe subset is best.
      safeChars = lib.stringToCharacters "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-.";
      chars = lib.stringToCharacters noSpaces;
      filteredChars = builtins.filter (c: builtins.elem c safeChars) chars;
    in
    builtins.concatStringsSep "" filteredChars;

  removeExtension =
    filename:
    let
      parts = builtins.filter builtins.isString (builtins.split "\\." filename);
    in
    # Fallback case if the file has no dot extension at all, or if it is a bare hash
    if (builtins.length parts) > 1 then builtins.concatStringsSep "." (lib.init parts) else filename;

  getFileName =
    src:
    if lib.isDerivation src then
      let
        rawName = src.name;
        hasHash = builtins.match "[a-z0-9]{32}-.*" rawName != null;
      in
      if hasHash then builtins.substring 33 (builtins.stringLength rawName) rawName else rawName
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
        baseName;
}
