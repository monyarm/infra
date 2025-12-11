{ mkOutOfStoreSymlinkRecursive, dirs, ... }:
{
  home.file = mkOutOfStoreSymlinkRecursive "${dirs.hmConfig}/BluRay-DVD/.MakeMKV";
}
