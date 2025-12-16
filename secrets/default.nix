{
  dirs,
  lib,
  config,
  isNixOS,
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
    age.keyFile = "${dirs.HOME}/.config/sops/age/keys.txt";

    secrets =
      let
        standaloneKeys = [
          "syncthing/key.pem"
          "syncthing/cert.pem"
        ];
        jetbrainsKeys = builtins.map (k: "jetbrains/${k}.key") [
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
          }
        );
  };
}
