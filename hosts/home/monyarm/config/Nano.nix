{
  lib,
  parallel,
  ...
}:

let
  generateNanorc =
    settings: lib.concatStringsSep "\n" (parallel (map (setting: "set ${setting}")) settings);
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
