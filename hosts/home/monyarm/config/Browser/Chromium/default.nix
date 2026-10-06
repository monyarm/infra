# Chromium, home-manager half: package + web-store extensions.
#
# The NixOS half lives in hosts/modules/programs/chromium.nix, because
# ManagedBookmarks has to be written to /etc/chromium/policies/ -- Chromium
# reads managed policies from there ONLY (no XDG user policy dir), and HM's
# programs.chromium has no policies option at all.
{ ... }:
{
  imports = [ ./extensions.nix ];

  programs.chromium.enable = true;
}
