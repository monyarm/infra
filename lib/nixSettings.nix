{ lib, ... }:
let
  common = {
    experimental-features = [
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
    ];
    allow-unsafe-native-code-during-evaluation = true;
    connect-timeout = 25000;
    auto-optimise-store = true;
    lazy-trees = true;
    eval-cores = 0;
    keep-outputs = false;
    keep-derivations = false;
    min-free = 8192;
    keep-going = true;
  };

  mkValueString =
    v:
    if builtins.isList v then
      lib.concatStringsSep " " v
    else if builtins.isBool v then
      (if v then "true" else "false")
    else
      toString v;

  # Renders a settings attrset as nix.conf lines (`key = value`), for
  # contexts (like a sops template) that need the literal file text rather
  # than the `nix.settings` module option.
  renderConf =
    settings: lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "${k} = ${mkValueString v}") settings);
in
{
  inherit common renderConf;
}
