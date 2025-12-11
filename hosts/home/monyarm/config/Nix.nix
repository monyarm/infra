{
  config,
  lib,
  mkOutOfStoreSymlink,
  ...
}:
let
  nixconf = {
    allowUnfree = true;
  };
in
{
  sops.templates."nix.conf".content = ''
    experimental-features = ${
      lib.concatStringsSep " " [
        "nix-command"
        "flakes"
        "pipe-operator"
        "coerce-integers"
      ]
    }
    access-tokens = github.com=${config.sops.placeholder.github_access_token}
    allow-unsafe-native-code-during-evaluation = true
  '';

  nixpkgs.config = nixconf;

  xdg.configFile = {
    "nix/nix.conf".source = mkOutOfStoreSymlink config.sops.templates."nix.conf".path;
    "nixpkgs/confix.nix".text = builtins.toJSON nixconf;
  };
}
