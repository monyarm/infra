{
  pkgs,
  lib,
  meta,
  config,
  ...
}:
let
  emptyProgram = pkgs.writeScriptBin "emptyProgram" "echo nothing";

  retainedPrograms = [
    "swww"
    "octant"
    "thefuck"
    "rtx"
    "wpaperd"
    "niri"
    "firefox" # only so I can then set package to null
    "home-manager" # package is readOnly
  ];

  retainedServices = [
    "keepassx"
    "password-store-sync"
    "barrier"
  ];

  # We use the CONFIG tree instead of the OPTIONS tree.
  # This is usually much lazier.
  genDisables =
    type: retained:
    let
      # We create a mapping of every attribute currently in your config
      allAttrs = config.${type};

      # We filter the attribute names BEFORE doing anything else
      # This prevents us from ever touching the deprecated keys
      safeKeys = lib.filter (name: !(lib.elem name retained)) (lib.attrNames allAttrs);
    in
    lib.genAttrs safeKeys (
      name:
      # We only apply the override if the attribute actually looks like a
      # program/service module (has a package field defined).
      lib.optionalAttrs (lib.hasAttr "package" allAttrs.${name}) {
        package = lib.mkForce emptyProgram;
      }
    );

in
lib.mkIf (meta.deviceType != "android-phone") {

  programs = (genDisables "programs" retainedPrograms) // {
    firefox.package = null;
  };

  services = genDisables "services" retainedServices;
}
