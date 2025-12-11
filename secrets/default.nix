{ dirs, lib, ... }:
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
        binaryKeys = builtins.map (k: "jetbrains/${k}.key") [
          "clion"
          "phpstorm"
          "webstorm"
        ];
      in
      (lib.genAttrs basicSecrets (_: { }))
      // (lib.genAttrs binaryKeys (name: {
        format = "binary";
        sopsFile = ./. + "/${name}";
      }));
  };
}
