{
  inputs,
  nixSettings,
  user,
  stateVersion,
  timeZone,
  ...
}:

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

        sshUser = user.name;
        sshKey = "/etc/ssh/ssh_host_ed25519_key";

      }

      # {
      #   hostName = "eu.nixbuild.net";
      #   system = "x86_64-linux";
      #   maxJobs = 24;
      #   speedFactor = 1;
      #   supportedFeatures = [
      #     "nixos-test"
      #     "big-parallel"
      #     "ca-derivations"
      #   ];
      #   sshUser = user.name;
      #   sshKey = "/etc/ssh/ssh_host_ed25519_key";
      # }
    ];

    settings = nixSettings.common // {
      trusted-users = [
        "root"
        user.name
      ];
      builders-use-substitutes = true;
      max-jobs = 8 - 2;
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Default (100000) is a system-wide aggregate, not per-sandbox -- a single
  # large archive going through lib/optimize/dynamic-inner.nix's per-file
  # recursive-nix sandbox (one dynamic bind-mount per file, several per file
  # in practice) can approach it alone. Exceeding it surfaces as a generic,
  # textually-identical-to-real-disk-full "No space left on device" on the
  # next bind-mount, which is genuinely misleading to debug.
  boot.kernel.sysctl."fs.mount-max" = 1000000;

  time.timeZone = timeZone;

  system.stateVersion = stateVersion;

  services.userborn.enable = true;
  virtualisation.virtualbox.guest.enable = false;
  services.tcsd.enable = false;

  programs.ssh.knownHosts = {
    "monyarm" = {
      hostNames = [ "monyarm" ];
      publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDKY6U2A27whIn6CbkikaNxgctvktDypSwpiRsnso6zF2XzJqDMxvPCPcl6nR0qxXc9rQEaJf1WZdSt5nwdiHvEq7RAqnopB/MdZpB/2ACJ8UYbd8AoSgCqTKa3QFOx6AlYEn4AL0NwBawRTlfIsqUE6ufk0DkghaEREh5DkB9QcyomZxUo5NYXy7u0UB4McMCiadDVu35sIs1oN2T8hBoZS8KVGJI8uWpyoeLAkSxegk/wommQ49rMTkca+1h7q9qHlBtYnhDyClPFlXLln8Gr+l8pS+2gEGDgfCxekulYa4yuoHgXNLhuZqHKNmw1QK+N9JRYKWGBLEF1k1OFJ2dx monyarm@gmail.com";
    };

    nixbuild = {
      hostNames = [ "eu.nixbuild.net" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
    };
  };

  # Without IdentitiesOnly, ssh offers every key in the agent before this
  # one -- nixbuild.net's server hits its max-auth-tries limit and drops
  # the connection as "Permission denied" before ever trying the right key.
  programs.ssh.extraConfig = ''
    Host eu.nixbuild.net
      PubkeyAcceptedKeyTypes ssh-ed25519
      IdentitiesOnly yes
      IdentityFile /etc/ssh/ssh_host_ed25519_key
      ServerAliveInterval 60
      IPQoS throughput
  '';

  systemd.services.nix-daemon = {
    serviceConfig = {
      EnvironmentFile = "-/run/nix-daemon-secrets.env";
    };
  };

}
