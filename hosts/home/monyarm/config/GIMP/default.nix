{
  mkOutOfStoreSymlink,
  dirs,
  lib,
  ...
}:
let
  mkGimpConfig = version: {
    "GIMP/${version}".source = mkOutOfStoreSymlink "${dirs.hmConfig}/GIMP/.config/GIMP/${version}";
  };
in
{
  xdg.configFile = lib.mkMerge (
    lib.map mkGimpConfig [
      "2.10"
      "3.0"
    ]
  );
}
