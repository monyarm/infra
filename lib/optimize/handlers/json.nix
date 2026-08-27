{
  pkgs,
  system,
  guardSizeTail,
  getName,
  ...
}:
# Three-stage fallback, each only attempted if the previous produced no
# usable output: minijson (real JSON minifier with comment support, see
# packages/minijson.nix) -> a string-literal-aware Python JSONC-stripper
# piped into jq -c (verified against minijson's own adversarial test
# fixtures) -> plain passthrough via guardSizeTail. Same handler for both
# .json and .jsonc -- neither stage cares which name the file has, and jq
# itself can't parse either extension's content once real comments are in
# it (confirmed: jq fails cleanly, no output, on JSON-with-comments).
{
  handler =
    src:
    derivation {
      name = "${getName src}-minified";
      inherit system;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        ''
          export PATH=${pkgs.coreutils}/bin:${pkgs.minijson}/bin:${pkgs.jq}/bin:${pkgs.python3}/bin
          # minijson's CLI prompts interactively (hangs in a sandboxed build)
          # if the target filename doesn't look like JSON -- tmp.json, not
          # tmp.out, sidesteps that.
          cp "${src}" tmp.json
          chmod +w tmp.json
          if ! minijson --file tmp.json --comment; then
            rm -f tmp.json
            if python3 ${../py/jsoncstrip.py} "${src}" stripped.json \
              && jq -c . stripped.json > tmp.json; then
              :
            else
              rm -f tmp.json
            fi
          fi
          ${guardSizeTail "tmp.json" src}
        ''
      ];
      allowSubstitutes = false;
      __contentAddressed = true;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";
    };
  extensions = [
    "json"
    "jsonc"
  ];
}
