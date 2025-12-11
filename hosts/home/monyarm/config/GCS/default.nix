{
  mkOutOfStoreSymlink,
  dirs,
  ...
}:

{
  home.file."GCS/User Library".source = mkOutOfStoreSymlink "${dirs.hmConfig}/GCS/User Library";
}
