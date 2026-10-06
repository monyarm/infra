# Browser configuration entry point. autoImport picks this up because the
# containing directory has a default.nix (see lib/imports.nix: a directory with
# default.nix is imported as a whole; its sibling .nix files are not swept in).
#
# bookmarks data lives in ./data/bookmarks.nix -- NOT here, because autoImport
# treats every non-default .nix file in a config directory as a module, and a
# data file would blow up on its mkBookmark/toolbar keys. It also keeps
# bookmarks-private.sops.nix out of the module graph.
{
  importSopsNix,
  urlEncodeEucJp,
  ...
}:
let
  data = import ./data/bookmarks.nix { inherit importSopsNix urlEncodeEucJp; };
in
{
  _module.args.bookmarks = data;

  imports = [
    ./Chromium
    ./Firefox
  ];
}
