{
  getSecretPath,
  dirs,
  lib,
  ...
}:
let
  deviceList = [
    {
      name = "monyarm-desktop";
      id = "QDUULK4-IFXZ5MO-LQSHOZJ-Q4E67K6-PLIWXKS-ZUDRI56-Y7LPXQZ-Z7FIBQZ";
    }
    {
      name = "monyarm-laptop";
      id = "R2HYOB7-P63AREZ-GHTLY4F-553JZQS-ZOCILFB-4H4SH3P-5CZ6MY6-QAWM6QH";
    }
    {
      name = "motorola edge 40 neo";
      id = "WTN3DND-SPW3N3O-J7XV473-6BTXKME-QIWNU46-PJECA4Y-HQTSLFA-ZEGI7AB";
    }
  ];

  deviceNames = builtins.map (device: device.name) deviceList;
in
{
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    cert = getSecretPath "syncthing/cert.pem";
    key = getSecretPath "syncthing/key.pem";

    settings = {
      folders = {
        "Obsidian" = {
          devices = deviceNames;
          id = "hqrrn-9mxsg";
          versioning.type = "staggered";
          type = "sendreceive";
          ignorePatterns = [ "**/node_modules" ];
          path = "${dirs.HOME}/Documents/Obsidian Notes";
        };
      };
      devices = builtins.listToAttrs (
        builtins.map (
          device:
          lib.nameValuePair device.name {
            inherit (device) id;
            autoAcceptFolders = true;
          }
        ) deviceList
      );
    };
  };
}
