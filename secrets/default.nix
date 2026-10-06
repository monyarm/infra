{
  lib,
  config,
  isNixOS,
  isHomeManager,
  isHomeManagerInNixOS,
  dirs,
  parallel,
  ...
}:
let
  basicSecrets = builtins.attrNames (
    builtins.removeAttrs (builtins.fromJSON (builtins.readFile ./secrets.json)) [ "sops" ]
  );
in
{
  sops = {
    defaultSopsFile = ./secrets.json;
    defaultSopsFormat = "json";
    age.keyFile =
      if (isNixOS || isHomeManagerInNixOS) then
        "/var/lib/sops-nix/keys.txt"
      else
        "${dirs.HOME}/.config/sops/age/keys.txt";

    secrets =
      let
        # All standalone files are format = "binary": sops treats the whole file
        # as the secret value and does NOT walk the name as a key path.
        # (format = "json" splits the name on "/" and looks each segment up as
        # a key inside the document -- that's for pulling one key out of a
        # shared secrets file, not for whole-file secrets like the maFile.)
        standaloneKeys = [
          "syncthing/key.pem"
          "syncthing/cert.pem"
          "archisteamfarm/cards.maFile.json"
        ];
        jetbrainsKeys = parallel (map (k: "jetbrains/${k}.key")) [
          "clion"
          "phpstorm"
          "webstorm"
        ];
        binaryKeys = standaloneKeys ++ jetbrainsKeys;
      in
      lib.recursiveUpdate
        (
          (lib.genAttrs basicSecrets (_: { }))
          // (lib.genAttrs binaryKeys (name: {
            format = "binary";
            sopsFile = ./. + "/${name}";
          }))
        )
        (
          lib.optionalAttrs isNixOS {
            "syncthing/key.pem" = {
              owner = config.services.syncthing.user;
              group = config.services.syncthing.user;
            };
            "syncthing/cert.pem" = {
              owner = config.services.syncthing.user;
              group = config.services.syncthing.user;
            };
            # services.archisteamfarm runs with ProtectSystem = "strict", so
            # root-owned 0400 sops output under /run/secrets is unreadable.
            # Do NOT use a literal `or "archisteamfarm"` fallback here:
            # sops-install-secrets resolves `owner` through NSS at build time
            # and hard-fails if the account is absent, so the real user must
            # exist. hosts/modules/services/archisteamfarm.nix creates it.
            archisteamfarm_password = {
              owner = config.users.users.archisteamfarm.name;
              group = config.users.users.archisteamfarm.group;
            };
            "archisteamfarm/cards.maFile.json" = {
              owner = config.users.users.archisteamfarm.name;
              group = config.users.users.archisteamfarm.group;
            };
          }
        );
  }
  // lib.optionalAttrs (isHomeManager && !isHomeManagerInNixOS) {
    environment.PATH = lib.mkForce (
      let
        pluginPaths = lib.makeBinPath config.sops.age.plugins;
        systemPaths = "/usr/bin:/bin:/usr/sbin:/sbin";
      in
      lib.concatStringsSep ":" (
        lib.filter (p: p != "") [
          pluginPaths
          systemPaths
        ]
      )
    );
  };
}
