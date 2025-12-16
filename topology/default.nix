{ config, ... }:
with config.lib.topology;
let
  # Helper to create a tailscale interface
  mkTailscaleInterface = address: {
    addresses = [ "${address}/32" ];
    network = "tailscale";
    icon = ./icons/tailscale.png;
  };

  # Helper to create a service definition
  mkService =
    {
      name,
      icon,
      port,
      path ? "",
    }:
    {
      inherit name icon;
      info = "0.0.0.0:${toString port}${path}";
    };

  # Syncthing service definition (reused across devices)
  syncthingService = mkService {
    name = "Syncthing";
    icon = ./icons/syncthing.svg;
    port = 8384;
  };

  # List of tailscale peers for generating connections
  tailscalePeers = [
    "motorola-phone"
    "monyarm"
    "simeon-laptop"
    "gaming-laptop"
  ];

  # Common network style
  mkNetworkStyle =
    {
      primaryColor,
      pattern ? "solid",
    }:
    {
      inherit primaryColor pattern;
      secondaryColor = null;
    };
in
{
  ## 1. Define Networks
  networks = {
    home = {
      name = "Home Network";
      cidrv4 = "192.168.0.0/24";
      style = mkNetworkStyle { primaryColor = "#70a5eb"; };
    };
    tailscale = {
      name = "Tailnet (Overlay VPN)";
      cidrv4 = "100.64.0.0/10";
      style = mkNetworkStyle {
        primaryColor = "#9378de";
        pattern = "dashed";
      };
    };
  };

  ## 2. Define Nodes
  nodes = {

    internet = mkInternet {
      connections = [
        (mkConnection "router" "wan1")
        (mkConnection "tailscale" "wan")
      ];
    };

    tailscale = {
      name = "Tailnet";
      deviceType = "internet";
      interfaces."wan".network = "home";
      interfaces."*" = {
        network = "tailscale";

        physicalConnections = map (peer: mkConnection peer "tailscale0") tailscalePeers;
      };
      hardware.image = ./images/Tailscale.png;
    };

    router = mkRouter "TP Link Archer EX220" {
      info = "A1 Router";
      image = ./images/Router.png;
      interfaceGroups = [
        [ "wan1" ]
        [
          "eth1"
          "eth2"
          "eth3"
          "eth4"
          "wifi"
        ]
      ];

      connections = {
        eth1 = mkConnection "monyarm" "enp4s0";
        wifi = [
          (mkConnection "finlux-tv" "wifi")
          (mkConnection "gaming-laptop" "wlp3s0")
        ];
      };

      interfaces = {
        eth1 = {
          addresses = [ "192.168.0.1" ];
          network = "home";
        };
      };
    };

    # --- monyarm (The Main Host) ---
    monyarm = {
      name = "Home Desktop";
      deviceType = "device";
      icon = "devices.desktop";
      hardware.info = "Linux Desktop";
      deviceIcon = ./icons/gentoo.svg;

      interfaces = {
        enp4s0 = {
          addresses = [ "192.168.0.4/24" ];
          network = "home";
          type = "ethernet";
        };

        tailscale0 = mkTailscaleInterface "100.67.143.124";
      };

      services.home-assistant = mkService {
        name = "Home Assistant";
        icon = "services.home-assistant";
        port = 8123;
      };

      services.jellyfin = mkService {
        name = "Jellyfin";
        icon = "services.jellyfin";
        port = 8096;
      };

      services.matter = mkService {
        name = "Matter Server";
        icon = ./icons/matter.svg;
        port = 5580;
      };

      services.syncthing = syncthingService;

      services.lighttpd = mkService {
        name = "Lighttpd";
        icon = ./icons/lighttpd.png;
        port = 80;
      };
    };

    # --- Tailscale Peers ---
    motorola-phone = {
      name = "motorola-edge-40-neo";
      icon = "devices.desktop";
      deviceType = "device";
      hardware.info = "Android Device";
      deviceIcon = ./icons/android.svg;

      interfaces.tailscale0 = mkTailscaleInterface "100.82.4.38";

      services.syncthing = syncthingService;
    };

    simeon-laptop = {
      name = "simeon-laptop";
      icon = "devices.laptop";
      deviceType = "nixos";
      hardware.info = "Linux Laptop";

      interfaces.tailscale0 = mkTailscaleInterface "100.119.130.60";

      services.syncthing = syncthingService;
    };

    gaming-laptop = {
      name = "Gaming Laptop";
      icon = "devices.laptop";
      hardware.info = "Linux Gaming Laptop";

      interfaces = {
        wlp3s0 = {
          network = "home";
          type = "wifi";
        };

        enp4s0 = {
          network = "home";
          type = "ethernet";
        };

        tailscale0 = mkTailscaleInterface "100.XX.XX.XX"; # TODO: Add actual IP
      };

      services.syncthing = syncthingService;
    };

    # --- Other Devices ---
    finlux-tv = {
      icon = "devices.desktop";
      deviceType = "device";
      hardware.info = "Finlux TV";

      interfaces.wifi = {
        mac = "70:54:b4:1e:bd:20";
        network = "home";
      };

    };
  };
}
