# Destination-path helpers for PSP resources.
# Category layout follows Categories Lite (codestation/gclite category.c):
# categories are directories under PSP/GAME and ISO, optionally `CAT_`-prefixed
# and optionally numbered, 30 chars max including the homebrew folder.
{ lib }:

let
  categoryFolder =
    {
      category,
      prefix ? false,
      sort ? false,
      order ? null,
    }:
    let
      digits =
        if (sort && order != null) then
          (if order < 10 then "0${toString order}" else toString order)
        else
          "";
    in
    if prefix then "CAT_${digits}${category}" else "${digits}${category}";

  categoryCharWidth = char: if builtins.stringLength char > 1 then 2 else 1;

  displayWidth =
    text: builtins.foldl' (sum: c: sum + categoryCharWidth c) 0 (lib.stringToCharacters text);
in
{
  inherit categoryFolder displayWidth;

  # Categories Lite's folder-name limit, measured in characters: category
  # folder plus homebrew folder. The plugin counts non-ASCII characters as two.
  categoryNameLimit = 30;

  # Categories Lite caps the category list at 8 including the synthetic
  # "uncategorized" entry.
  maxCategories = 8;

  # Extension a given resource type must carry.
  expectedExtension =
    type:
    {
      "psp-iso" = ".iso";
      "psp-cso" = ".cso";
    }
    .${type} or null;
}
