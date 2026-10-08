# Chromium, NixOS half: enterprise policy.
#
# Split from the home-manager half (hosts/home/monyarm/config/Browser/Chromium/)
# because Chromium reads managed policies from /etc/chromium/policies/ ONLY --
# there is no XDG user policy directory, and HM's programs.chromium exposes no
# policies option. The nixos module writes extra.json to
# environment.etc."chromium/policies/managed".
{
  pkgs,
  urlEncodeEucJp,
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
    inherit importSopsNix urlEncodeEucJp;
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
  # NixOS's programs.chromium.enable only gates the environment.etc policy
  # files -- it does not add chromium to environment.systemPackages, so this
  # does not duplicate the HM-installed binary. Without it extraOpts is never
  # forced and no /etc/chromium/policies is written.
  programs.chromium = {
    enable = true;
    extraOpts = {
      ManagedBookmarks = managed;

      # Chromium otherwise shows the bookmarks bar only on the new-tab page.
      BookmarkBarEnabled = true;
    };
  };
}
