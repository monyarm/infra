{
  pkgs,
  parallel,
  ...
}:
let
  rootless = [
    # taken from my current doas.conf, should be updated to reflect the paths in the nix store when these are added there
    "/usr/bin/dump_caches"
    "/usr/bin/flatpak"
  ];

  # lib/fetchers/disc.nix's ripDisc/ripDiscContents/ripDiscRedumper. Args
  # left unrestricted here (doas's `args` field requires an exact full-argv
  # match, which can't express "device must be an optical drive" while
  # --title/--out vary per game) -- disc-rip-helper validates --device
  # itself before touching anything.
  discRipHelper = "${pkgs.disc-rip-helper}/bin/disc-rip-helper";
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
  ++ parallel (map (cmd: {
    groups = [ ":wheel" ];
    noPass = true;
    runAs = "root";
    inherit cmd;
  })) (rootless ++ [ discRipHelper ])
  ++ [
    # A nix-daemon build always runs as one of the nixbld1..64 pool
    # accounts, never as the interactive wheel-group user -- the disc
    # fetchers call doas from inside their build script, so they need
    # their own grant keyed on the actual builder identity, additive to
    # the wheel-based grant above (which covers running the helper
    # interactively outside a build).
    {
      groups = [ ":nixbld" ];
      noPass = true;
      runAs = "root";
      cmd = discRipHelper;
    }
  ];
}
