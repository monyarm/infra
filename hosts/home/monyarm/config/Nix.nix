{
  config,
  lib,
  mkOutOfStoreSymlink,
  inputs,
  nixSettings,
  ...
}:
let
  nixconf = {
    allowUnfree = true;
  };
in
{
  sops.templates."nix.conf".content = ''
    ${nixSettings.renderConf nixSettings.common}
    access-tokens = github.com=${config.sops.placeholder.github_access_token}
  '';

  xdg.configFile = {
    "nix/nix.conf".source = mkOutOfStoreSymlink config.sops.templates."nix.conf".path;
    "nixpkgs/config.nix".text = builtins.toJSON nixconf;
  };
  nix = {
    enable = true;
    package = lib.mkForce inputs.determinate-nix.packages."x86_64-linux".nix;
  };
}
