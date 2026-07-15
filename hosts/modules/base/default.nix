{ inputs, ... }:

{
  nix = {
    package = inputs.determinate-nix.packages."x86_64-linux".nix;

    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "monyarm";
        system = "x86_64-linux";
        maxJobs = 16;
        speedFactor = 2;
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
          "ca-derivations"
        ];

        sshUser = "monyarm";
        sshKey = "/etc/ssh/ssh_host_ed25519_key";

      }
    ];

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
        "git-hashing"
        "parse-toml-timestamps"
        "parallel-eval"
      ];
      allow-unsafe-native-code-during-evaluation = true;
      trusted-users = [
        "root"
        "monyarm"
      ];
      connect-timeout = 25000;
      auto-optimise-store = true;
      lazy-trees = true;
      eval-cores = 0;

      keep-outputs = false;
      keep-derivations = false;

      min-free = 8192;

      keep-going = true;

      builders-use-substitutes = true;

      max-jobs = 8;
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Europe/Sofia";

  system.stateVersion = "24.11";

  services.userborn.enable = true;
  virtualisation.virtualbox.guest.enable = false;
  services.tcsd.enable = false;

  programs.ssh.knownHosts = {
    "monyarm" = {
      hostNames = [ "monyarm" ];
      publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDKY6U2A27whIn6CbkikaNxgctvktDypSwpiRsnso6zF2XzJqDMxvPCPcl6nR0qxXc9rQEaJf1WZdSt5nwdiHvEq7RAqnopB/MdZpB/2ACJ8UYbd8AoSgCqTKa3QFOx6AlYEn4AL0NwBawRTlfIsqUE6ufk0DkghaEREh5DkB9QcyomZxUo5NYXy7u0UB4McMCiadDVu35sIs1oN2T8hBoZS8KVGJI8uWpyoeLAkSxegk/wommQ49rMTkca+1h7q9qHlBtYnhDyClPFlXLln8Gr+l8pS+2gEGDgfCxekulYa4yuoHgXNLhuZqHKNmw1QK+N9JRYKWGBLEF1k1OFJ2dx monyarm@gmail.com";
    };
  };

}
