{
  lib,
  ...
}:

let
  generateNanorc = settings: lib.concatStringsSep "\n" (lib.map (setting: "set ${setting}") settings);
in
{
  home.file.".nanorc".text = generateNanorc [
    # keep-sorted start
    "atblanks"
    "autoindent"
    "colonparsing"
    "linenumbers"
    "softwrap"
    # keep-sorted end
  ];
}
