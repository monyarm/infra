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
    deprecated-features = ${
      lib.concatStringsSep "" [
        "floating-without-zero"
        "nul-bytes"
      ]
    }
    access-tokens = github.com=${config.sops.placeholder.github_access_token}
    allow-unsafe-native-code-during-evaluation = true
    connect-timeout = 25000
  '';

  xdg.configFile = {
    "nix/nix.conf".source = mkOutOfStoreSymlink config.sops.templates."nix.conf".path;
    "nixpkgs/confix.nix".text = builtins.toJSON nixconf;
  };
}
