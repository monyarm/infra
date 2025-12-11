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
  xdg.configFile = lib.mkMerge [
    (mkGimpConfig "2.10")
    (mkGimpConfig "3.0")
  ];
}
