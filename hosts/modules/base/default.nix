{inputs,...}:

{
  nix = {
    program = inputs.determinate-nix.lib."x86_64-linux".nix;
    settings = {
      experimental-features = [
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
      ];
      allow-unsafe-native-code-during-evaluation = true;
      trusted-users = [
        "root"
        "monyarm"
      ];
      connect-timeout = 25000;
      auto-optimise-store = true;
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Europe/Sofia";

  system.stateVersion = "24.11";

  services.userborn.enable = true;
  virtualisation.virtualbox.guest.enable = false;
  services.tcsd.enable = false;

}
