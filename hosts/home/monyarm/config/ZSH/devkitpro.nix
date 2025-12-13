{ lib, ... }:
let
  DEVKITPRO = "/opt/devkitpro";
in
{
  home.sessionVariables = {
    inherit DEVKITPRO;
  }
  // (lib.genAttrs' [ "ARM" "PPC" "PSP" ] (
    name: lib.nameValuePair "DEVKIT${name}" "${DEVKITPRO}/${lib.toUpper name}"
  ));
  home.sessionPath = [ "${DEVKITPRO}/tools/bin" ];
}
