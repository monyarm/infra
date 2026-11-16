{
  autoImport,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.thermalPrinters;
  enabled = lib.filterAttrs (_: printer: printer.enable) cfg;
  printers = lib.attrValues enabled;

  linkService =
    name: printer:
    lib.nameValuePair "thermal-printer-${name}-link" {
      description = "Hold the Bluetooth link to thermal printer ${name}";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${printer.package}/bin/tp --serve --mac ${printer.mac} --channel ${toString printer.channel}";
        Environment = [
          "TP_SOCKET=${printer.socketPath}"
          "TP_IDLE=${toString printer.idleTimeout}"
        ];
        RuntimeDirectory = "thermal-printer";
        # Printer switched off: keep the socket up and retry on the next job.
        Restart = "always";
        RestartSec = 2;
      };
    };

  queueService =
    name: printer:
    lib.nameValuePair "thermal-printer-${name}" {
      description = "Create CUPS queue '${printer.queueName}' for thermal printer ${name}";
      wantedBy = [ "multi-user.target" ];
      wants = [
        "cups.service"
        "thermal-printer-${name}-link.service"
      ];
      after = [
        "cups.service"
        "thermal-printer-${name}-link.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # NixOS has no declarative print-queue option -- queues live in cupsd's
        # runtime printers.conf -- so recreate it on every boot. lpadmin on an
        # existing queue just updates it; retry until cupsd accepts requests.
        ExecStart = pkgs.writeShellScript "thermal-printer-${name}-queue" ''
          for _ in $(seq 30); do
            # CUPS rejects a colon-bearing host in device-uri ("Bad
            # device-uri"), so the MAC uses dashes here; tp.py folds them back.
            ${pkgs.cups}/bin/lpadmin -p ${printer.queueName} -E \
              -v thermal://${lib.replaceStrings [ ":" ] [ "-" ] printer.mac} -m raw && exit 0
            sleep 1
          done
          exit 1
        '';
      };
    };
in
{
  imports = autoImport ./.;

  options.services.thermalPrinters = lib.mkOption {
    default = { };
    description = "Bluetooth ESC/POS thermal printers, each as a raw CUPS queue.";
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }: {
          options = {
            enable = lib.mkEnableOption "this thermal printer";

            package = lib.mkOption {
              type = lib.types.package;
              default = pkgs.tp;
              description = "Package providing the tp CLI and the thermal CUPS backend.";
            };

            mac = lib.mkOption {
              type = lib.types.strMatching "^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$";
              example = "00:11:22:33:44:55";
              description = "Bluetooth address of the printer.";
            };

            channel = lib.mkOption {
              type = lib.types.ints.between 1 30;
              default = 1;
              description = "RFCOMM channel the printer listens on.";
            };

            queueName = lib.mkOption {
              type = lib.types.str;
              default = name;
              description = "CUPS queue name; also the name to pass to lp -d.";
            };

            createQueue = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Create the raw CUPS queue with a systemd oneshot.";
            };

            linkHolder = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Keep the Bluetooth link open between jobs with a systemd service.";
            };

            idleTimeout = lib.mkOption {
              type = lib.types.ints.positive;
              default = 60;
              description = "Seconds without a job before the link is dropped.";
            };

            socketPath = lib.mkOption {
              type = lib.types.str;
              default = "/run/thermal-printer/tp.sock";
              description = "Unix socket the link-holder service listens on.";
            };

            addToSystemPackages = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Put the tp CLI on PATH.";
            };
          };
        }
      )
    );
  };

  config = lib.mkIf (enabled != { }) {
    hardware.bluetooth.enable = true;
    services.printing.drivers = map (printer: printer.package) printers;

    # One printer: tp targets it with no arguments. More than one: tp needs
    # --mac, since nothing says which queue a bare command means.
    environment.systemPackages = map (
      printer:
      if lib.length printers == 1 then
        pkgs.writeShellScriptBin "tp" ''
          export TP_MAC=${printer.mac}
          export TP_CHANNEL=${toString printer.channel}
          export TP_SOCKET=${printer.socketPath}
          exec ${printer.package}/bin/tp "$@"
        ''
      else
        printer.package
    ) (lib.filter (printer: printer.addToSystemPackages) printers);

    systemd.services = lib.listToAttrs (
      lib.mapAttrsToList queueService (lib.filterAttrs (_: printer: printer.createQueue) enabled)
      ++ lib.mapAttrsToList linkService (lib.filterAttrs (_: printer: printer.linkHolder) enabled)
    );
  };
}
