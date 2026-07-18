{ lib, pkgs, ... }:
let

  androidApps = {
    # Example APKs (replace with your actual paths or nixpkgs references)
    aptoide = pkgs.fetchurl {
      url = "https://pool.apk.aptoide.com/aptoide-web/cm-aptoide-pt-12060-71289868-2725e9ae81839a4ae69f8f362fc4d7e1.apk?apk_name=manabox";
      sha256 = "sha256-GIu9uJm+LaQBrARxuk0QaTYS+hBn8uoJh8xuGvz9Q3Q=";
    };
  };

in
{

  # Handle the App installs via an automated loop
  systemd.services.waydroid-apk-sync = {
    description = "Declarative APK Sync Engine";
    after = [
      "waydroid-container.service"
      "waydroid-bootstrap.service"
    ];
    requires =[
      "waydroid-container.service"
      "waydroid-bootstrap.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
    timeout=20
    elapsed=0
    until ${pkgs.waydroid}/bin/waydroid status | grep -q "RUNNING"; do
      if [ "$elapsed" -ge "$timeout" ]; then
        echo "waydroid did not reach RUNNING after ''${timeout}s, giving up" >&2
        exit 1
      fi
      sleep 1
      elapsed=$((elapsed + 1))
    done

  ${lib.concatMapStringsSep "\n" (apk: ''
    ${pkgs.waydroid}/bin/waydroid app install "${apk}" || true
  '') (lib.attrValues androidApps)}
'';

      # Dynamically loop through your nix list to provision the apps
      ${lib.concatMapStringsSep "\n" (apk: ''
        ${pkgs.waydroid}/bin/waydroid app install "${apk}" || true
      '') (lib.attrValues androidApps)}
    '';
  };

}
