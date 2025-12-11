{ mkOutOfStoreSymlink, dirs, ... }:
{
  home.file = {
    ".macromedia".source = mkOutOfStoreSymlink "${dirs.hmConfig}/Adobe/.macromedia";
  };
}
