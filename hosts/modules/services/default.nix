{ pkgs, ... }:
{
  services.xserver = {
    enable = true;
    autorun = false;
    displayManager.startx = {
      enable = true; # dummy display manager, does nothing
      generateScript = false;
    };
  };
  services.getty = {
    autologinUser = "monyarm";
    autologinOnce = true;
  };
  programs.niri.enable = true;

  # Configure keymap in X11
  services.xserver.xkb.layout = "gb";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  services.printing.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  environment.systemPackages = with pkgs; [
    blueman
    bluez
    pavucontrol
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
}
