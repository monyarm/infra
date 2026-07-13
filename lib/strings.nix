{
  pkgs,
  lib,
  alphabets,
  ...
}:
rec {
  searchChars = lib.flatten (
    lib.map (c: [
      c
      (lib.toUpper c)
    ]) alphabets
  );

  casefoldRegex =
    str:
    lib.strings.replaceStrings searchChars (lib.flatten (
      lib.map (
        c:
        let
          regex = "[${c}${lib.toUpper c}]";
        in
        [
          regex
          regex
        ]
      ) alphabets
    )) str;

  urlEncode' =
    charset: text:
    builtins.readFile (
      pkgs.runCommand "url-encode-${charset}" { nativeBuildInputs = [ pkgs.python3 ]; } ''
        python3 << 'PYTHON_EOF' > $out
        text = """${text}"""
        result = []
        for char in text:
            if ord(char) > 127 or char in ' %&+/=?#<> ':
                for byte in char.encode('${charset}'):
                    result.append(f'%{byte:02x}')
            else:
                result.append(char)
        print("".join(result), end="")
        PYTHON_EOF
      ''
    );

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
