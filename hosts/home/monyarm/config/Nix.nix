{
  config,
  lib,
  mkOutOfStoreSymlink,
  inputs,
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
        "git-hashing"
        "parse-toml-timestamps"
        "parallel-eval"
      ]
    }
    access-tokens = github.com=${config.sops.placeholder.github_access_token}
    allow-unsafe-native-code-during-evaluation = true
    connect-timeout = 25000
    auto-optimise-store = true
    lazy-trees = true
    eval-cores = 0

    keep-outputs = false
    keep-derivations = false

    min-free = 8192

    keep-going = true
  '';

  xdg.configFile = {
    "nix/nix.conf".source = mkOutOfStoreSymlink config.sops.templates."nix.conf".path;
    "nixpkgs/confix.nix".text = builtins.toJSON nixconf;
  };
  nix = {
    enable = true;
    package = lib.mkForce inputs.determinate-nix.packages."x86_64-linux".nix;
  };
}
