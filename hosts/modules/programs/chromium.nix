# Chromium, NixOS half: enterprise policy.
#
# Split from the home-manager half (hosts/home/monyarm/config/Browser/Chromium/)
# because Chromium reads managed policies from /etc/chromium/policies/ ONLY --
# there is no XDG user policy directory, and HM's programs.chromium exposes no
# policies option. The nixos module writes extra.json to
# environment.etc."chromium/policies/managed".
{
  lib,
  pkgs,
  ...
}:
let
  # same shape as lib/imports.nix's importSopsNix, which is a HM-extra and not
  # reachable from here.
  importSopsNix =
    file:
    builtins.exec [
      "${pkgs.sops}/bin/sops"
      "--decrypt"
      (toString file)
    ];

  bookmarks = import ../../home/monyarm/config/Browser/data/bookmarks.nix {
    inherit importSopsNix;
    inherit (lib) urlEncodeEucJp;
  };

  # Firefox tree -> Chromium ManagedBookmarks: `bookmarks` becomes `children`,
  # `toolbar`/`url` markers are dropped, and the root gets a display name via
  # toplevel_name (defaults to "Managed bookmarks" otherwise).
  #
  # Keys are lowercase -- verified in Chromium's managed_bookmarks_tracker.cc
  # (kName/kUrl/kChildren/kFolderName) and common_schemas.yaml.
  toChromium =
    node:
    if node ? bookmarks then
      {
        inherit (node) name;
        children = map toChromium node.bookmarks;
      }
    else
      {
        inherit (node) name;
        inherit (node) url;
      };

  managed = map (root: {
    toplevel_name = root.name;
    children = map toChromium root.bookmarks;
  }) bookmarks.all;
in
{
  programs.chromium.extraOpts = {
    ManagedBookmarks = managed;

    # Chromium otherwise shows the bookmarks bar only on the new-tab page.
    BookmarkBarEnabled = true;
  };
}
