{
  pkgs,
  lib,
  meta,
  options,
  ...
}:
let
  emptyProgram = pkgs.writeScriptBin "emptyProgram" "echo nothing";
  retainedNames = [ ];
  isRetained = name: lib.elem name retainedNames;

  # Helper to get filtered option names with a specific attribute
  getFilteredNames =
    optionSet: excludeList: attrName:
    lib.attrNames (
      lib.filterAttrs (_name: value: value ? ${attrName}) (lib.removeAttrs optionSet excludeList)
    );

  # Helper to generate disabled attributes for non-retained items
  disableAttrs = names: config: lib.genAttrs names (name: lib.mkIf (!(isRetained name)) config);

  # Helper to disable packages for non-retained programs/services
  disablePackages = names: disableAttrs names { package = lib.mkForce emptyProgram; };

  unfilteredProgramNames = getFilteredNames options.programs [
    "octant"
    "thefuck"
    "rtx"
    "wpaperd"
    "niri"
    "firefox" # only so I can then set package to null
    "home-manager" # package is readOnly
  ] "package";

  unfilteredServiceNames = getFilteredNames options.services [
    "keepassx"
    "password-store-sync"
  ] "package";

  unfilteredWindowManagerNames = getFilteredNames options.xsession.windowManager [ ] "enable";
in
lib.mkIf (meta.deviceType != "android-phone") {
  programs = (disablePackages unfilteredProgramNames) // {
    firefox.package = null;
  };

  services = disablePackages unfilteredServiceNames;

  xsession.windowManager = disableAttrs unfilteredWindowManagerNames { enable = lib.mkForce false; };
}
