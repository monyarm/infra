{
  inputs,
  nixSettings,
  user,
  stateVersion,
  timeZone,
  config,
  ...
}:

let
  # fleet machines, self included -- lets other hosts reach this one too.
  # filter below drops self -- no ssh-to-self loop.
  allBuildMachines = [
    {
      hostName = "monyarm";
      protocol = "ssh-ng";
      system = "x86_64-linux";
      maxJobs = 16;
      speedFactor = 2;
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
        "ca-derivations"
        "cdrom"
      ];

      sshUser = user.name;
      sshKey = "/etc/ssh/ssh_host_ed25519_key";

    }

    {
      hostName = "gaming-laptop";
      protocol = "ssh-ng";
      system = "x86_64-linux";
      maxJobs = 8;
      speedFactor = 1;
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
  # max-jobs = this host's own entry above, minus 2. add an entry above
  # before reusing this module on a new host.
  currentHostMachine = builtins.head (
    builtins.filter (m: m.hostName == config.networking.hostName) allBuildMachines
  );
in
{
  nix = {
    package = inputs.determinate-nix.packages."x86_64-linux".nix;

    distributedBuilds = true;
    # appended here, not in allBuildMachines -- would break self-matching
    # above. ssh:// force-resets max-connections to 1 regardless; ssh-ng doesn't.
    buildMachines = map (
      m: m // { hostName = "${m.hostName}?max-connections=${toString m.maxJobs}"; }
    ) (builtins.filter (m: m.hostName != config.networking.hostName) allBuildMachines);

    settings = nixSettings.common // {
      trusted-users = [
        "root"
        user.name
      ];
      builders-use-substitutes = true;
      max-jobs = currentHostMachine.maxJobs - 2;
    };

    nrBuildUsers = 64;
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
  #
  # monyarm builder gets its own stanza: ControlMaster keeps one session
  # alive and reused instead of a fresh SSH handshake per connection --
  # what Hydra itself uses (github.com/NixOS/nix/issues/8499). Shared
  # sticky-bit socket dir (like /tmp), not root-only -- both nix-daemon's
  # root-owned remote-build connections and this user's own interactive
  # `ssh monyarm` need to land in the same place without colliding (%r in
  # the path already keys each user's socket separately).
  programs.ssh.extraConfig = ''
    Host eu.nixbuild.net
      PubkeyAcceptedKeyTypes ssh-ed25519
      IdentitiesOnly yes
      IdentityFile /etc/ssh/ssh_host_ed25519_key
      ServerAliveInterval 60
      IPQoS throughput

    Host monyarm
      ControlMaster auto
      ControlPath /run/ssh-control/%r@%h-%p
      ControlPersist 10m
  '';

  systemd.tmpfiles.rules = [ "d /run/ssh-control 1777 root root -" ];

  systemd.services.nix-daemon = {
    serviceConfig = {
      EnvironmentFile = "-/run/nix-daemon-secrets.env";
    };
  };

}
