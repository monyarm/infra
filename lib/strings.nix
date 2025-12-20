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
            if ord(char) > 127:
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
}
