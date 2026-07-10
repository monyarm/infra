_:

{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operator"
        "coerce-integers"
      ];
      deprecated-features = [
        "floating-without-zero"
        "nul-bytes"
      ];
      allow-unsafe-native-code-during-evaluation = true;
      trusted-users = [
        "root"
        "monyarm"
      ];
      connect-timeout = 25000;
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
