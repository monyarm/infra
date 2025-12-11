{ config, ... }:
with config.lib.topology;
{
  ## 1. Define Networks
  networks = {
    home = {
      name = "Home Network";
      cidrv4 = "192.168.0.0/24";
      # ✅ CORRECTED: Using required style attributes with hex colors.
      style = {
        primaryColor = "#70a5eb"; # Blue from predefinedStyles
        secondaryColor = null; # Null for transparent/unused background
        pattern = "solid";
      };
    };
    tailscale = {
      name = "Tailnet (Overlay VPN)";
      cidrv4 = "100.64.0.0/10";
      style = {
        primaryColor = "#9378de"; # Purple from predefinedStyles
        secondaryColor = null;
        pattern = "dashed"; # Using 'dashed' for the VPN overlay network
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

        physicalConnections = [
          (mkConnection "motorola-phone" "tailscale0")
          (mkConnection "monyarm" "tailscale0")
          (mkConnection "simeon-laptop" "tailscale0")
        ];
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
        wifi = mkConnection "finlux-tv" "wifi";
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
      hardware.info = "Linux Desktop";

      interfaces = {
        enp4s0 = {
          addresses = [ "192.168.0.4/24" ];
          network = "home";
          type = "ethernet";
        };

        tailscale0 = {
          addresses = [ "100.67.143.124/32" ];
          network = "tailscale";
        };
      };

      services.home-assistant = {
        name = "Home Assistant";
        icon = "services.home-assistant";
        info = "http://192.168.0.4:8123";
      };

      services.jellyfin = {
        name = "Jellyfin";
        icon = "services.jellyfin";
        info = "http://192.168.0.4:8096";
      };

      services.matter = {
        name = "Matter Server";
        icon = ./icons/matter.svg;
        info = "TCP/5580";
      };
    };

    # --- Tailscale Peers ---
    motorola-phone = {
      name = "motorola-edge-40-neo";
      icon = "devices.desktop";
      deviceType = "device";
      hardware.info = "Android Device";

      interfaces.tailscale0 = {
        addresses = [ "100.82.4.38/32" ];
        network = "tailscale";
      };
    };

    simeon-laptop = {
      name = "simeon-armenchev-laptop-001";
      icon = "devices.laptop";
      deviceType = "device";
      hardware.info = "Linux Laptop";

      interfaces.tailscale0 = {
        addresses = [ "100.119.130.60/32" ];
        network = "tailscale";
      };
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
