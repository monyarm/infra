{ lib, ... }:
{
  # dispatchExt accepts an attribute set where keys are extensions (e.g., ".zip")
  # and values are the functions handling them. Use "_" for a custom fallback.
  dispatchExt =
    extMap: src:
    let
      # Coerce to string, grab the basename, and force it to lowercase
      rawFileName = src.name or (builtins.baseNameOf (toString src));
      fileName = lib.toLower rawFileName;

      matchableAttrs = removeAttrs extMap [ "_" ];
      matchableList = lib.attrsToList matchableAttrs;

      matched =
        lib.findFirst
          # The key (m.name) is checked against the lowercase filename
          (m: lib.hasSuffix m.name fileName)
          null
          matchableList;
    in
    if matched != null then
      matched.value src
    else if extMap ? "_" then
      extMap."_" src
    else
      throw "dispatchExt: No matching handler found for extension in file '${fileName}'";
}
