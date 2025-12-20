{
  inputs,
  config ? null,
  pkgs,
  lib,
  ...
}:

let
  mkOutOfStoreSymlink =
    if (config != null && config ? lib.file) then config.lib.file.mkOutOfStoreSymlink else (_x: { });
  customLib = import ../../lib {
    inherit (pkgs) system lib;
    inherit pkgs mkOutOfStoreSymlink;
    config = if config != null then config else { };
  };
in
{
  _module.args = {
    inherit inputs mkOutOfStoreSymlink;
    inherit (customLib)
      format
      helpers
      constants
      meta
      fetchers
      sops
      ;
    shouldFullUpdate = customLib.meta.deviceType != "android" && (builtins.getEnv "FULLUPDATE") != "";
  }
  // customLib.format
  // customLib.helpers
  // customLib.constants
  // customLib.fetchers;
}
