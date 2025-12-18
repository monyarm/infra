{
  config,
  lib,
  mkOutOfStoreSymlink,
  isHomeManagerInNixOS,
  ...
}:
let
  nixconf = {
    allowUnfree = true;
  };
in
lib.mkMerge [
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

    xdg.configFile = {
      "nix/nix.conf".source = mkOutOfStoreSymlink config.sops.templates."nix.conf".path;
      "nixpkgs/confix.nix".text = builtins.toJSON nixconf;
    };
  }
  (lib.optionalAttrs (!isHomeManagerInNixOS) {
    nixpkgs.config = nixconf;
  })
]
