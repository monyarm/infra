{ mkOutOfStoreSymlink, dirs, ... }:
{
  xdg.configFile = {
    "bless".source = mkOutOfStoreSymlink "${dirs.hmConfig}/Bless/.config/bless";
  };
}
