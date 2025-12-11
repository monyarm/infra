_: {
  services.xserver.enable = true;
  services.displayManager.sddm.enable = false;
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

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
}
