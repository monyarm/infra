{ lib, ... }:
let
  rootless = [
    # taken from my current doas.conf, should be updated to reflect the paths in the nix store when these are added there
    "/usr/bin/dump_caches"
    "/usr/bin/flatpak"
    "/home/monyarm/local/dvdrip"
  ];
in
{
  security.doas.enable = true;
  security.sudo.enable = false;
  security.doas.extraRules = [
    {
      groups = [ ":wheel" ];
      keepEnv = true;
      persist = true;
    }
  ]
  ++ lib.map (cmd: {
    groups = [ ":wheel" ];
    noPass = true;
    runAs = "root";
    inherit cmd;
  }) rootless;
}
