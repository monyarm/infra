{ lib, ... }:
let
  mkCustomizePkgFileContent =
    strings:
    lib.strings.concatStringsSep "#" (
      [
        "replace"
        "source"
      ]
      ++ strings
    );

  mkCustomizePkgFiles =
    files:
    lib.mapAttrs' (name: parts: {
      name = ".customizepkg/${name}";
      value = {
        text = mkCustomizePkgFileContent parts;
      };
    }) files;
in
{
  home.file = mkCustomizePkgFiles {
    "epson-printer-utility" = # Corrected typo here
      let
        commonUrlPart = "https://download3.ebz.epson.net/dsc/f/03/00/10/";
        urlSuffix1 = "63/46/b97d32a556a8cdd77f24289a9b2f2097b6ef4ffc";
        urlSuffix2 = "73/17/307ed265941f8a9a13b826dfe89e5ebc1caa546f";
        pkgInfo = "\$\{pkgname\}_\$\{pkgver\}-1lsb3.2_amd64.deb";
      in
      [
        "${commonUrlPart}${urlSuffix1}/${pkgInfo}"
        "${commonUrlPart}${urlSuffix2}/${pkgInfo}"
      ];
  };
}
