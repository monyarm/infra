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
        "pipe-operators"
        "ca-derivations"
        "dynamic-derivations"
        "configurable-impure-env"
        "impure-derivations"
        "recursive-nix"
        "lazy-trees"
        "parallel-eval"
      ]
    }
    access-tokens = github.com=${config.sops.placeholder.github_access_token}
    allow-unsafe-native-code-during-evaluation = true
    connect-timeout = 25000
    auto-optimise-store = true
  '';

  xdg.configFile = {
    "nix/nix.conf".source = mkOutOfStoreSymlink config.sops.templates."nix.conf".path;
    "nixpkgs/confix.nix".text = builtins.toJSON nixconf;
  };
}
