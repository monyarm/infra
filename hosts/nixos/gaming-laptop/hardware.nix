{
  config,
  lib,
  modulesPath,
  inputs,
  ...
}:

{
  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-legion-y530-15ich # Not the exact model (y520-15kbn), but close enough
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/87bcc465-332c-49b4-a40c-246fbbc52f3c";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/0500-89C8";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  fileSystems."/home/monyarm" = {
    device = "/dev/disk/by-uuid/57646ffc-1f74-4084-a5ed-02b9380aae1c";
    fsType = "ext4";
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/6133b12d-84a5-49fe-83d2-167e606f7a13"; }
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp4s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp3s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
