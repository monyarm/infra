{ format, bluetoothMacs, ... }:
{
  # bluealsa isn't installed/enabled anywhere in this repo (it's a system
  # daemon, out of home-manager's reach) and every host now launches
  # gentoo-pipewire-launcher / wireplumber, which handle Bluetooth audio
  # through PipeWire instead. This looks like leftover pre-PipeWire config;
  # disabled rather than deleted until that's confirmed.
  # home.file.".asoundrc".text = format.toRCFile {
  #   defaults.bluealsa = {
  #     service = "org.bluealsa";
  #     device = bluetoothMacs.headphones;
  #     profile = "a2dp";
  #     delay = 10000;
  #   };
  # };
}
