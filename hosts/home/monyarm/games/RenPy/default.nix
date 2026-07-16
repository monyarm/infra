{ mkOutOfStoreSymlink, dirs, ... }:
{
  home.file = {
    ".renpy".source = mkOutOfStoreSymlink "${dirs.hmConfig}/RenPy/.renpy";
  };
}
