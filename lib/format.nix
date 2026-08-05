{
  lib,
  wasm,
  ...
}:
rec {
  /**
    A generic function to convert a nested attribute set to an rc-style file.
    It recursively walks the attribute set, joining keys with a dot,
    and formats the final key-value pair on a new line.
  */
  toRCFile =
    attrs:
    let
      generateLines =
        path: attrs:
        lib.flatten (
          lib.mapAttrsToList (
            name: value:
            let
              newPath = path ++ [ name ];
            in
            if lib.isAttrs value then
              generateLines newPath value
            else
              let
                keyPath = lib.concatStringsSep "." newPath;
                formattedValue = if lib.isString value then ''"${value}"'' else toString value;
              in
              "${keyPath} ${formattedValue}"
          ) attrs
        );
    in
    lib.concatStringsSep "\n" (generateLines [ ] attrs);

  /**
    Converts a Nix value to an S-expression string, matching
    ihalseide/json-sexpr's `to_s` format exactly (see lib/wasm/serialize).
  */
  inherit (wasm) toSexpr;

  toLisp = toSexpr;

  mkIniFormat =
    mkValueString: value:
    lib.generators.toINIWithGlobalSection
      {
        mkKeyValue = lib.generators.mkKeyValueDefault { inherit mkValueString; } "=";
      }
      {
        globalSection = value._global or { };
        sections = builtins.removeAttrs value [ "_global" ];
      };

  toINI = mkIniFormat (lib.generators.mkValueStringDefault { });

  toTOML = mkIniFormat (
    v: if lib.isString v then "'${v}'" else lib.generators.mkValueStringDefault { } v
  );

  /**
    Converts a Nix attribute set to Valve's plain-text KeyValues format, e.g.
    Steam's appmanifest_<id>.acf files: `"Key"` + two tabs + `"Value"` for
    leaves, brace-delimited nested blocks for sections. This is NOT the same
    format as shortcuts.vdf, which is a separate binary encoding.
  */
  inherit (wasm) toKeyValues;
}
